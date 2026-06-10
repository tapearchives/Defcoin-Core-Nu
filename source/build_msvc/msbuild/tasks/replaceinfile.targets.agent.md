# replaceinfile.targets Agent Notes

## Purpose

Defines custom MSBuild helper behavior for text replacement in generated Windows build artifacts.

## Nu Risk

- Used during project generation/build steps where quoting and path normalization are fragile.

## Do Not Break

- Preserve XML escaping, command quoting, and input/output dependency behavior.
- Do not broaden replacement scope without reviewing generated files.

## Verification

- `git diff --check`
- Windows build target that exercises the replace-in-file task.
