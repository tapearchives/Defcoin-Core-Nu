# write_nu_build_metadata.cmake Agent Notes

## Purpose

Writes Nu build metadata used by packaged apps and release diagnostics.

## Nu Risk

- Incorrect metadata can make About/splash/backend labeling drift from the actual build.

## Do Not Break

- Keep fields synchronized with `DEFCOIN_NU_RELEASE_NAME`, backend version text, and release notes.
- Do not overwrite source-controlled release notes with generated metadata.

## Verification

- `git diff --check`
- Inspect generated metadata in a staged build and compare it with About/splash text.
