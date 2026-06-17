# Defcoin Core Nu 26.6.7t Release Notes

Internal Tahoe candidate focused on release security hardening and version
alignment after the 26.6.7s Paper Wallet build.

## Security

- Keeps paper-wallet private-key import local-only. Nu now refuses to send a
  paper-wallet WIF to wallet RPC unless the configured backend RPC host is
  loopback, even when the remote-RPC operator override is enabled.
- Applies the same local-RPC requirement to wallet passphrase RPCs and
  UI-triggered private-key signing operations.
- Blocks RPC console methods that can transmit or reveal wallet secrets unless
  the backend RPC host is loopback, including private-key signing commands and
  wallet-backed signing commands, descriptor-bearing commands such as
  `scantxoutset`/`utxoupdatepsbt`, plus encrypted wallet creation with a
  passphrase argument.

## Packaging

- Advances the visible candidate label from `26.6.7s` to `26.6.7t` before
  rebuilding artifacts so the backend tools, app metadata, staged folder, and
  DMG do not reuse the earlier label.

## Verification

- Updated roborev to `v0.58.0`, reran maximum-reasoning security review, and
  resolved the reported remote-RPC wallet-secret findings. Final dirty security
  review `job 9` completed with no issues found.
- Built backend tools with
  `make -j6 src/defcoind src/defcoin-cli src/defcoin-tx src/defcoin-wallet`.
  The staged bundle reports `v26.6.7t` for `defcoind`, `defcoin-cli`,
  `defcoin-tx`, and `defcoin-wallet`.
- Built the Tahoe Apple Silicon app with
  `cmake --build build/nu-qml-arm64-26.6.7t --target DefcoinCoreNu -j 8`
  and `cmake --build build/nu-qml-arm64-26.6.7t --target DefcoinCoreNuResources -j 1`.
- Staged and signed
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.7t-20260617/apple-silicon/Defcoin Core Nu.app`;
  `CFBundleShortVersionString` and `CFBundleVersion` are both `26.6.7t`.
- Verified the staged app with `codesign --verify --deep --strict --verbose=2`.
- Verified
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.7t-20260617/apple-silicon/Defcoin-Core-Nu-v26.6.7t-macOS-AppleSilicon.dmg`
  with `hdiutil verify`; SHA-256 is
  `b01ca6b13311c474daa02c41dc419077c5cb8971f742a04e3a29cff5e01a8706`.
- Ran staged-app UI self-test with backend autostart disabled; routes and
  dialogs completed successfully and wrote screenshots under
  `/tmp/defcoin-nu-26.6.7t-ui-self-test/screenshots`.
- Rendered actual paper-wallet print previews from the staged app. Design 1 was
  rendered as the release-enabled path, and Designs 2-5 were separately forced
  through the internal render-only regression path under
  `/tmp/defcoin-paper-wallet-26.6.7t-all-designs`.
- Ran `/usr/bin/xcrun clang-format --dry-run --Werror src/qt/nu/app/NuRpcService.cpp`
  and `git diff --check`.
