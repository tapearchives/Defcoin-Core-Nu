# Defcoin Core Nu 26.6.7u Release Notes

Internal Tahoe Apple Silicon publish candidate after `26.6.7t`.

## Highlights

- Rebuilt the macOS Finder app icon with the modern Icon Composer asset stack.
  Finder now resolves the staged app to `AppIcon` with both `AppIcon.icns` and
  `Assets.car`, and the rendered coin foreground measures `824x824` in the same
  `NSWorkspace` path used to compare Chrome.
- Restored Debug Log under RPC Console as a second tab, preserving line numbers,
  filters, find, copy, save, open-log, and font-size controls.
- Added the `explorer.defcoin.fun` explorer preset and split custom explorer
  templates into transaction and address URL fields.
- Moved the scheduled Defcoin-only magic-byte switch to August 1, 2026 and
  enforced that date in settings load.
- Added one-shot recovery for empty-keypool change-address failures in Send and
  PSBT creation: wallet-scoped `keypoolrefill`, `getrawchangeaddress`, then the
  original RPC retry.

## User-Facing Fixes

- Paper Wallet design dropdowns close when users click the arrow again or click
  the already-selected design.
- The shutdown overlay now stays up while Nu starts cleanup and reports which
  backend/helper shutdown step is in progress.
- Quick Clone receive permission defaults on for new settings.
- Peer Inspection values are selectable and copyable.
- Peers > Traceroute uses Atkinson Hyperlegible Mono and larger single-page
  trippy output dimensions.
- Seed-source display keeps configured names for IPv6 DNS results and prefers
  specific configured seed names over `seed.defcoin.mikej.tech` when the same
  address appears from more than one source.
- Splash, About, Home, and navigation rail branding use the tighter centered
  coin + two-line wordmark ratios from the brand spec.
- About now uses the same canonical coin-to-wordmark ratio as the shared logo
  component, and the recovery-wallet creation dialog uses "Encrypt new wallet"
  instead of "Encrypt recovered wallet".
- Settings > Display and Settings > Updates now use explicit scroll containers
  so expanded explorer URL/status controls stay reachable on smaller windows.

## Packaging

- Visible label is `26.6.7u` in app metadata and bundled Core tools.
- Staged Apple Silicon output:
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.7u-20260617/apple-silicon/`.
- DMG:
  `Defcoin-Core-Nu-v26.6.7u-macOS-AppleSilicon.dmg`.
- SHA-256:
  `174b40d94297732795111771874703bce745244a2ef13c7ca9315756df28274a`.
- The staging script now removes source-only `.agent.md` companions and
  wallet-app Explore-only QML from final app bundles.
- Direct macOS app target builds now install `AppIcon.icns` and `Assets.car`
  into the app bundle, so Finder icons are present even when the resource target
  is not run first.
- Trippy single-page TUI flags are now passed only when the installed
  `trip`/`trippy` binary advertises support; older Trippy binaries fall back to
  legacy stream mode instead of failing the trace.

## Verification

- Homebrew was updated before packaging; `openssl@3` is current at `3.6.2`, and
  the staged app bundles `OpenSSL 3.6.2 7 Apr 2026`.
- `git diff --check` passed.
- `clang-format --dry-run --Werror` passed for touched C++ files.
- Backend tools, Qt app, and Nu resources rebuilt successfully.
- Built-app and staged-app UI self-tests passed with backend autostart disabled.
- Post-review UI self-tests captured Settings > Display and Settings > Updates
  with backend autostart disabled.
- Roborev was updated/current at `v0.58.0`; maximum-reasoning review found the
  direct-target icon and Trippy-flag issues, and the dirty rerun passed with no
  issues found.
- Staged app codesign verification passed.
- `hdiutil verify` passed for the DMG.
- Staged app contains no `.agent.md` files and no wallet-app Explore-only QML.

## Remaining Notes

- The automatic keypool recovery path was built and reviewed but not exercised
  against a live empty-keypool wallet in this pass.
- Export-control language should be reviewed before public distribution.
