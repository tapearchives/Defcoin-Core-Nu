# Defcoin Core Nu 26.6.7x Release Notes

Internal Tahoe Apple Silicon candidate after `26.6.7w`.

## Highlights

- Locks the DEFCOIN / CORE NU logo ratios into the shared QML lockup, splash
  painter, About artwork, navigation masthead, and DMG renderer.
- Updates Explore to use the complete Nu logo plus a separated `EXPLORE` third
  line in the splash, About dialog, and left navigation masthead.
- Rebuilds the macOS Finder app icon through the Icon Composer source with a
  clean foreground coin, no bottom haze, and Chrome-like foreground/tile scale.
- Renames Wallet > Files to Wallets.
- Adds introductory Wallet > Messages signing guidance for new users.
- Builds the Explore app resources explicitly so the staged Explore bundle has
  its real executable and launches instead of closing immediately.

## Packaging

- Visible candidate label: `26.6.7x`.
- Nu build output:
  `source/build/nu-qml-arm64-26.6.7x/DefcoinCoreNu.app`.
- Explore build output:
  `source/build/nu-qml-arm64-26.6.7x/DefcoinCoreExplore.app`.
- Staged Nu app:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.7x-20260620/apple-silicon/Defcoin Core Nu.app`.
- Staged Nu DMG:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.7x-20260620/apple-silicon/Defcoin-Core-Nu-v26.6.7x-macOS-AppleSilicon.dmg`.
- Staged Explore app:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Explore/Explore-26.6.7x-20260620/apple-silicon/Defcoin Core Nu Explore.app`.
- Staged Explore DMG:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Explore/Explore-26.6.7x-20260620/apple-silicon/Defcoin-Core-Nu-Explore-v26.6.7x-macOS-AppleSilicon.dmg`.
- Nu DMG SHA-256:
  `1a37ae54a0f5c9057a4effcb2bc776ca55ee1eb6185c9a28336491b1c049f645`.
- Explore DMG SHA-256:
  `b3a858293e849f9e6b9a7e26cae7c850fb660f36e6161d22b41cb76a5dbbc6d5`.

## Verification

- Backend tools rebuilt: `defcoind`, `defcoin-cli`, `defcoin-tx`, and
  `defcoin-wallet` report `v26.6.7x`.
- Built `DefcoinCoreNuResources` and `DefcoinCoreExploreResources`.
- Built and staged Nu/Explore app bundles report
  `CFBundleShortVersionString=26.6.7x` and `CFBundleVersion=26.6.7x`.
- Built and staged app bundles pass
  `codesign --verify --deep --strict --verbose=2`.
- Staged Nu and Explore DMGs pass `hdiutil verify`.
- Built and staged Nu and Explore apps pass `--smoke-test` with backend
  autostart disabled.
- Nu and Explore splash/About captures were generated and visually checked.
- Finder-style `NSWorkspace` icon render measured Nu and Chrome colored
  foreground/tile ratios within 0.3 percentage points. The Nu Icon Composer
  foreground alpha bbox is `832x832` on a `1024x1024` canvas.
- `git diff --check`, `bash -n stage_macos_distribution.sh`, and
  `python3 -m json.tool AppIcon.icon/icon.json` pass.
- Gatekeeper still rejects both staged apps via `spctl --assess` because this
  local build is ad-hoc signed, not Developer ID signed and notarized.

## Remaining Notes

- This remains a suffix candidate label unless explicitly promoted to the
  public three-number release line.
