# testconsensus.vcxproj Agent Notes

## Purpose

Builds the Windows consensus test executable.

## Nu Risk

- Confirms consensus library behavior across toolchains.

## Do Not Break

- Keep this target tied to the same consensus library used by daemon/wallet builds.
- Run it after consensus, script, crypto, or validation-adjacent source membership changes.

## Verification

- `git diff --check`
- Windows `testconsensus` build/run when available.
