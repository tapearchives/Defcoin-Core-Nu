#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  render_paper_wallet_previews.sh <DefcoinCoreNu.app|DefcoinCoreNu executable> [output-dir] [wallet-count] [hide-art] [design]

Renders actual paper-wallet print pages for all Nu paper-wallet designs using
the app's render-only self-test print renderer. Outputs PDFs and raster PNG
pages for fast layout review without walking through the full UI.

Optional design may be 1, 2, 3, 4, or 5. Omit it to render all designs.

No real wallet data is read or written. The app must support
DEFCOIN_NU_UI_SELF_TEST and DEFCOIN_NU_PAPER_WALLET_PDF.
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

app_input="${1:-}"
if [[ -z "$app_input" ]]; then
  usage >&2
  exit 64
fi

if [[ "$app_input" == *.app ]]; then
  app_exe="$app_input/Contents/MacOS/DefcoinCoreNu"
else
  app_exe="$app_input"
fi

if [[ ! -x "$app_exe" ]]; then
  echo "error: app executable is not runnable: $app_exe" >&2
  exit 66
fi

app_bundle=""
if [[ "$app_input" == *.app ]]; then
  app_bundle="$app_input"
fi

restore_qt_bundle_parts() {
  if [[ -n "${moved_frameworks_from:-}" && -e "${moved_frameworks_from:-}" ]]; then
    mv "$moved_frameworks_from" "$moved_frameworks_to"
  fi
  if [[ -n "${moved_plugins_from:-}" && -e "${moved_plugins_from:-}" ]]; then
    mv "$moved_plugins_from" "$moved_plugins_to"
  fi
}

prepare_raw_build_qt_runtime() {
  moved_frameworks_from=""
  moved_frameworks_to=""
  moved_plugins_from=""
  moved_plugins_to=""

  if [[ -z "$app_bundle" ]]; then
    return
  fi
  if ! command -v otool >/dev/null 2>&1; then
    return
  fi
  if ! otool -L "$app_exe" 2>/dev/null | grep -q "/opt/homebrew/opt/qt"; then
    return
  fi

  local frameworks_dir="$app_bundle/Contents/Frameworks"
  local plugins_dir="$app_bundle/Contents/PlugIns"
  if [[ -d "$frameworks_dir" ]]; then
    moved_frameworks_from="${frameworks_dir}.__render_hold__"
    moved_frameworks_to="$frameworks_dir"
    rm -rf "$moved_frameworks_from"
    mv "$frameworks_dir" "$moved_frameworks_from"
  fi
  if [[ -d "$plugins_dir" ]]; then
    moved_plugins_from="${plugins_dir}.__render_hold__"
    moved_plugins_to="$plugins_dir"
    rm -rf "$moved_plugins_from"
    mv "$plugins_dir" "$moved_plugins_from"
  fi

  export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-offscreen}"
  export QT_PLUGIN_PATH="${QT_PLUGIN_PATH:-/opt/homebrew/share/qt/plugins}"
  export QT_QPA_PLATFORM_PLUGIN_PATH="${QT_QPA_PLATFORM_PLUGIN_PATH:-/opt/homebrew/share/qt/plugins/platforms}"
  export QML2_IMPORT_PATH="${QML2_IMPORT_PATH:-/opt/homebrew/share/qt/qml}"
}

out_dir="${2:-/tmp/defcoin-paper-wallet-previews}"
wallet_count="${3:-6}"
hide_art="${4:-0}"
requested_design="${5:-all}"
if ! [[ "$wallet_count" =~ ^[0-9]+$ ]] || (( wallet_count < 1 )); then
  echo "error: wallet-count must be a positive integer" >&2
  exit 64
fi
case "$hide_art" in
  0|false|False|FALSE|no|No|NO) hide_art=0 ;;
  1|true|True|TRUE|yes|Yes|YES|hide-art|--hide-art) hide_art=1 ;;
  *)
    echo "error: hide-art must be 0/1, true/false, yes/no, or hide-art" >&2
    exit 64
    ;;
esac

magick_bin="${MAGICK:-/opt/homebrew/bin/magick}"
if [[ ! -x "$magick_bin" ]]; then
  magick_bin="$(command -v magick || true)"
fi
if [[ -z "$magick_bin" || ! -x "$magick_bin" ]]; then
  echo "error: ImageMagick 'magick' is required to rasterize preview pages" >&2
  exit 69
fi

mkdir -p "$out_dir"
prepare_raw_build_qt_runtime
trap restore_qt_bundle_parts EXIT

forms=(0 1 2 3 4)
names=(
  "design-1-full-sheet-strips"
  "design-2-full-width-trifold"
  "design-3-avery-5011"
  "design-4-public-private-cards"
  "design-5-defcoin-bulk"
)

if [[ "$requested_design" != "all" ]]; then
  if ! [[ "$requested_design" =~ ^[1-5]$ ]]; then
    echo "error: design must be 1, 2, 3, 4, 5, or omitted" >&2
    exit 64
  fi
  design_index=$((requested_design - 1))
  forms=("${forms[$design_index]}")
  names=("${names[$design_index]}")
fi

for i in "${!forms[@]}"; do
  form="${forms[$i]}"
  name="${names[$i]}"
  design_dir="$out_dir/$name"
  mkdir -p "$design_dir"
  pdf="$design_dir/$name.pdf"
  log="$design_dir/$name.log"

  count="$wallet_count"
  if [[ "$form" == "4" && "$count" -lt 2 ]]; then
    count=2
  fi

  echo "rendering $name -> $pdf"
  DEFCOIN_NU_UI_SELF_TEST=1 \
  DEFCOIN_NU_NO_BACKEND_AUTOSTART=1 \
  DEFCOIN_NU_PAPER_WALLET_RENDER_ONLY=1 \
  DEFCOIN_NU_PAPER_WALLET_FORM="$form" \
  DEFCOIN_NU_PAPER_WALLET_HIDE_ART="$hide_art" \
  DEFCOIN_NU_PAPER_WALLET_SELF_TEST_COUNT="$count" \
  DEFCOIN_NU_PAPER_WALLET_PDF="$pdf" \
  "$app_exe" --ui-self-test --allow-multiple --debug-use-env >"$log" 2>&1

  rm -f "$design_dir"/page-*.png
  "$magick_bin" -density 140 "$pdf" -quality 90 "$design_dir/page-%02d.png"
done

echo "paper-wallet previews written to: $out_dir"
