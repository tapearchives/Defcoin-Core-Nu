#!/bin/sh
export LC_ALL=C
set -eu

plist="$1"

/usr/libexec/PlistBuddy -c "Set :NSQuitAlwaysKeepsWindows false" "$plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :NSQuitAlwaysKeepsWindows bool false" "$plist"

/usr/libexec/PlistBuddy -c "Set :NSWindowRestoresWorkspaceAtLaunch false" "$plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :NSWindowRestoresWorkspaceAtLaunch bool false" "$plist"

/usr/libexec/PlistBuddy -c "Set :ApplePersistenceIgnoreState true" "$plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :ApplePersistenceIgnoreState bool true" "$plist"
