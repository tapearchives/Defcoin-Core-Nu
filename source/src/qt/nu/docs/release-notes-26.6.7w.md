# Defcoin Core Nu 26.6.7w Release Notes

Internal Tahoe Apple Silicon publish candidate after `26.6.7v`.

## Highlights

- Carries forward the 26.6.7v wallet create, paper-wallet import, recovery,
  Debug Log, explorer preset, shutdown, seed attribution, Trippy, and packaging
  fixes.
- Adds the optional SQL descriptor recovery path for BIP39 phrase restore while
  keeping the legacy Nu/Core HD seed recovery path as the default.
- Tightens the DEFCOIN / CORE NU logo line spacing in both the shared QML
  lockup and the startup splash renderer.
- Bundles the new passphrase visibility icons used by Create/Restore Wallet
  passphrase fields.
- Updates the brand construction note so future splash, About, navigation, and
  package artwork use the same tighter spacing.

## Packaging

- Visible candidate label: `26.6.7w`.
- Build output:
  `build/nu-qml-arm64-26.6.7w/DefcoinCoreNu.app`.
- Staged Tahoe Apple Silicon artifact:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.7w-20260620/apple-silicon/Defcoin Core Nu.app`.
- Staged DMG:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.7w-20260620/apple-silicon/Defcoin-Core-Nu-v26.6.7w-macOS-AppleSilicon.dmg`.
- DMG SHA-256:
  `5cb93107593e84c8feee9e3645fc283a6f1220fff7beaf397573aa8d6c4a8009`.

## Verification

- Backend tools rebuilt:
  `defcoind`, `defcoin-cli`, `defcoin-tx`, and `defcoin-wallet` report
  `v26.6.7w`.
- Nu app resource target rebuilt with the bundled backend tools and runtime
  assets.
- Built and staged bundle metadata report `CFBundleShortVersionString=26.6.7w`,
  `CFBundleVersion=26.6.7w`, `CFBundleIconFile=AppIcon`, and
  `CFBundleIconName=AppIcon`.
- Built and staged app bundles pass
  `codesign --verify --deep --strict --verbose=2`.
- `hdiutil verify` reports the staged DMG checksum is valid.
- `git diff --check`, `bash -n stage_macos_distribution.sh`, and local Nu
  `clang-format --dry-run --Werror` checks pass.
- Startup splash was captured with `--grab-splash`, and About was captured with
  backend autostart disabled; both use the moderated brand lockup spacing.
- The DMG background image was extracted from the staged DMG and visually
  checked for the updated wordmark spacing.
- Gatekeeper still rejects the staged app via `spctl --assess` because this
  local build is ad-hoc signed, not Developer ID signed and notarized.

## Remaining Notes

- This is still a suffix candidate label unless explicitly promoted to the
  public three-number release line.
