# set_macos_help_plist.sh Agent Notes

## Purpose

Adds macOS Help Book keys to an app Info.plist when help is bundled.

## Nu Risk

- Must match the help folder/title used by `MacHelp.mm`.

## Do Not Break

- Keep keys limited to Help Book metadata.
- Preserve plist writability restore behavior.

## Verification

- `git diff --check`
- Package with help enabled and verify Help menu opens the bundled help.
