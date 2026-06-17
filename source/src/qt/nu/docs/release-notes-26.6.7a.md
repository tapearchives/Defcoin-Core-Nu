# Defcoin Core Nu 26.6.7a Release Notes

26.6.7a skips the 26.6.6 label and is a Tahoe polish, wallet-tab, shutdown,
mining, and Fast Sync selector update after 26.6.5h.

## Changes

- Wallet tab content is now mapped to the visible tab labels. The Recovery tab
  opens BIP39 recovery tools again, Watch-only tools remain under Wallet >
  Tools, and Paper Wallet generation lives in the separate Explore app.
- App quit now routes through a shutdown status overlay before the backend stops,
  warning users not to force-quit while wallets, indexes, and database files are
  closing cleanly.
- Shared Nu panels now retain the existing hover light but add a subtle dark
  purple rollover outline.
- Wallet > Tools is scrollable, so Watch-only controls remain reachable on
  shorter windows.
- Explore adds a Paper Wallet route with mouse/keyboard entropy capture,
  in-memory address/private-key QR previews, a pop-out preview, native printing,
  and a Clear action that removes generated key material from the session.
- Wallet > Files action buttons get a stable wrapping height so default-width
  windows do not crop the rightmost actions.
- The mast/header is cleaner while mining: Network and Wallet remain aligned,
  Sync stays anchored near Wallet, Block keeps the chain-tip status, and average
  block spacing is removed from the mast so it can live in Metrics instead.
- The mining status strip now aligns its status dot and metric text with the
  other header rows.
- Mining > Monitor adds a Follow tail checkbox and keeps current miner output
  pinned to the newest line when enabled.
- Mining pool presets now include `pool.defcoin.fun:3333` and
  `pool.defcoin.io:4044`.
- The splash startup timer/status text is nudged down so it does not collide
  with the splash branding.
- UDP Fast Sync selector cooldown is less punitive for verified UDP peers. A
  verified peer keeps receiving a minimum UDP sample share, so a transient UDP
  failure does not hide useful UDP throughput behind the normal Core path.
- Build acknowledgements now include a fourth "Everyone we forgot" section.

## Cross-Build Notes

- Lion and Windows should port the Wallet tab mapping, mast/header layout,
  shutdown overlay, panel hover outline, Wallet Tools scrolling, mining monitor
  Follow tail control, Explore Paper Wallet placement, mining pool presets, and
  UDP selector cooldown changes.
- Server Fast Sync should match the 26.6.7a user-agent/version identity and the
  same responder/probe behavior, but does not need Quick Clone.
- Metrics should retain average block spacing and the fuller sync diagnostic
  story; the mast should stay short.

## Verification

- Passed: `git diff --check`.
- Passed: paper-wallet whitespace/security closeout checks. Generated WIF/private
  key state stays in process memory, paper QR sources are in-memory data URLs,
  descriptor RPC console input is redacted, and the app does not write paper
  WIFs to settings, logs, files, temp QR images, or external network requests.
- Passed: `ruff check` and `ruff format --check` for
  `src/qt/nu/tools/defcoin_fast_syncd.py`.
- Passed: `qmllint` on the modified Wallet, StatusStrip, Mining, and Main QML
  files. The remaining warnings are the known static-analysis warnings for the
  runtime-provided `Defcoin.Nu` singleton.
- Passed: Tahoe Apple Silicon backend rebuild. Bundled `defcoind`,
  `defcoin-cli`, `defcoin-tx`, and `defcoin-wallet` report v26.6.7a.
- Passed: Tahoe Apple Silicon QML app build, staging, codesign verification,
  and DMG checksum verification.
- Passed: Tahoe paper-wallet check build on 2026-06-11:
  `cmake -S src/qt/nu/app -B build/nu-qml-arm64-paper-wallet-check ...`,
  `cmake --build build/nu-qml-arm64-paper-wallet-check --target DefcoinCoreNuResources -- -j1`,
  and `cmake --build build/nu-qml-arm64-paper-wallet-check --target DefcoinCoreExploreResources -- -j1`.
- Passed: Tahoe Qt 6.11.1 Apple Silicon Nu and Explore resource rebuild from
  `source/build/nu-qml-arm64-26.6.7a` after the Explore parity/self-test pass.
- Passed: Tahoe Nu and Explore `--ui-self-test --allow-multiple` route, menu,
  dialog, and Paper Wallet pop-out walks with screenshots under
  `/tmp/defcoin-nu-ui-selftest-tahoe` and
  `/tmp/defcoin-explore-ui-selftest-tahoe`.
- Staged: Tahoe Nu and Explore Apple Silicon apps/DMGs under the timestamped
  `apple-silicon-20260611_125538` distribution folders.
- Passed: launch-gate first-launch test. The gate cleared any blocking dialogs,
  clicked the Local Network prompt when it appeared, and recorded a clean
  post-allow audit for build 26.6.7a.
- Passed: controlled QML captures from the staged app showed the tightened
  mast/header with `Sync: Ready`, no mast average-block field, and compact block
  status.
- Passed: live Wallet tab smoke test. Recovery shows BIP39 recovery tools, and
  Tools shows Watch-only tools.
- Passed: dc903 server Fast Sync/backend update. The live server now reports
  `/DefcoinCoreNu:26.6.7a/`, keeps the Fast Sync service bit, is synced, and has
  UDP listeners active on `0.0.0.0:10334` and `[::]:10334`.

## Risks / Follow-Up

- Re-check Tahoe, Lion, and Windows Wallet tabs after porting because the visible
  labels are now intentionally mapped against an older panel declaration order.
