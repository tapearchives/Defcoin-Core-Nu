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
- Follow `docs/writing-style.md` for new prose and changelog entries. Preserve existing release history and dated notes; append corrections or new entries without rewriting prior entries.
- Metrics is read-only; controls belong in Settings or a dedicated tool view.
- Keep chart labels unique and ensure transport counters are not double-counted.
- Selectable/copyable diagnostic text should support normal clipboard use where practical.
- Do not add Qt modules that break Lion parity without documenting the fallback.
- Nu-owned C, C++, Objective-C, and Objective-C++ files in this subtree use the local `.clang-format`; backend/Core files outside this subtree keep the Litecoin/Core `source/src/.clang-format` style.

## Work Guidance

- QML is the presentation layer. Use existing custom QML/Canvas components where Lion parity matters; use newer Qt modules only when the platform matrix supports them.
- Use `.clang-format` for Nu app C/C++/Obj-C++ touched hunks or new Nu-owned files. On Tahoe, `/usr/bin/xcrun clang-format` is the expected Xcode formatter path. Do not use it as a global QML formatter.
- For frontend changes, check both layout density and text clipping at realistic window sizes.
- For service changes, keep C++ bridge APIs narrow and explicit.
- For Tahoe CMake app builds, build the default target or `DefcoinCoreNuResources` before launch verification. Building only `DefcoinCoreNu` creates the executable but can leave QML/assets/tools unstaged, producing a backend-only launch.
- For new Tahoe app launches, run `tools/macos_click_lan_allow.sh` against the fresh app PID within a few seconds of `open`; do not rediscover the Local Network permission click workflow each time.
- If a QML, C++, or build file has a sibling `[full filename].agent.md`, read that companion before editing the file and keep it current with durable behavior changes.

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
