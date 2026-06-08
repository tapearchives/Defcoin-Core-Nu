#!/bin/sh
export LC_ALL=C
set -eu

plist="$1"

chmod u+w "$plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleHelpBookFolder DefcoinCoreNu.help" "$plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleHelpBookFolder string DefcoinCoreNu.help" "$plist"

/usr/libexec/PlistBuddy -c "Set :CFBundleHelpBookName Defcoin Core Nu Help" "$plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleHelpBookName string Defcoin Core Nu Help" "$plist"

chmod a-w "$plist"
