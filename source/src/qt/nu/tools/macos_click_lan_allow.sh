#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/macos_click_lan_allow.swift"
CACHE_DIR="${TMPDIR:-/tmp}/defcoin-nu-tools"
BINARY="$CACHE_DIR/macos-click-lan-allow"

mkdir -p "$CACHE_DIR"

if [[ ! -x "$BINARY" || "$SOURCE" -nt "$BINARY" ]]; then
  xcrun swiftc "$SOURCE" \
    -o "$BINARY" \
    -framework ApplicationServices \
    -framework AppKit \
    -framework CoreGraphics \
    -framework Foundation \
    -framework ImageIO \
    -framework Vision
fi

exec "$BINARY" "$@"
