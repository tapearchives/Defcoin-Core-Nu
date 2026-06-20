# Defcoin Core Nu 26.6.7y Release Notes

Internal Tahoe Apple Silicon candidate after `26.6.7x`.

## Highlights

- Makes the splash, About, left navigation masthead, and DMG artwork reuse the
  generated locked DEFCOIN / CORE NU lockup assets instead of reconstructing
  logo geometry independently.
- Updates the Nu and Explore DMG backgrounds with centered suite lockups, no
  top-left decorative coins, and a centered install row.
- Updates the runtime Dock/Command-Tab icon source to the same rounded
  Tahoe-style tile used for the Finder `.app` icon.
- Reworks Wallet > Wallets defaults: metrics stay on one line at normal window
  widths, the wallet table shows a vertical scrollbar gutter, Security is
  folded into an `Encrypt...` action, and Watch-Only Addresses moves to the
  second tab.
- Fixes Create Wallet passphrase visibility defaults, slashed/open eye icon
  mapping, BIP39 phrase display, and the recovery-checkbox text.
- Cleans Wallet tab wording: Recovery button text, close-all help, address
  zero-received filters, watch-only headings, and selected-tab styling.

## Packaging

- Visible candidate label: `26.6.7y`.
- Nu build output:
  `source/build/nu-qml-arm64-26.6.7y/DefcoinCoreNu.app`.
- Explore build output:
  `source/build/nu-qml-arm64-26.6.7y/DefcoinCoreExplore.app`.
- Staged Nu app:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.7y-20260620/apple-silicon/Defcoin Core Nu.app`.
- Staged Nu DMG:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.7y-20260620/apple-silicon/Defcoin-Core-Nu-v26.6.7y-macOS-AppleSilicon.dmg`.
- Staged Explore app:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Explore/Explore-26.6.7y-20260620/apple-silicon/Defcoin Core Nu Explore.app`.
- Staged Explore DMG:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Explore/Explore-26.6.7y-20260620/apple-silicon/Defcoin-Core-Nu-Explore-v26.6.7y-macOS-AppleSilicon.dmg`.
- Nu DMG SHA-256:
  `96d6b2fad279e144097c829d44c4da5e3aa696496731774fe245e0d5d62d9598`.
- Explore DMG SHA-256:
  `365628646eaf749f98fc5b5687a68f375934909788e0c6b7c1b8743ebcee56c4`.

## Verification

- Backend tools rebuilt: `defcoind`, `defcoin-cli`, `defcoin-tx`, and
  `defcoin-wallet` report `v26.6.7y`.
- Built `DefcoinCoreNuResources` and `DefcoinCoreExploreResources`.
- Built and staged Nu/Explore app bundles report
  `CFBundleShortVersionString=26.6.7y` and `CFBundleVersion=26.6.7y`.
- Built and staged app bundles pass
  `codesign --verify --deep --strict --verbose=2`.
- Staged Nu and Explore DMGs pass `hdiutil verify`.
- Built Nu and Explore apps pass `--smoke-test` with backend autostart
  disabled.
- Nu and Explore splash captures, Nu About capture, Wallets route capture,
  Create Wallet dialog captures, and DMG background captures were generated and
  visually checked.
- The Create Wallet UI self-test opens both default and recovery-phrase dialog
  states without QML errors, and the recovery state displays generated words.
- `git diff --check` and `bash -n stage_macos_distribution.sh` pass.
- Gatekeeper still rejects both staged apps via `spctl --assess` because this
  local build is ad-hoc signed, not Developer ID signed and notarized.

## Remaining Notes

- This remains a suffix candidate label unless explicitly promoted to the
  public three-number release line.
