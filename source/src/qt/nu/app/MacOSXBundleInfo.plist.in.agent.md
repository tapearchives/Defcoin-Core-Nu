# MacOSXBundleInfo.plist.in Agent Notes

## Purpose

Template for macOS bundle metadata: bundle id, display name, icon, version, document/help settings, and launch persistence behavior.

## Nu Risk

- Affects macOS app identity, Local Network privacy behavior, Finder kind, window restoration prompts, icon display, and version/about metadata.

## Do Not Break

- Keep bundle identifiers stable unless intentionally creating a new product identity.
- Keep window-restoration suppression keys so macOS does not prompt to reopen old Nu windows after a crash.
- Keep app category/platform metadata appropriate for a macOS desktop app, not iOS.
- Keep help-book keys synchronized with `set_macos_help_plist.sh` and `remove_macos_help_plist.sh`.

## Verification

- `git diff --check`
- Build a bundle and inspect `mdls`, Finder Kind, icon, version, and relaunch-after-crash behavior.
