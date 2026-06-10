# common.vcxproj Agent Notes

## Purpose

Copies built artifacts from the MSVC output folder back into `src` for downstream packaging and tooling.

## Nu Risk

- The copy target changes where release scripts and manual packaging expect `.exe` and `.pdb` outputs.

## Do Not Break

- Do not redirect artifacts to a new folder without updating Windows packaging notes and scripts.
- Keep `SkipUnchangedFiles` behavior unless a reproducibility issue requires otherwise.

## Verification

- `git diff --check`
- Confirm a Windows build produces artifacts where the installer/portable packaging expects them.
