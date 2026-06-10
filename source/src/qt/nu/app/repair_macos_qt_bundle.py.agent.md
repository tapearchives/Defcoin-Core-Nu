# repair_macos_qt_bundle.py Agent Notes

## Purpose

Repairs and validates Qt framework deployment in macOS Nu bundles after macdeployqt/manual copy steps.

## Nu Risk

- Solves recurring non-fatal macdeploy warnings by copying missing frameworks, normalizing Mach-O references, pruning non-runtime files, and validating no unresolved Qt framework references remain.

## Do Not Break

- Do not paper over missing dependencies by suppressing validation.
- Keep path rewriting deterministic and app-local.
- Do not remove runtime framework files required by Qt Quick/QML.
- Python version must remain compatible with the build environment.

## Verification

- `git diff --check`
- Run the script on a staged bundle; it must exit nonzero on unresolved required Qt references and print verification success only when valid.
