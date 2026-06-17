# Defcoin Core Nu 26.6.7h Release Notes

Internal Tahoe candidate focused on making Wallet > Paper Wallet previews match
the real printed paper-wallet pages.

## Changed

- Replaced the independent QML sheet-preview sketch with C++ rendered page
  images from the same paper-wallet renderer used by Print.
- Preview pages now show the selected design's real page geometry, artwork,
  fold layout, QR placement, and double-sided front/back ordering.
- Before key generation, preview pages use explicit placeholder QR boxes rather
  than encoding fake placeholder text as real QR codes.
- Updated Design 1 center-panel typography: `DEFCOIN`, `PAPER`, and `WALLET`
  now print as solid black text, with the `DEFCOIN` title moved down for better
  spacing under the coin.
- Updated Design 1 private-key flap text to start with a fold/tape-shut
  instruction before the private-key exposure warning.
- Added a durable workflow rule for paper-wallet layout work: iterate with the
  preview/PDF render path and inspect generated page images before treating a
  layout change as complete.
- Added `src/qt/nu/tools/render_paper_wallet_previews.sh`, a small self-test
  wrapper that renders all paper-wallet designs to PDFs and PNG pages from an
  existing app bundle.

## Verification

- `git diff --check`
- `/opt/homebrew/bin/qmllint -I src/qt/nu/qml src/qt/nu/qml/Views/PaperWalletView.qml` (warnings only; standalone lint context does not resolve injected `NuService`)
- `/opt/homebrew/bin/cmake --build build/nu-qml-arm64-26.6.7h -j6`
- `src/qt/nu/tools/render_paper_wallet_previews.sh --help`
- `src/qt/nu/tools/render_paper_wallet_previews.sh build/nu-qml-arm64-26.6.7h/DefcoinCoreNu.app /tmp/defcoin-paper-wallet-previews-26.6.7h 6`
- `DEFCOIN_NU_UI_SELF_TEST=1 DEFCOIN_NU_PAPER_WALLET_FORM=0 DEFCOIN_NU_PAPER_WALLET_SELF_TEST_COUNT=3 DEFCOIN_NU_PAPER_WALLET_PDF=/tmp/defcoin-paper-design1-adjusted/design1.pdf build/nu-qml-arm64-26.6.7h/DefcoinCoreNu.app/Contents/MacOS/DefcoinCoreNu --ui-self-test --allow-multiple --debug-use-env`
- `DEFCOIN_NU_UI_SELF_TEST=1 DEFCOIN_NU_PAPER_WALLET_FORM=0 DEFCOIN_NU_PAPER_WALLET_SELF_TEST_COUNT=3 DEFCOIN_NU_PAPER_WALLET_PDF=/tmp/defcoin-paper-design1.pdf build/nu-qml-arm64-26.6.7h/DefcoinCoreNu.app/Contents/MacOS/DefcoinCoreNu --ui-self-test --allow-multiple --debug-use-env`
- `DEFCOIN_NU_UI_SELF_TEST=1 DEFCOIN_NU_PAPER_WALLET_FORM=2 DEFCOIN_NU_PAPER_WALLET_SELF_TEST_COUNT=6 DEFCOIN_NU_PAPER_WALLET_PDF=/tmp/defcoin-paper-design3.pdf build/nu-qml-arm64-26.6.7h/DefcoinCoreNu.app/Contents/MacOS/DefcoinCoreNu --ui-self-test --allow-multiple --debug-use-env`
- `/opt/homebrew/bin/magick -density 140 '/tmp/defcoin-paper-design3.pdf[1]' -quality 90 /tmp/defcoin-paper-design3-page2.png`
