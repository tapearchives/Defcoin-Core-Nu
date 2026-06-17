# Defcoin Core Nu 26.6.7s Release Notes

Internal Tahoe candidate focused on Paper Wallet generation flow and preview
accuracy.

## Paper Wallet

- Shows only Design 1 in the user-facing design selector while keeping Designs
  2-5 compiled for later polish.
- Removes duplicate entropy percentage copy in the Create Entropy step.
- Adds clearer Generate button status text when generation is blocked by
  backend, entropy, or BIP38 passphrase requirements.
- Marks weak BIP38 passphrases in red until the phrase is long enough or the
  user explicitly enables weak phrases.
- Allows regenerated paper-wallet sheets after customization changes without
  forcing a fresh entropy ceremony when generated keys already exist.
- Preserves already generated public addresses during regeneration; additional
  wallets append new keys, and BIP38 changes re-encode existing private keys.
- Tightens Design 1 QR rendering by drawing QR modules directly into the
  reserved square instead of scaling a padded QR image.
- Adds subtle key/address grouping guides for paper-wallet transcription.
- Splits Design 1 private-key output across two grouped mono lines and narrows
  the secret checker/QR area so the WIF/BIP38 text is not clipped.

## Verification

- Built Tahoe Apple Silicon `DefcoinCoreNu` target from
  `build/nu-qml-arm64-26.6.7s`.
- Rendered Design 1 with `render_paper_wallet_previews.sh` and inspected the
  resulting page image.
