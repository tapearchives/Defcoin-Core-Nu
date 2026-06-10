# NuPlatformIntegration.h Agent Notes

## Purpose

Declares the QML-visible platform integration object and native menu/tray state.

## Nu Divergence

- Exposes `trayAvailable` and invokable foreground/background actions to the QML shell.
- Holds a weak pointer to `NuRpcService` for status and update actions.

## Do Not Break

- QML invokable names are part of the UI contract. Rename only with synchronized QML changes.
- Keep pointer ownership weak (`QPointer`) because QML/service lifetimes differ during shutdown.

## Verification

- `git diff --check`
- Build Nu frontend after header changes.
