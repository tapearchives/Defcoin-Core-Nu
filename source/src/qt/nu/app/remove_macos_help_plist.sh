#!/bin/sh
export LC_ALL=C
set -eu

plist="$1"

/usr/libexec/PlistBuddy -c 'Delete :CFBundleHelpBookFolder' "$plist" >/dev/null 2>&1 || true
/usr/libexec/PlistBuddy -c 'Delete :CFBundleHelpBookName' "$plist" >/dev/null 2>&1 || true
