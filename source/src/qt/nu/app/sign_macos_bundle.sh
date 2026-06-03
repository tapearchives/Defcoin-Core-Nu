#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <app-bundle>" >&2
  exit 2
fi

APP="$1"
CONTENTS="$APP/Contents"
PLIST="$CONTENTS/Info.plist"

if [ ! -d "$APP" ] || [ ! -d "$CONTENTS" ]; then
  echo "app bundle not found: $APP" >&2
  exit 1
fi

APP_EXECUTABLE_NAME=""
if [ -f "$PLIST" ]; then
  APP_EXECUTABLE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$PLIST" 2>/dev/null || true)"
fi
if [ -z "$APP_EXECUTABLE_NAME" ]; then
  APP_EXECUTABLE_NAME="$(basename "$APP" .app)"
fi
APP_EXE="$CONTENTS/MacOS/$APP_EXECUTABLE_NAME"

PYTHON_FOR_SIGNING="${DEFCOIN_NU_PACKAGING_PYTHON:-$(command -v python3)}"

xattr -cr "$APP" >/dev/null 2>&1 || true

sign_macho_tree() {
  local root="$1"
  local exclude_dir="${2:-}"
  while IFS= read -r -d '' candidate; do
    chmod u+w "$candidate" 2>/dev/null || true
    codesign --force --sign - --timestamp=none "$candidate" >/dev/null
  done < <("$PYTHON_FOR_SIGNING" - "$root" "$exclude_dir" <<'PY'
import os
import sys

root = os.path.abspath(sys.argv[1])
exclude_dir = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2] else ""
magics = {
    b"\xfe\xed\xfa\xce",
    b"\xce\xfa\xed\xfe",
    b"\xfe\xed\xfa\xcf",
    b"\xcf\xfa\xed\xfe",
    b"\xca\xfe\xba\xbe",
    b"\xbe\xba\xfe\xca",
    b"\xca\xfe\xba\xbf",
    b"\xbf\xba\xfe\xca",
}
paths = []
for base, _dirs, files in os.walk(root, followlinks=False):
    for name in files:
        path = os.path.abspath(os.path.join(base, name))
        if exclude_dir and os.path.commonpath([path, exclude_dir]) == exclude_dir:
            continue
        try:
            with open(path, "rb") as handle:
                head = handle.read(4)
        except OSError:
            continue
        if head in magics:
            paths.append(path)
for path in sorted(paths):
    sys.stdout.buffer.write(path.encode() + b"\0")
PY
)
}

sign_macho_tree "$CONTENTS" "$CONTENTS/MacOS"
if [ -x "$APP_EXE" ]; then
  chmod u+w "$APP_EXE" 2>/dev/null || true
  codesign --force --sign - --timestamp=none "$APP_EXE" >/dev/null
fi
codesign --force --sign - --timestamp=none "$APP" >/dev/null
codesign --verify --deep --strict --verbose=4 "$APP"
