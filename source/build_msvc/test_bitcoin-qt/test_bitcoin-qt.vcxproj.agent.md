# test_bitcoin-qt.vcxproj Agent Notes

## Purpose

Builds the Windows classic Qt test executable.

## Nu Risk

- Exercises classic Qt widget code, not the Nu QML frontend, but it shares Qt path and generated-file assumptions.

## Do Not Break

- Keep Qt references and generated MOC paths consistent with `libbitcoin_qt`.
- Do not use this target as proof that Nu QML views were tested.

## Verification

- `git diff --check`
- Windows Qt test build when available.
