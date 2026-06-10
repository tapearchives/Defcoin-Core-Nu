# NuVelopackUpdater.h Agent Notes

## Purpose

Declares the optional Velopack updater wrapper, update result state, and update detail payload.

## Nu Divergence

- Keeps the updater isolated behind a small QObject-free public API consumed by `NuRpcService`.
- Uses opaque structs for Velopack C ABI types resolved at runtime.

## Do Not Break

- Do not expose raw Velopack pointers outside this class.
- Keep `CheckState` values mapped correctly to user-facing update status.

## Verification

- `git diff --check`
- Build Nu frontend after API changes.
