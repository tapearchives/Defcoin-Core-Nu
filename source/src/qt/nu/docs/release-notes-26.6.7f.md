# Defcoin Core Nu 26.6.7f Release Notes

Internal Tahoe candidate focused on the v26 brand lockup and Paper Wallet flow.

## Changed

- Rebuilt the reusable Nu combination mark to use the v26 coin plus the documented
  DEFCOIN / CORE NU wordmark ratios and character-level spacing.
- Updated the splash renderer to draw the wordmark with the same character-level
  construction instead of ordinary text runs.
- Expanded Wallet > Paper Wallet into a liteaddress-style sheet workflow:
  Hide Art, addresses to generate, BIP38 encryption/passphrase, addresses per
  page, Generate, and Print.
- Paper Wallet now defaults to three generated addresses and prints fixed-size
  QPainter-rendered foldable strips rather than a multi-page oversized coin
  preview.
- Added `Design 5 - Defcoin Bulk two-page`, a landscape two-page paper-wallet
  design based on the original `sibios/defcoin-bulk` front/back artwork and
  coordinate layout.
- Tightened Design 1 and Design 5 print overlays so QR/text areas stay centered,
  text gets readable backing, and inverted Design 5 text cannot run outside its
  source-art slot.
- Optional BIP38 encryption uses OpenSSL scrypt/AES and fails closed if
  encryption cannot complete.
- Paper Wallet entropy capture now requires a larger mouse/keyboard collection
  target with a visible progress meter, while key generation mixes that local
  input with OpenSSL/platform cryptographic randomness instead of relying only
  on Qt convenience randomness.
- Temporary private-key, BIP38, and recovery-phrase byte buffers are securely
  cleansed after use where Nu owns the memory.
- Paper-wallet entries, QR images, and private-key material remain in memory
  only; the GUI preview stays unbranded while the print sheet uses the v26 coin.
- Bundled a Defcoin Bulk notice file; Nu uses the historical artwork/layout
  reference while keeping key generation and QR creation in native Core/Nu code.

## Verification

- `git diff --check`
- `cmake -S src/qt/nu/app -B build/nu-qml-arm64-26.6.7f -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="/opt/homebrew/opt/qt;/opt/homebrew/opt/openssl@3" -DDEFCOIN_NU_RELEASE_NAME=26.6.7f`
- `cmake --build build/nu-qml-arm64-26.6.7f --target DefcoinCoreNu -j 8`
- `cmake --build build/nu-qml-arm64-26.6.7f --target DefcoinCoreNuResources -j 8`
- `DEFCOIN_NU_SMOKE_TEST=1 DEFCOIN_NU_NO_BACKEND_AUTOSTART=1 DEFCOIN_NU_UI_SELF_TEST_SCREENSHOTS=/tmp/nu-ui-26.6.7f build/nu-qml-arm64-26.6.7f/DefcoinCoreNu.app/Contents/MacOS/DefcoinCoreNu --ui-self-test --allow-multiple`
