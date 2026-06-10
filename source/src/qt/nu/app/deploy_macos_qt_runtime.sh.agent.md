# deploy_macos_qt_runtime.sh Agent Notes

## Purpose

Deploys the Qt runtime, plugins, and QML imports into a macOS Nu app bundle.

## Nu Risk

- Controls whether the app launches on a clean machine without Homebrew Qt.
- Intentionally avoids unrelated Qt modules to keep bundle size and macdeploy warnings under control.

## Do Not Break

- Keep plugin/QML copy lists aligned with CMake Qt module usage.
- Do not mask unresolved dependencies; use repair/validation scripts to solve them explicitly.
- Preserve paths expected by `repair_macos_qt_bundle.py`.

## Verification

- `git diff --check`
- Package, run `repair_macos_qt_bundle.py`, and launch the app outside the build tree.
