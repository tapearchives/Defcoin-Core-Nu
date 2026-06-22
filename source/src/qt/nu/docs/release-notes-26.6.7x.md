# Defcoin Core Nu 26.6.7x Release Notes

Internal Tahoe Apple Silicon candidate after `26.6.7w`.

## Highlights

- Locks the DEFCOIN / CORE NU logo ratios into the shared QML lockup, splash
  painter, About artwork, navigation masthead, and DMG renderer.
- Rebuilds the macOS Finder app icon through the Icon Composer source with a
  clean foreground coin, no bottom haze, and Chrome-like foreground/tile scale.
- Renames Wallet > Files to Wallets.
- Adds introductory Wallet > Messages signing guidance for new users.

## Packaging

- Visible candidate label: `26.6.7x`.
- Nu build output:
  `source/build/nu-qml-arm64-26.6.7x/DefcoinCoreNu.app`.
- Staged Nu app:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.7x-20260620/apple-silicon/Defcoin Core Nu.app`.
- Staged Nu DMG:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.7x-20260620/apple-silicon/Defcoin-Core-Nu-v26.6.7x-macOS-AppleSilicon.dmg`.
- Nu DMG SHA-256:
  `1a37ae54a0f5c9057a4effcb2bc776ca55ee1eb6185c9a28336491b1c049f645`.

## Verification

- Backend tools rebuilt: `defcoind`, `defcoin-cli`, `defcoin-tx`, and
  `defcoin-wallet` report `v26.6.7x`.
- Built `DefcoinCoreNuResources`.
- Built and staged Nu app bundle reports `CFBundleShortVersionString=26.6.7x`
  and `CFBundleVersion=26.6.7x`.
- Built and staged app bundle passes
  `codesign --verify --deep --strict --verbose=2`.
- Staged Nu DMG passes `hdiutil verify`.
- Built and staged Nu app passes `--smoke-test` with backend autostart
  disabled.
- Nu splash/About captures were generated and visually checked.
- Finder-style `NSWorkspace` icon render measured Nu and Chrome colored
  foreground/tile ratios within 0.3 percentage points. The Nu Icon Composer
  foreground alpha bbox is `832x832` on a `1024x1024` canvas.
- `git diff --check`, `bash -n stage_macos_distribution.sh`, and
  `python3 -m json.tool AppIcon.icon/icon.json` pass.
- Gatekeeper still rejects the staged app via `spctl --assess` because this
  local build is ad-hoc signed, not Developer ID signed and notarized.

## Remaining Notes

- This remains a suffix candidate label unless explicitly promoted to the
  public three-number release line.
