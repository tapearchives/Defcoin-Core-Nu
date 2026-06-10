# hexdump.targets Agent Notes

## Purpose

Defines custom MSBuild helper behavior for hexdump-style generated artifacts.

## Nu Risk

- Small XML or command-line changes can silently alter generated resource/header data used by Windows builds.

## Do Not Break

- Preserve command quoting and path handling for Windows shells.
- If changing generated output shape, inspect every project that imports this target.

## Verification

- `git diff --check`
- Windows build target that exercises the hexdump task.
