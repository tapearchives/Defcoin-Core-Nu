# Defcoin Core Nu 26.6.7g Release Notes

Internal Tahoe candidate focused on making Wallet > Paper Wallet readable,
staged, and safer to use before the Lion and Windows parity ports.

## Changed

- Reworked Wallet > Paper Wallet into a numbered seven-stage workflow:
  choose design, customize, create entropy, generate, review and print,
  distribute funds into paper wallet, and clear private keys from memory.
- Replaced the old two-QR preview area with a persistent scaled sheet preview
  that uses placeholders before generation, then renders the selected design
  family with generated QR/address data. Double-sided designs show front/back.
- Added an explicit design selector for five print layouts, including the
  simple public/private QR-card layout as the final legacy-style option.
- Added wallet count, cosmetic printed amount, Hide Art, and BIP38/passphrase
  controls before entropy/key generation so the printed sheet can be previewed
  in context.
- Added an always-visible funding stage with a generated-address table, DFC
  amount entry, and reviewed active-wallet `sendmany` funding transaction.
- Added a final Clear Private Keys stage wired to `clearPaperWallet()` so the
  cleanup action is visible after printing. Review and Print no longer has a
  second Clear button.
- Added Paper Wallet leave guards: switching Wallet tabs or routes with
  generated keys in memory now prompts the user to return or erase keys and
  leave.
- Routed View-menu shortcuts through the same leave guard so menu navigation
  cannot bypass the Paper Wallet private-key warning.
- Fixed the staged card layout so expanded stage content contributes to its
  real height instead of overlapping later controls.
- Hardened Wallet tab selection by explicitly setting `walletTabs.currentIndex`
  on each tab click.
- Fixed the Address tab row binding after inserting Paper Wallet so address
  book rows still render on the correct tab.
- Paper-wallet generation now defaults to one wallet and is capped at 100 wallets per run so private-key review
  and print jobs remain bounded.

## Notes

- The printed amount is cosmetic. It does not fund the paper wallet or check
  balance.
- Bulk funded paper-wallet workflows, custom artwork templates, and automatic
  split/distribution beyond the reviewed Nu funding table belong in Explore and
  remain roadmap work.

## Verification

- `git diff --check`
- `qmllint src/qt/nu/qml/Main.qml src/qt/nu/qml/Shell/AppFrame.qml src/qt/nu/qml/Views/WalletView.qml src/qt/nu/qml/Views/PaperWalletView.qml` (warnings only; standalone import path does not resolve injected `NuService`)
- `cmake --build build/nu-qml-arm64-26.6.7g --target DefcoinCoreNuResources -j8`
- `DEFCOIN_NU_SMOKE_TEST=1 DEFCOIN_NU_NO_BACKEND_AUTOSTART=1 DEFCOIN_NU_UI_SELF_TEST_SCREENSHOTS=/tmp/nu-ui-26.6.7g build/nu-qml-arm64-26.6.7g/DefcoinCoreNu.app/Contents/MacOS/DefcoinCoreNu --ui-self-test --allow-multiple`
- `DEFCOIN_NU_UI_SELF_TEST=1 DEFCOIN_NU_PAPER_WALLET_PDF=/tmp/defcoin-paperwallet-26.6.7g-forms/formN.pdf DEFCOIN_NU_PAPER_WALLET_FORM=N DEFCOIN_NU_PAPER_WALLET_SELF_TEST_COUNT=6 build/nu-qml-arm64-26.6.7g/DefcoinCoreNu.app/Contents/MacOS/DefcoinCoreNu --ui-self-test --allow-multiple` for forms `0..4`
