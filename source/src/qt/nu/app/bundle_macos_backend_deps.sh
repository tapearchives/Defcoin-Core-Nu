#!/usr/bin/env bash
export LC_ALL=C
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <Defcoin Core Nu.app>" >&2
  exit 2
fi

APP="$1"
FRAMEWORKS_DIR="$APP/Contents/Frameworks"
BACKEND_BIN_DIR="$APP/Contents/Resources/nu/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
DEFAULT_BACKEND_BIN_DIR="$REPO_ROOT/src"

if [ ! -d "$APP/Contents" ]; then
  echo "app bundle not found: $APP" >&2
  exit 1
fi

if [ ! -d "$BACKEND_BIN_DIR" ]; then
  SOURCE_BIN_DIR="${DEFCOIN_NU_BACKEND_BIN_DIR:-$DEFAULT_BACKEND_BIN_DIR}"
  if [ -x "$SOURCE_BIN_DIR/defcoind" ] && [ -x "$SOURCE_BIN_DIR/defcoin-cli" ]; then
    mkdir -p "$BACKEND_BIN_DIR"
    for tool in defcoind defcoin-cli defcoin-tx defcoin-wallet; do
      if [ -x "$SOURCE_BIN_DIR/$tool" ]; then
        cp -p "$SOURCE_BIN_DIR/$tool" "$BACKEND_BIN_DIR/$tool"
        chmod u+w "$BACKEND_BIN_DIR/$tool"
      fi
    done
  else
    exit 0
  fi
fi

mkdir -p "$FRAMEWORKS_DIR"

is_bundle_dependency() {
  local dep="$1"
  case "$dep" in
    *.framework/*) return 1 ;;
    /opt/homebrew/*|/opt/local/*|/usr/local/*) return 0 ;;
    *) return 1 ;;
  esac
}

is_macho_file() {
  local path="$1"
  [ -f "$path" ] && file "$path" | grep -q 'Mach-O'
}

declare -a queue=()
queued_list=""
copied_dependency=""

enqueue_once() {
  local path="$1"
  if ! printf '%s\n' "$queued_list" | grep -Fqx "$path"; then
    queued_list="${queued_list}
$path"
    queue+=("$path")
  fi
}

copy_dependency() {
  local dep="$1"
  local base
  base="$(basename "$dep")"
  local dest="$FRAMEWORKS_DIR/$base"

  if [ ! -e "$dest" ]; then
    cp -p "$dep" "$dest"
    chmod u+w "$dest"
  fi

  enqueue_once "$dest"
  copied_dependency="$dest"
}

rewrite_image_dependencies() {
  local image="$1"
  local mode="$2"
  local dep dest base new_path

  chmod u+w "$image" 2>/dev/null || true

  if [ "$mode" = "framework" ]; then
    base="$(basename "$image")"
    install_name_tool -id "@rpath/$base" "$image" 2>/dev/null || true
    install_name_tool -add_rpath "@loader_path" "$image" 2>/dev/null || true
  else
    install_name_tool -add_rpath "@loader_path/../../../Frameworks" "$image" 2>/dev/null || true
  fi

  while IFS= read -r dep; do
    [ -n "$dep" ] || continue
    if ! is_bundle_dependency "$dep"; then
      continue
    fi
    copy_dependency "$dep"
    dest="$copied_dependency"
    base="$(basename "$dest")"
    if [ "$mode" = "framework" ]; then
      new_path="@loader_path/$base"
    else
      new_path="@rpath/$base"
    fi
    install_name_tool -change "$dep" "$new_path" "$image" 2>/dev/null || true
  done < <(otool -L "$image" | awk 'NR > 1 {print $1}')
}

for backend in "$BACKEND_BIN_DIR"/*; do
  if is_macho_file "$backend"; then
    rewrite_image_dependencies "$backend" "backend"
  fi
done

index=0
while [ "$index" -lt "${#queue[@]}" ]; do
  image="${queue[$index]}"
  index=$((index + 1))
  if is_macho_file "$image"; then
    rewrite_image_dependencies "$image" "framework"
  fi
done
