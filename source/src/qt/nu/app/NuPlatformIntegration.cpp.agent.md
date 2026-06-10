# NuPlatformIntegration.cpp Agent Notes

## Purpose

Implements platform integration for Nu: macOS app menu, tray/menu behavior, foreground activation, background notices, and status text bridge.

## Nu Divergence

- Adds Mac application menu actions for About, updates, Preferences, and Quit that call back into QML or `NuRpcService`.
- Adds tray support and background-running notices for platforms where tray icons are available.

## Do Not Break

- Keep root-object method names aligned with `Main.qml`.
- Do not leave tray menu or tray icon objects alive after quit.
- Keep update checks routed through `NuRpcService` so unavailable updater runtimes fail gracefully.

## Verification

- `git diff --check`
- Launch on macOS and check app menu About/Preferences/Quit actions after edits.
