# Nu Qt/QML DOX

## Purpose

This folder owns the Tahoe Nu frontend, QML views/components, bridge services, Nu assets, local UI docs, and small test/support tools.

## Ownership

- `app/` contains C++ bridge and app service code.
- `qml/` contains the QML shell, views, components, and theme.
- `assets/`, `resources/`, and `help/` contain bundled UI/support assets.
- `docs/` contains current Nu build, protocol, UX, and cross-build notes.
- `tools/` contains launch gates and test/debug helpers.

## Local Contracts

- UI text must be concise and user-facing; dense diagnostics belong behind Details or Advanced tools.
- Metrics is read-only; controls belong in Settings or a dedicated tool view.
- Keep chart labels unique and ensure transport counters are not double-counted.
- Selectable/copyable diagnostic text should support normal clipboard use where practical.
- Do not add Qt modules that break Lion parity without documenting the fallback.

## Work Guidance

- QML is the presentation layer. Use existing custom QML/Canvas components where Lion parity matters; use newer Qt modules only when the platform matrix supports them.
- For frontend changes, check both layout density and text clipping at realistic window sizes.
- For service changes, keep C++ bridge APIs narrow and explicit.

## Verification

- Run `git diff --check` from the Tahoe source repository root.
- Build the Nu app when QML/C++ bridge changes affect runtime.
- Launch the app and inspect the touched view when possible.

## Child DOX Index

- `qml/` - QML shell, views, components, and theme.
- `app/` - C++ app services and bridge code.
- `docs/` - Nu-specific operational and protocol documentation.
- `tools/` - launch/test helpers.
- `assets/`, `resources/`, `help/` - bundled UI content.
