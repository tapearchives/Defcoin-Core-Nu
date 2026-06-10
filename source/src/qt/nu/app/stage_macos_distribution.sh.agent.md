# stage_macos_distribution.sh Agent Notes

## Purpose

Stages macOS Nu distribution bundles, deploys backend/Qt runtime dependencies, signs the app, and generates DMG background assets/layout.

## Nu Risk

- Owns the final user-facing macOS app package and DMG presentation.
- DMG layout has repeatedly regressed around icon text backing, coin artwork placement, arrow alignment, and title/logo text.

## Do Not Break

- Do not copy wallet/datadir content into distributions.
- Keep staged app version, bundle metadata, icon, backend binary, Qt runtime, and signing steps synchronized.
- DMG background artwork should be visually verified; generated gradients must fully fade out before image edges.
- Do not treat successful packaging as proof of runtime launch; smoke-test launch separately.

## Verification

- `git diff --check`
- Run staging, verify codesign, open the DMG, inspect layout, and launch the staged app.
