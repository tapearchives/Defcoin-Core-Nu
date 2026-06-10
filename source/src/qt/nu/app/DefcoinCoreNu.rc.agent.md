# DefcoinCoreNu.rc Agent Notes

## Purpose

Windows resource file for the Nu executable icon/version resources.

## Nu Risk

- Controls visible Windows icon/resource metadata for the Nu app.
- Must remain aligned with CMake release metadata and packaged artifacts.

## Do Not Break

- Do not change icon/resource paths without verifying the Windows build includes the expected icon.
- Keep version strings synchronized with the release label rule when this file contains or gains version metadata.

## Verification

- `git diff --check`
- Windows build; inspect executable icon and file properties.
