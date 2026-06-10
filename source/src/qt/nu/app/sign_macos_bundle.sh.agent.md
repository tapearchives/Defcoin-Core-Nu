# sign_macos_bundle.sh Agent Notes

## Purpose

Ad-hoc signs macOS Nu bundle contents and verifies the final bundle signature.

## Nu Risk

- Unsigned or partially signed nested binaries can trigger launch failures, firewall/privacy weirdness, or distribution friction.

## Do Not Break

- Sign nested frameworks, plugins, helpers, app executable, then the outer bundle.
- Do not sign wallet/datadir content.
- Keep verification strict enough to catch broken nested signatures.

## Verification

- `git diff --check`
- Run on a staged bundle and require `codesign --verify --deep --strict --verbose=4` success.
