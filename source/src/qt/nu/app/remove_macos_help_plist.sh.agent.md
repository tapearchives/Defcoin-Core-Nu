# remove_macos_help_plist.sh Agent Notes

## Purpose

Removes macOS Help Book keys from an app Info.plist when help is disabled.

## Nu Risk

- Stale help keys can make macOS show broken Help menu behavior.

## Do Not Break

- Keep deletions limited to `CFBundleHelpBookFolder` and `CFBundleHelpBookName`.
- Missing keys should remain non-fatal.

## Verification

- `git diff --check`
- Package with help disabled and verify Help Book keys are absent.
