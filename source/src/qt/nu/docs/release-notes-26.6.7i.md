# Defcoin Core Nu 26.6.7i Release Notes

Internal Tahoe candidate focused on paper-wallet responsiveness, preview
accuracy, and entropy UI polish.

## Changed

- Paper Wallet preview rendering is deferred and coalesced so opening Wallet >
  Paper Wallet can show the screen immediately while expensive sheet previews
  render behind a visible loading state.
- Print and Pop Out are available before entropy is complete for alignment and
  duplex testing. Placeholder sheets now carry an explicit unusable/test-print
  warning.
- Added preview zoom controls modeled after Preview-style zoom out, 1:1, and
  zoom in buttons.
- Removed the extra clear-keys step from the workflow; generated private keys
  are cleared through the existing leave-tab warning or app shutdown.
- Updated the entropy panel toward the approved mockup direction: larger dark
  premium stage, gold hourglass rims, denser sand, concave upper sand form,
  convex lower mound, and no raw key-code/debug-number overlay.
- Tightened Design 1 output: center lettering spacing, taller amount box,
  no amount divider, centered private flap QR/warning group, and paragraph
  spacing for the fold/private-key warning.

## Verification

- `git diff --check`
- `/opt/homebrew/bin/qmllint -I src/qt/nu/qml -I build/nu-qml-arm64-26.6.7i src/qt/nu/qml/Views/PaperWalletView.qml` (warnings only; standalone lint context does not resolve injected `NuService`)
- `/opt/homebrew/bin/qmllint -I src/qt/nu/qml -I build/nu-qml-arm64-26.6.7i src/qt/nu/qml/Views/WalletView.qml` (warnings only; standalone lint context does not resolve injected `NuService`)
- `/opt/homebrew/bin/cmake --build build/nu-qml-arm64-26.6.7i -j6`
- `DEFCOIN_NU_UI_SELF_TEST=1 DEFCOIN_NU_NO_BACKEND_AUTOSTART=1 DEFCOIN_NU_UI_SELF_TEST_SCREENSHOTS=/tmp/defcoin-ui-selftest-26.6.7i build/nu-qml-arm64-26.6.7i/DefcoinCoreNu.app/Contents/MacOS/DefcoinCoreNu --ui-self-test --allow-multiple --debug-use-env`
- Design 1 actual print-render inspection:
  `/tmp/defcoin-paper-wallet-design1-26.6.7i-v2/page-00.png`
