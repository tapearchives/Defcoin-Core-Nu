# common.init.vcxproj Agent Notes

## Purpose

Defines shared MSVC toolset, output/intermediate folders, warning policy, and common linker libraries for Windows projects.

## Nu Risk

- Uses Visual Studio toolset `v142`.
- Shared `OutDir` and `IntDir` affect every project in the solution.
- Common Windows system libraries are inherited by backend, wallet, and Qt targets.

## Do Not Break

- Do not change the platform toolset, output layout, or inherited linker dependencies without verifying all Windows targets.
- Keep Release and Debug property groups aligned unless a difference is intentional and documented.

## Verification

- `git diff --check`
- Run or request a Windows build after functional XML changes.
