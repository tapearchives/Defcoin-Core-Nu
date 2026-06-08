#!/bin/sh
export LC_ALL=C
set -eu

qt_root="$1"
app_binary="$2"

install_name_tool -delete_rpath "$qt_root/lib" "$app_binary" 2>/dev/null || true
install_name_tool -add_rpath "@executable_path/../Frameworks" "$app_binary" 2>/dev/null || true
