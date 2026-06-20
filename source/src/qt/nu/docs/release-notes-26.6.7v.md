# Defcoin Core Nu 26.6.7v Release Notes

Internal Tahoe Apple Silicon publish candidate after `26.6.7u`.

## Highlights

- Carries forward the 26.6.7u publish-candidate fixes for Finder app icons,
  Debug Log under RPC Console, explorer presets, August 2026 Defcoin-only magic,
  send keypool recovery, shutdown progress, seed attribution, and Paper Wallet
  selector behavior.
- Adds post-review packaging hardening: direct macOS app target builds now
  install both `AppIcon.icns` and `Assets.car`, so Finder icons remain present
  even when the app target is built without the resource target first.
- Regenerates `AppIcon.icns` from the corrected 1024 PNG through a full iconset,
  so the ICNS fallback now includes every standard macOS size through
  `512x512@2x` instead of relying on `Assets.car` alone for large Finder icons.
- Makes Trippy launch compatibility-aware. Nu now probes `trip --help` before
  using newer single-page TUI flags and falls back to legacy stream mode for
  older Trippy binaries.
- Polishes the About logo lockup and Settings panes after screenshot review.

## User-Facing Fixes

- About now uses the same canonical coin-to-wordmark ratio as the shared logo
  component.
- The recovery-wallet creation dialog now says "Encrypt new wallet" instead of
  "Encrypt recovered wallet".
- Settings > Display and Settings > Updates use explicit scroll containers so
  expanded explorer URL/status controls stay reachable on smaller windows.
- The focused UI self-test can capture Settings > Display or Updates with
  `DEFCOIN_NU_UI_SELF_TEST_SETTINGS_TAB`.

## Packaging

- Visible label is `26.6.7v` in app metadata and bundled Core tools.
- Staged Apple Silicon output:
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.7v-20260619/apple-silicon/`.
- DMG:
  `Defcoin-Core-Nu-v26.6.7v-macOS-AppleSilicon.dmg`.
- SHA-256:
  `82a4a16db0908adc0ce850b2a7e09ce25301978193a1b98f2af1f3bbd8940db4`.

## Verification

- `git diff --check` passed.
- `/usr/bin/xcrun clang-format --dry-run --Werror
  src/qt/nu/app/NuRpcService.cpp src/qt/nu/app/main.cpp` passed.
- Backend tools rebuilt and report `v26.6.7v`.
- `cmake --build build/nu-qml-arm64-26.6.7v --target DefcoinCoreNuResources
  -j 1` passed and verified the built app signature.
- Built-app UI self-tests passed, including the full route/dialog walk and
  focused Settings > Display / Updates screenshots.
- The built and staged `AppIcon.icns` files extract to a complete macOS iconset
  through `icon_512x512@2x.png`, and the staged app rendered through
  `NSWorkspace.icon(forFile:)` measures `890x888+67+76`.
- Roborev `v0.58.0` maximum-reasoning dirty review passed with no issues after
  the full-ICNS fallback change.
- `stage_macos_distribution.sh ... 26.6.7v macOS-AppleSilicon` staged, signed,
  and created the DMG; `hdiutil verify` passed.
- `codesign --verify --deep --strict --verbose=2` passed for the staged app.
- Staged-app UI self-test passed.
- Staged app contains no `.agent.md` files.

## Remaining Notes

- The automatic keypool recovery path was built and reviewed but not exercised
  against a live empty-keypool wallet in this pass.
- Export-control language should be reviewed before public distribution.
