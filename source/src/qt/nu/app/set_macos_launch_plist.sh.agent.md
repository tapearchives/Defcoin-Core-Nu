# set_macos_launch_plist.sh Agent Notes

## Purpose

Sets macOS Info.plist keys that suppress confusing window-restoration prompts and stale layout reopening.

## Nu Risk

- Directly addresses the repeated "reopen windows" crash/relaunch prompt regression.

## Do Not Break

- Keep `NSQuitAlwaysKeepsWindows`, `NSWindowRestoresWorkspaceAtLaunch`, and `ApplePersistenceIgnoreState` set to disable restoration.
- Missing keys should be added; existing keys should be updated.

## Verification

- `git diff --check`
- Crash/relaunch or force-quit smoke test should open Nu in its default view without macOS asking to reopen old windows.
