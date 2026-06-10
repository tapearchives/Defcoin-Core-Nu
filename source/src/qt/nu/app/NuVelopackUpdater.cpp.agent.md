# NuVelopackUpdater.cpp Agent Notes

## Purpose

Loads the optional Velopack runtime dynamically and implements update check, download, pending restart, and apply flows.

## Nu Divergence

- Searches platform-specific runtime library names and bundle locations for macOS, Windows, and Linux.
- Uses dynamic symbol resolution so Nu can launch even when the updater runtime is absent.

## Do Not Break

- Missing Velopack runtime must be a user-visible "updates unavailable" state, not a launch failure.
- Keep symbol names aligned with the Velopack C ABI.
- Do not allow version downgrades unless the release process explicitly requires it.
- Keep downloaded update metadata separate from wallet/backend data.

## Verification

- `git diff --check`
- Launch without the Velopack runtime and confirm Nu still opens.
- If runtime is present, smoke-test manual update check.
