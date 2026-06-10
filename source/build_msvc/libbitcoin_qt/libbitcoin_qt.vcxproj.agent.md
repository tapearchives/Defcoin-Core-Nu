# libbitcoin_qt.vcxproj Agent Notes

## Purpose

Builds the classic Qt wallet static library and runs Qt MOC/UIC/RCC generation for the MSVC project graph.

## Nu Risk

- This target has fragile generated-file paths and many explicit MOC source entries.
- It is classic Qt widget code, not the Nu QML frontend, but Windows builds may still depend on it.

## Do Not Break

- Keep `GeneratedFilesOutDir`, MOC/UIC/RCC target outputs, and Qt include directories stable.
- Add or remove Qt headers/forms/resources in all matching item groups and generation targets.
- Do not add QML-only assumptions here without a planned Windows Nu QML packaging path.

## Verification

- `git diff --check`
- Windows Qt build; inspect MOC/UIC/RCC generation output on failure.
