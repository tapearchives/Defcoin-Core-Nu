# Cross-Build Internal Change Log

This file is the internal porting ledger for Defcoin Core Nu. Update it for
every Tahoe Nu build that changes behavior, build metadata, UI, backend
interfaces, packaging, or developer assumptions. It is not a user-facing release
note. Its audience is Codex, especially threads building the Lion Intel iMac,
Catalina UTM, Windows, and server variants.

## How To Use This File

For each new build:

1. Add a new version entry at the top of `Entries`.
2. Include the previous version it was based on.
3. Separate what must be ported from what is Tahoe-only.
4. Explain intent and hidden assumptions that a code diff will not reveal.
5. List exact files/functions when porting is likely non-obvious.
6. Include verification commands and the observed result.
7. Note whether Lion, Catalina, Windows, and server builds need equivalent work.

## Entry Template

```text
### <version> - <YYYY-MM-DD> - <short title>

Big picture:
- ...

Porting priority:
- Lion Intel:
- Catalina UTM:
- Windows:
- Server:

Changed behavior:
- ...

Changed files and important details:
- path: why it changed; what to port; what not to port.

Compatibility notes:
- ...

Build/package notes:
- ...

Verification performed:
- command/result

Risks / follow-up:
- ...
```

## Entries

### 26.6.7a - 2026-06-11 - Wallet-tab, shutdown, mining mast, and UDP selector polish

Big picture:
- This build skips the 26.6.6 label and moves Tahoe to 26.6.7a. It is a
  wallet/UI polish and Fast Sync selector tuning pass; it does not alter
  consensus, wallet storage, or block validation.
- The Wallet view had drifted out of sync: the visible Recovery tab opened the
  Paper Wallet / Watch-only tools panel. This build adds an explicit tab-to-panel
  mapping so visible Wallet tab labels open their matching panels.
- The mast/header is tightened for mining and normal sync use. Average block
  spacing is removed from the mast and should remain in Metrics.
- Shutdown now presents a status overlay before quitting, warning users not to
  force-quit while wallets, indexes, and database files are closing cleanly.
- Shared panels keep their existing hover light and add a subtle dark purple
  rollover outline. Wallet > Tools is scrollable so Paper Wallet and Watch-only
  tools stay reachable on smaller windows.
- Verified UDP Fast Sync peers now keep a minimum selector share and shorter
  cooldown, so a transient failure does not make the selector over-prefer the
  normal Core path before UDP has enough fair samples.

Porting priority:
- Lion Intel: required. Port the Wallet tab mapping, mining mast alignment,
  shutdown overlay, shared panel hover outline, scrollable Wallet Tools panel,
  Mining Monitor Follow tail checkbox, new pool presets, splash text nudge, and
  UDP selector cooldown logic using Qt 5.9-compatible controls.
- Catalina UTM: required if it shares Tahoe QML.
- Windows: required. Port the same UI/QML changes and selector behavior.
- Server: required for Fast Sync parity only. Update visible/version identity
  and responder/probe behavior; Quick Clone remains Nu-client only.

Changed behavior:
- Wallet > Recovery now opens recovery phrase tooling; Wallet > Tools opens
  Paper Wallet and Watch-only tools.
- Quitting routes through a visible shutdown sequence before the app asks the
  backend to stop.
- Wallet > Tools scrolls when content exceeds the available height, and Paper
  Wallet copy controls use Nu button styling with enough right-side padding.
- The mast keeps Network/TX/RX/Hashrate/Difficulty on row one and
  Wallet/Sync/Peers/Block on row two, with stable learned slots.
- Mining status uses a single aligned dot plus metric rows instead of mixing a
  status-dot label and metric rows with mismatched baselines.
- Mining > Monitor can follow the live miner log tail without losing scrollbars.
- UDP Fast Sync cooldown is shorter for verified UDP peers and the selector
  keeps probing/sampling verified UDP instead of going silent after minor
  failures.

Changed files and important details:
- `src/clientversion.h`: visible Defcoin release identity moved to `26.6.7a`.
- `src/qt/nu/app/CMakeLists.txt`: default `DEFCOIN_NU_RELEASE_NAME` moved to
  `26.6.7a`.
- `src/qt/nu/app/NuPlatformIntegration.cpp` and `src/qt/nu/qml/Main.qml`:
  native Quit now routes through the QML shutdown status overlay.
- `src/qt/nu/qml/Views/WalletView.qml`: `walletPanelIndexForTab()` maps visible
  Wallet tabs to the historically declared StackLayout panel order; Wallet
  Tools content now scrolls when needed.
- `src/qt/nu/qml/Components/NuPanel.qml` and `NuCopyField.qml`: shared hover
  outline polish and unclipped Copy button styling.
- `src/qt/nu/qml/Shell/StatusStrip.qml`: removes average block time from the
  mast, anchors Sync to row two, and aligns live mining metrics.
- `src/qt/nu/qml/Views/MiningView.qml`: adds the Follow tail checkbox and the
  two new pool presets.
- `src/qt/nu/app/main.cpp`: splash startup status line is nudged down from the
  top edge.
- `src/qt/nu/app/NuRpcService.cpp`: verified UDP peers use shorter failure
  cooldowns and retain selector quota.
- `src/qt/nu/qml/Main.qml`: Build Notes acknowledgements add the fourth
  "Everyone we forgot" section requested by the project owner.

Compatibility notes:
- The UDP selector change is transport-only. Every UDP-received block still goes
  through Core's normal block acceptance and validation path.
- Keep Wallet tab metadata and address-book lazy rendering intact; large wallets
  should not bind thousands of hidden rows just because the Wallet view opened.

Build/package notes:
- Tahoe Apple Silicon build, staging, codesign verification, and DMG checksum
  verification passed on 2026-06-11.
- The staged distribution is
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.7a-20260611/apple-silicon/`.
- dc903 server Fast Sync/backend was updated after Tahoe passed local build
  checks. The live server now advertises `/DefcoinCoreNu:26.6.7a/`; the server
  keeps `DEFCOIN_FASTSYNC` in service bits and UDP listeners on port `10334`.

Verification performed:
- `git diff --check`: passed.
- `ruff check src/qt/nu/tools/defcoin_fast_syncd.py`: passed.
- `ruff format --check src/qt/nu/tools/defcoin_fast_syncd.py`: passed.
- `qmllint` on modified Wallet, StatusStrip, Mining, and Main QML files:
  passed with only the known runtime-singleton static warnings.
- Bundled backend tools report v26.6.7a.
- Launch gate first-launch test recorded a clean post-allow Local Network audit.
- QML grabs verified the tightened mast/header. Live Wallet-tab test verified
  Recovery and Tools content are no longer swapped.
- Server RPC verification reported blocks and headers equal at `2344693` with
  `initialblockdownload=false`, and `defcoind` / `defcoin-fast-syncd` /
  `p2pool-defcoin` were active after restart.

Risks / follow-up:
- Re-check Tahoe, Lion, and Windows Wallet tabs after porting because the
  visible labels are now intentionally mapped against an older panel declaration
  order.

### 26.6.5h - 2026-06-11 - Same-node grouping and embedded trace cleanup

Big picture:
- This build finishes the peer same-node grouping UX and tightens the route
  tracing path. It does not change consensus, wallet storage, or block
  validation.
- Current Nu nodes advertise a persistent random `node_unique_id` during
  low-frequency LAN beacon and UDP Fast Sync probe/ack negotiation. Peer tables
  use that value, or a strong LAN workstation-name fallback, to identify when
  multiple rows appear to be the same running node over different paths.
- Fast Sync/Quick Clone in-flight scheduling now also collapses known
  `node_unique_id` matches into one logical peer so IPv4 and IPv6 rows from the
  same machine do not consume parallel UDP slots as if they were independent
  sources. If the active path fails or cools down, the alternate host path can
  still be selected later.

Porting priority:
- Lion Intel: required. Port the display-only `(gN)` node grouping suffix,
  `node_unique_id` peer detail row, in-app Trippy stream window behavior, and
  package cleanup.
- Catalina UTM: required if it shares Tahoe QML.
- Windows: required. Keep `trip.exe` bundled only when a real Windows target
  binary is available, do not run Unix chmod commands during CMake resource
  staging, reject host `/opt/homebrew` qrencode during Windows cross-builds,
  and preserve real numeric peer ids for peer actions.
- Server: required only for Fast Sync negotiation parity. Server code should
  learn/use `node_unique_id` during negotiation, not in every block/chunk
  payload.

Changed behavior:
- The peer Node column keeps Core's numeric peer id and appends a suffix like
  `(g1)` only when at least two current rows appear to be the same running Nu
  node.
- Hovering the Node column explains `(gN)`. Peer actions still use Core's real
  numeric peer id from metadata.
- `node_unique_id` is displayed in peer inspection where known.
- Trippy now launches in unprivileged stream mode with bounded report cycles so
  the in-app trace window receives readable text output.
- Lion packaging now moves the final `.app` to the output directory and removes
  temporary `stage/` and `dmg-root/` folders after packaging.

Changed files and important details:
- `src/clientversion.h`: visible Defcoin release identity moved to `26.6.5h`.
- `src/qt/nu/app/CMakeLists.txt`: default `DEFCOIN_NU_RELEASE_NAME` moved to
  `26.6.5h`; Trippy copy hooks no longer run `/bin/chmod` on Windows; Windows
  qrencode resolves through `DEFCOIN_NU_QRENCODE_ROOT` or the project target
  toolchain instead of host Homebrew; Windows Trippy auto-detection searches
  target toolchain paths only.
- `src/qt/nu/app/NuRpcService.cpp`: peer row metadata now computes
  display-only group ids from `node_unique_id` or strong LAN workstation names;
  `fastSyncLogicalPeerKey()` and the local in-flight counter prevent duplicate
  same-node UDP scheduling; `tracePeer()` runs
  `trip -u --mode stream --report-cycles 16`.
- `src/qt/nu/qml/Views/NodeView.qml`: Node column hover text and peer
  inspection explain/display `(gN)` without changing selection keys.
- Lion `src/qt/nu/legacy-osx107/main.cpp`: same display-only grouping and peer
  detail behavior in the Qt Widgets table.
- Lion `contrib/legacy-osx107/package_legacy_dmg.sh`: optional `--trip` copy
  hook and cleanup of temporary packaging folders.

Compatibility notes:
- `(gN)` is not a Core node id and must never be passed to RPC. Keep using
  `meta.nodeId` / table item metadata for Retest FastSync, Ban, Inspect, and
  Traceroute.
- Do not put `node_unique_id` in high-volume Fast Sync block request/chunk
  payloads. It belongs in beacons/probes/acks and peer metadata.
- `Scanning...` LAN names must not be used as grouping keys.

Build/package notes:
- Tahoe target: `26.6.5h`.
- Lion target: `26.6.5h-Lion-alpha`.
- Windows target should use the same `26.6.5h` visible label after parity.
- Windows builds need `QT_HOST_PATH` pointed at the bundled macOS Qt host tools
  and `CMAKE_PREFIX_PATH`/`Qt6_DIR` pointed at the bundled MinGW Qt target tree.
- If no Windows `trip.exe` exists, omit it from the package. Nu falls back to
  Windows `tracert`; shipping the macOS `trip` binary as `trip.exe` is invalid.

Verification performed:
- Tahoe Apple Silicon `26.6.5h` DMG built and verified.
- Physical Lion `26.6.5h-Lion-alpha` Qt 5.9 package built, verified with
  `hdiutil verify`, and smoke-launched with no Qt `No such slot` warnings.
- Windows 11 x86_64 package built from fresh 26.6.5h backend binaries and
  staged at
  `/Volumes/TB5_4TB/d/litecoincore/Tools/Defcoin Core Nu/Nu-26.6.5h-Windows-11-x86_64-20260611_031651`.
- Windows package verification confirmed one setup EXE, one portable ZIP,
  required Qt/runtime/backend files, target PE binaries, and no bundled
  non-Windows `trip.exe`.
- dc903 server Fast Sync responder updated and restarted. Loopback probe
  confirmed `probe-ack` includes the persisted server `node_unique_id`.

Risks / follow-up:
- A real Windows `trip.exe` is still not bundled because no Windows Trippy
  target binary/toolchain is present locally. Windows Nu falls back to
  `tracert` in the same in-app trace window.

### 26.6.5g - 2026-06-10 - Peer inspect, traceroute, and DMG staging cleanup

Big picture:
- This build adds a readable per-peer inspection popup and a peer route-trace
  launcher to Metrics > Peers. It does not change consensus, wallet storage, or
  Fast Sync block scheduling.
- Apple Silicon packaging now keeps the generated DMG background inside the
  temporary DMG stage instead of leaving a sidecar PNG in the distribution
  folder.

Porting priority:
- Lion Intel: required. Port the user affordances and grouped peer detail view
  with Lion-compatible UI widgets. Trippy may be optional if the Lion toolchain
  cannot support a current `trip` binary.
- Catalina UTM: required if it shares Tahoe QML.
- Windows: required. Use `trip.exe` when present and fall back to `tracert`.
- Server: not applicable.

Changed behavior:
- Double-clicking a peer row opens a grouped peer detail popup.
- `Inspect Peer` is enabled when exactly one peer row is selected.
- `Traceroute` is enabled when one or more peer rows are selected and opens one
  route window per selected peer.
- Traceroute prefers Trippy's `trip` binary, then falls back to system
  traceroute/tracert.
- Header TX/RX compact rates drop the ordinary `~` marker; a `+` remains only
  for capped display values.
- Apple Silicon distribution folders no longer retain
  `defcoin-core-nu-dmg-background.png` or the Explore equivalent.

Changed files and important details:
- `src/clientversion.h`: visible Defcoin release identity moved to `26.6.5g`.
- `src/qt/nu/app/CMakeLists.txt`: default `DEFCOIN_NU_RELEASE_NAME` moved to
  `26.6.5g`.
- `src/qt/nu/qml/Views/NodeView.qml`: peer detail dialog, `Inspect Peer`,
  `Traceroute`, and double-click handling.
- `src/qt/nu/app/NuRpcService.h/.cpp`: `tracePeer()` launches Trippy or a
  platform fallback traceroute for a selected peer endpoint.
- `src/qt/nu/app/CMakeLists.txt`: optional `DEFCOIN_NU_TRIPPY_BINARY`
  autodetect/copy hook bundles `trip` into `nu/bin` when present.
- `src/qt/nu/app/stage_macos_distribution.sh`: DMG background output now points
  at the temporary staging folder and removes any legacy sidecar PNG.
- `src/qt/nu/qml/Main.qml` and `doc/license-and-attribution-notices.md`: Trippy
  optional-tool credit and Apache-2.0 attribution note.
- `src/qt/nu/assets/licenses/trippy-Apache-2.0-LICENSE.txt`: bundled Trippy
  Apache-2.0 license text.

Compatibility notes:
- `tracePeer()` intentionally depends on the current peer endpoint map. It
  should fail with a user-visible message if the selected peer is stale.
- If Trippy is bundled on another platform, set `DEFCOIN_NU_TRIPPY_BINARY` and
  ship the Apache-2.0 license and any upstream NOTICE material with that
  package.

Verification performed:
- `git diff --check` passed.
- `bash -n src/qt/nu/app/stage_macos_distribution.sh` passed.
- `qmllint -I src/qt/nu/qml src/qt/nu/qml/Views/NodeView.qml` passed with
  only the expected out-of-bundle `Defcoin.Nu` import warning.
- `cmake --build build/nu-qml-arm64-26.6.5g --target DefcoinCoreNu -j 6`
  passed on Tahoe.
- `cmake --build build/nu-qml-arm64-26.6.5g --target DefcoinCoreNuResources
  -j 1` passed and `codesign --verify --deep --strict --verbose=2` passed.
- Apple Silicon staging passed and `hdiutil verify` reported a valid checksum
  for `Defcoin-Core-Nu-v26.6.5g-macOS-AppleSilicon.dmg`.
- The staged Apple Silicon distribution folder contains the app and DMG only
  besides Finder metadata; no generated DMG background PNG remains beside them.
- The staged Apple Silicon app includes signed `Contents/Resources/nu/bin/trip`
  and the Trippy Apache-2.0 license asset.

Risks / follow-up:
- The route trace window is intentionally external because Trippy is a terminal
  TUI. A future build can embed structured JSON output if we want in-app trace
  rendering.

### 26.6.5f - 2026-06-10 - Splash, mast, wallet backup, and traffic polish

Big picture:
- This build tightens visible startup and day-to-day wallet UI behavior after
  26.6.5e. It does not change consensus, wire protocol, Fast Sync reservation,
  or Quick Clone scheduling.
- The mast is no longer a wrapping `Flow`; it is a stable two-line status strip
  with fixed slot widths so TX/RX and chain numbers do not cause constant visual
  shifting.
- Large wallets should no longer freeze the Tools tab just because an offscreen
  address-book table tried to render thousands of rows.

Porting priority:
- Lion Intel: required. Port the same intent to the legacy UI: splash progress
  must not collide, mast/status metrics should be stable, active-wallet backup
  names should identify the selected wallet, and large address books must not be
  rendered while hidden.
- Catalina UTM: required if it shares the QML shell.
- Windows: required. Rebuild/check both QML frontend and bundled backend; the
  26.6.5e Windows package still had an older inherited backend.
- Server: not applicable unless backend release label propagation is needed in
  a later server package.

Changed behavior:
- Startup splash progress text is centered at the top of the splash instead of
  drawing over the bottom version/copyright text.
- Header line 1 shows Network, TX, RX, Hashrate, Difficulty, Avg block, Peers,
  and Block in stable slots.
- Header line 2 shows Wallet in the same left slot under Network, then Sync.
- Header slot widths learn normal-window content widths and persist through
  the existing `NuTables/statusHeaderSlots` settings path. Reset views clears
  that key and restores first-launch header spacing.
- Active wallet backup defaults to `wallet_<active-wallet>.dat` for BDB/unknown
  wallets and `wallet_<active-wallet>.sqlite` for SQL wallets.
- Wallet address-book rendering is lazy: hidden tabs render no rows, and the
  Addresses tab starts at 500 rows with explicit show-more/show-all controls.
- Metrics Traffic Details colors now keep received components in a green lane
  and sent components in a blue lane, with the total receive/send outline drawn
  on top of each stack.
- Peak labels now use a small readable plate rather than a dark text stroke.

Changed files and important details:
- `src/clientversion.h`: visible Defcoin release identity moved to `26.6.5f`.
- `src/qt/nu/app/CMakeLists.txt`: default `DEFCOIN_NU_RELEASE_NAME` moved to
  `26.6.5f`.
- `src/qt/nu/app/main.cpp`: `StartupReporter::step()` splash message alignment
  changed to centered top.
- `src/qt/nu/qml/Shell/StatusStrip.qml`: replaced mast `Flow` with stable
  two-line layout slots and settings-backed learned widths.
- `src/qt/nu/app/NuRpcService.cpp`: `backupWallet()` default filename now uses
  current wallet name and detected storage type.
- `src/qt/nu/qml/Views/WalletView.qml`: address-book rows are only generated
  when the Addresses tab is active, and large wallets render incrementally.
- `src/qt/nu/qml/Components/NuTimelineGraph.qml`: Details palette, total
  outlines, and peak label rendering updated.

Compatibility notes:
- The QML changes are Tahoe/Catalina/Windows friendly. Lion needs equivalent
  legacy QtWidgets behavior rather than a literal QML import.
- The backup filename change only changes the save-dialog default path; Core's
  `backupwallet` RPC still performs the actual backup.
- The address-book row cap is presentation-only and does not prune wallet data.

Verification performed:
- `git diff --check` passed for touched Tahoe files.
- `/opt/homebrew/bin/qmllint -I src/qt/nu/qml` on the touched QML files exited
  0 with only the known local `Defcoin.Nu` import warning outside a built
  bundle.

Risks / follow-up:
- Build and visually inspect Tahoe before release.
- Rebuild/check Windows and Lion parity before marking this complete.
- Keep compact-window header slots fixed; only normal-width slots should learn
  and persist, otherwise narrow windows can become unstable.

### 26.6.5e - 2026-06-10 - Qt 6.11 traffic chart compatibility pass

Big picture:
- Tahoe now has Qt 6.11.1 available locally, including `QtCanvasPainter` and
  `QtTaskTree`, but this build deliberately does not link either new module.
- `QtCanvasPainter` is Technology Preview and licensed Commercial/GPLv3 in Qt
  6.11.1, which is not a good production dependency for the MIT-derived Nu
  wallet line without an explicit licensing decision.
- `QtTaskTree` is also Technology Preview. It may be useful later for backend
  launch/RPC/index workflows, but this pass avoids a broad async rewrite while
  Fast Sync/Quick Clone are still being stabilized.
- Metrics Traffic keeps the Qt Quick Canvas path so Tahoe, Windows, Catalina,
  and Lion can share the same chart semantics.
- The Tahoe launch-test gate now treats a new `DefcoinCoreNu` `SIGABRT` crash
  report as a hard launch failure. It clears the visible macOS crash dialog by
  clicking `Ignore`, records the DiagnosticReports path, and stops before LAN
  Allow or UDP testing.

Porting priority:
- Lion Intel: done in the legacy QtWidgets UI. It uses the same visible model:
  simple mode shows total received/sent; Details mode stacks TCP, Fast Sync UDP,
  and Quick Clone UDP components.
- Catalina UTM: required before next UI rebuild if it shares the QML shell.
- Windows: required. Rebuild from this source so the footer and hover labels
  match Tahoe.
- Server: not applicable. No Fast Sync protocol change.
- Test tooling: port or keep equivalent launch-gate behavior on any macOS build
  host that runs automated Nu launch tests. This is not needed on Windows or the
  server.

Changed behavior:
- Metrics Traffic Details mode now separates `TCP`, `FS UDP`, and `QC UDP` for
  both received and sent traffic.
- Simple mode remains quiet and still shows only total received and total sent.
- Hover text reports the three component rates so Quick Clone UDP is visible
  without being mistaken for a third transport.
- The footer grid now shows `TCP`, `FS UDP`, `QC UDP`, and total traffic totals.
- Quick Clone traffic is still counted inside total UDP traffic and exported
  through the existing `quickClone*` sample fields.
- A new `macos_click_visible_button` helper provides an OCR fallback for system
  dialogs that are visible but not reliably exposed through Accessibility.
- `nu_test_launch_gate.sh` records a crash scan timestamp before `open`, checks
  for a fresh `SIGABRT` report if no PID appears, and also watches for early
  splash-then-abort crashes for 10 seconds after the PID appears.

Changed files and important details:
- `src/clientversion.h`: visible Defcoin release identity moved to `26.6.5e`.
- `src/qt/nu/app/CMakeLists.txt`: default `DEFCOIN_NU_RELEASE_NAME` moved to
  `26.6.5e`.
- `src/qt/nu/qml/Components/NuTimelineGraph.qml`: Details mode now paints
  stacked TCP / Fast Sync UDP / Quick Clone UDP areas from existing sample keys.
- `src/qt/nu/qml/Views/NodeView.qml`: Metrics footer grid now breaks out TCP,
  Fast Sync UDP, Quick Clone UDP, and total traffic.
- `src/qt/nu/qml/Components/NuTimelineGraph.qml.agent.md`: updated invariants
  for the new chart model.
- `src/qt/nu/tools/macos_click_visible_button.sh/.swift`: generic OCR clicker
  for exact button text inside required visible context text.
- `src/qt/nu/tools/nu_test_launch_gate.sh`: new `SIGABRT` crash-report gate and
  crash-dialog clear path.

Compatibility notes:
- Do not port `QtCanvasPainter` to Lion or Windows yet. It is not required for
  this visual model, is Technology Preview, and is not LGPL in Qt 6.11.1.
- Do not introduce `QtTaskTree` until the async workflow being migrated is
  isolated and tested; the current timer/RPC flow remains the stable path.
- No 3D graph was added. TX/RX comparison is clearer as stacked 2D rates and is
  easier to backport.

Verification performed:
- `/opt/homebrew/bin/qmllint -I source/src/qt/nu/qml` on `NuTimelineGraph.qml`
  and `NodeView.qml` exited 0 with only the known local `Defcoin.Nu` import
  warning outside a built bundle.
- `/opt/homebrew/bin/qmlformat --check` is not available in this Qt install; no
  broad formatting rewrite was run.
- Tahoe `26.6.5e` built and staged at
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.5e-20260610/apple-silicon/Defcoin Core Nu.app`.
- Tahoe DMG staged and verified at
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.5e-20260610/apple-silicon/Defcoin-Core-Nu-v26.6.5e-macOS-AppleSilicon.dmg`.
- Tahoe staged app verifies with `codesign --verify --deep --strict`, embeds
  backend tools reporting `v26.6.5e`, and links Qt frameworks reporting
  `6.11.1`.
- Windows frontend rebuilt from the same QML source at
  `build/nu-qml-win64-26.6.5e` and packaged under
  `/Volumes/TB5_4TB/d/litecoincore/Tools/Defcoin Core Nu/Nu-26.6.5e-Windows-11-x86_64-20260610_083037`.
- Windows portable ZIP passed `unzip -t`; setup EXE is a Nullsoft GUI
  installer. The Windows frontend reports `26.6.5e`, but the embedded Windows
  backend is inherited from the prior Windows backend build and reports
  `v26.6.5a` because no fresh Windows backend rebuild was completed in this
  pass.
- `bash -n` passed for `nu_test_launch_gate.sh` and
  `macos_click_visible_button.sh`.
- `macos_click_visible_button.sh --button Ignore --context "quit unexpectedly"
  --timeout 1` compiled and returned `context_not_found` with no crash dialog
  visible, proving it did not click anything opportunistically.

Risks / follow-up:
- If Windows backend behavior changes are needed, rebuild the Windows backend
  executables before packaging; this pass changed only the Qt/QML shell and
  frontend release identity.
- Build Tahoe and Windows from this source before release.
- If a future build adopts Qt Canvas Painter, document the explicit license
  decision and provide a non-CanvasPainter fallback before merging it.

### 26.6.5d - 2026-06-10 - Sync mode mast and Quick Clone request isolation

Big picture:
- This build fixes confusing Quick Clone/Fast Sync status mixing and makes the
  mast show the active sync transport in a compact form.
- Quick Clone and Fast Sync still share the UDP transport implementation, but a
  block transfer now carries its own `clone_mode` flag from request through
  chunk assembly and submit status. Do not derive transfer type from the global
  Quick Clone setting.
- The visible Quick Clone setting is now an allowed/armed preference. A
  session-only request flag controls actual Quick Clone scheduling after the
  prompt/manual action. This prevents default-on settings from silently
  hijacking ordinary UDP Fast Sync.
- Traffic rate displays now use bits per second for rates. Total volume remains
  byte based.

Porting priority:
- Lion Intel: required. Port the per-request `clone_mode` parameter, earliest
  missing-block Quick Clone scheduling, staged-gap debug log, status text, and
  Settings/Peers/UI changes.
- Catalina UTM: required before its next package if it shares the Qt/QML shell.
- Windows: required. This shared source has the Windows QML/C++ changes; rebuild
  the Windows package from this source before testing the LAN icon and traffic
  footer there.
- Server: no Quick Clone UI. Keep Fast Sync responder behavior unchanged except
  for any shared transport-only bug fixes that do not depend on the QML service.

Changed behavior:
- Mast `Sync` value now reports `via TCP`, `via UDP FS`, `via UDP QC`, or
  `Up to Date`, then the current block/header progress and ETA while syncing.
- Mast shows compact `TX:` and `RX:` recent traffic rates.
- Quick Clone receiver requests the earliest missing Core-reserved block instead
  of filling a farther-ahead staged cache first.
- Staged-gap logs use `NU_UDP_FASTSYNC_STAGED_GAP mode=quick-clone|fast-sync`.
- Quick Clone settings default on for both receive and provide:
  `Allow Quick Clone from LAN nodes` and `Provide Quick Clones to LAN nodes`.
- Accepting the Quick Clone prompt or clicking the manual action starts the
  session. Merely enabling the checkbox keeps the node armed and listening.
- Metrics details show TCP and UDP; Quick Clone UDP is counted inside UDP, not
  as an extra graph/footer total.
- Services column is left-justified; Protocol Version and Magic are centered;
  workstation cells reserve width for the LAN icon.

Changed files and important details:
- `src/clientversion.h`: visible Defcoin release identity moved to `26.6.5d`.
- `src/qt/nu/app/CMakeLists.txt`: default `DEFCOIN_NU_RELEASE_NAME` moved to
  `26.6.5d`.
- `src/qt/nu/app/NuRpcService.h/.cpp`: added `syncTransportMode`,
  `trafficReceivedRate`, `trafficSentRate`, `lanQuickCloneProvideEnabled`,
  per-request `clone_mode`, session-only Quick Clone request state, bit-rate
  formatting helpers, clone-aware status, and throttled staged-gap diagnostics.
- `src/qt/nu/qml/Shell/StatusStrip.qml`: mast sync mode and TX/RX rates.
- `src/qt/nu/qml/Views/SettingsView.qml`: compact Quick Clone checkbox row and
  the new provider toggle.
- `src/qt/nu/qml/Views/NodeView.qml`: traffic footer consolidation and peer
  column alignment.
- `src/qt/nu/qml/Components/NuTimelineGraph.qml`: detail graph now draws TCP and
  UDP components only; Quick Clone remains part of UDP.
- `src/qt/nu/qml/Components/NuDataTable.qml`: workstation LAN-icon auto-fit
  padding and revised alignment heuristics.

Verification performed:
- `git diff --check` passed.
- `qmllint -I src/qt/nu/qml` on the touched QML files exited 0 with only the
  known `Defcoin.Nu` import/context-property warnings.
- Native Apple Silicon `DefcoinCoreNu` build completed in
  `build/nu-qml-arm64-26.6.5d`.

Risks / follow-up:
- Live UDP/Quick Clone testing still requires the macOS Local Network `Allow`
  prompt to be cleared on first launch of the new Tahoe app bundle.
- The Lion port must keep the same status strings and debug marker names so
  cross-machine log comparison stays useful.

### 26.6.5b - 2026-06-10 - Windows launch visibility and menu crash guard

Big picture:
- This is a Windows-focused stability pass after the 26.6.5a UI/metrics build.
- No consensus, wallet storage, Fast Sync, or Quick Clone protocol behavior
  changed.
- The main goals are to make slow Windows launches observable and remove recent
  UI-thread/menu crash risks.

Technical changes:
- `src/clientversion.h`: visible Defcoin release identity moved to `26.6.5b`.
- `src/qt/nu/app/CMakeLists.txt`: default `DEFCOIN_NU_RELEASE_NAME` moved to
  `26.6.5b`.
- `src/qt/nu/app/main.cpp`: adds `nu-gui-launch.log`, QML-warning capture, and
  startup splash phase messages with elapsed seconds.
- `src/qt/nu/app/NuRpcService.cpp`: wallet Nu builds skip startup loading of the
  separated Explorer recent-lookups SQLite cache and contact sets; Explore
  builds still load them.
- `src/qt/nu/qml/Main.qml`: menu-open handlers no longer call
  `NuService.refresh()` while the user is opening File/Open Wallet menus.
- `src/qt/nu/qml/Components/NuMenuItem.qml`: Windows disables the extra
  per-menu-item `Shortcut` wrapper to avoid a Qt 6.10 Windows menu crash path.

Verification performed:
- `git diff --check` passed.
- `qmllint` passed for the changed QML files with only existing
  context-property/import warnings.
- `clang-format --dry-run --Werror` passed for the changed C++ files.
- Native Apple Silicon syntax build completed.
- Windows Qt 6.10.1 MinGW frontend build completed, and the Windows payload was
  packaged into a clean NSIS setup EXE and portable ZIP under the Tools folder.
- The portable ZIP tested cleanly and the package contains the required Qt
  runtime files, platform plugin, `qt.conf`, and backend tools.
- PE import audit against the cleaned payload found no missing non-system DLLs.

Packaging caveat:
- The 26.6.5b Windows package reuses the prior Windows backend executables. The
  frontend/backend protocol did not change in this pass, but the backend depends
  rebuild is still blocked by whitespace in the current `Defcoin Core Nu` path.
  Use a no-space backend build root before the next backend-facing Windows
  release.

### 26.6.5a - 2026-06-10 - Metrics traffic clarity and mast alignment

Big picture:
- This is a UI/metrics clarity build after the 26.6.5 style baseline.
- No consensus or wallet-storage behavior changed.
- The main cross-build risk is keeping the new traffic counter names and QML
  graph sample fields in parity on Lion and Windows.

Technical changes:
- `src/clientversion.h`: visible Defcoin release identity moved to `26.6.5a`.
- `src/qt/nu/app/CMakeLists.txt`: default `DEFCOIN_NU_RELEASE_NAME` moved to
  `26.6.5a`.
- `src/qt/nu/app/NuRpcService.h/.cpp`: split formatted Fast Sync UDP totals out
  of the existing UDP total by subtracting the Quick Clone UDP subset. Traffic
  samples now include `fastSyncUdpReceived` and `fastSyncUdpSent`; CSV export
  also includes those columns.
- `src/qt/nu/qml/Components/NuTimelineGraph.qml`: Traffic simple mode remains
  total sent/received; Details mode draws stacked filled TCP / FS UDP / QC UDP
  components for sent and received groups with unique labels and colors.
- `src/qt/nu/qml/Views/NodeView.qml`: one linked `Details` switch now controls
  Traffic, Status, and Peers. Footer totals show TCP, FS UDP, QC UDP, and total.
- `src/qt/nu/qml/Views/MiningView.qml`: Reward Calculator `Use current values`
  fills current miner hashrate in KH/s when Nu has a running miner hashrate.
- `src/qt/nu/qml/Shell/StatusStrip.qml`,
  `src/qt/nu/qml/Components/NuStatusDot.qml`, and
  `src/qt/nu/qml/Components/NuMetricRow.qml`: mast dot/text alignment tightened.
- `src/qt/nu/qml/Components/NuDataTable.qml`: row height estimation now respects
  explicit newline-separated summaries while avoiding extra height for one-line
  content.

Verification performed:
- `git diff --check` passed.
- `qmllint -I src/qt/nu/qml` on the touched QML files exited 0 with only the
  known `Defcoin.Nu` import/context-property warnings.
- `/opt/homebrew/bin/ruff check --config source/src/qt/nu/tools/ruff.toml
  source/src/qt/nu/tools source/src/qt/nu/app/repair_macos_qt_bundle.py` passed.
- `/opt/homebrew/bin/ruff format --check --config source/src/qt/nu/tools/ruff.toml
  source/src/qt/nu/tools source/src/qt/nu/app/repair_macos_qt_bundle.py` passed.
- `clang-format --dry-run --Werror` passed for `NuRpcService.cpp/.h`.
- Tahoe Apple Silicon resources build passed for
  `build/nu-qml-arm64-26.6.5a`.
- Windows backend and Nu Qt shell/resources build passed for
  `build/nu-qml-win64-26.6.5a`; packaged one NSIS setup EXE and one portable
  ZIP in `Tools/Defcoin Core Nu/Nu-26.6.5a-Windows-11-x86_64-20260610_053604`.
- Lion source parity changes were applied and lint-clean locally, but the
  physical Lion iMac at `192.168.2.19` was unreachable during this pass, so the
  Lion package build still needs to run when that host is back online.

### 26.6.5 - 2026-06-10 - Nu style baseline and DOX tool notes

Big picture:
- Tahoe moves from the 26.6.4 letter-suffix line to the `26.6.5` release
  label. The change is intentionally a developer-quality/style baseline, not a
  Fast Sync or wallet behavior change.
- Nu-owned C++, Objective-C++, and helper code under `src/qt/nu` now has a
  local clang-format policy that is separate from upstream/Core formatting.
- The Nu tools folder now has a DOX index and `defcoin_fast_syncd.py` has a
  companion agent note documenting the responder-only Fast Sync assumptions.

Porting priority:
- Lion Intel: required for source-hygiene parity. Use the same DOX/companion
  model, but keep Ruff rules conservative because Lion-era scripts may need
  older Python compatibility.
- Catalina UTM: recommended. The style policy is Tahoe-source-first, but
  Catalina should not diverge in Nu-owned code style.
- Windows: recommended before the next Windows package. Use the same
  `26.6.5` label and avoid applying the Nu style to upstream Core files.
- Server: read the new `defcoin_fast_syncd.py.agent.md` before changing the
  Fast Sync responder; no server feature change is introduced by this entry.

Changed behavior:
- No intended runtime behavior changes.
- Frontend and backend visible release labels now report `26.6.5`.

Changed files and important details:
- `src/clientversion.h`: `DEFCOIN_RELEASE_VERSION_STR` advanced to `26.6.5`
  so backend tools and About/splash backend identity agree.
- `src/qt/nu/app/CMakeLists.txt`: project version and
  `DEFCOIN_NU_RELEASE_NAME` advanced to `26.6.5`.
- `src/qt/nu/.clang-format`: local Nu formatter policy, with separate C++ and
  Objective-C sections so `.mm` files parse correctly.
- `src/qt/nu/tools/AGENTS.md`: DOX index for Nu tools.
- `src/qt/nu/tools/defcoin_fast_syncd.py.agent.md`: documents server/LAN
  Fast Sync responder boundaries.

Compatibility notes:
- Do not run this Nu style profile over upstream Core files outside
  `src/qt/nu`.
- Do not enable Ruff `UP`/pyupgrade rules on Lion scripts until the target
  Python runtime is confirmed.

Build/package notes:
- Tahoe target: Apple Silicon `26.6.5`.
- Lion target should use `26.6.5-Lion-alpha` if rebuilt for parity.

Verification performed:
- `/usr/bin/xcrun clang-format -style=file --dump-config` passed for both
  `NuRpcService.cpp` and `MacHelp.mm` assumptions.
- `ruff check --fix` and `ruff format` were run on Nu Python helpers; no Python
  source changes were needed.
- `python3 src/qt/nu/tools/defcoin_fast_syncd.py --help` exits successfully.
- Backend tools rebuilt and report `v26.6.5`.
- `cmake -S source/src/qt/nu/app -B build/nu-qml-arm64-26.6.5 -G Ninja ...`
  configured successfully.
- `cmake --build build/nu-qml-arm64-26.6.5 --target DefcoinCoreNuResources
  -j6` completed successfully.
- Staged Tahoe Apple Silicon app:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.5-20260610/apple-silicon/Defcoin Core Nu.app`.
- Staged Tahoe Apple Silicon DMG:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.5-20260610/apple-silicon/Defcoin-Core-Nu-v26.6.5-macOS-AppleSilicon.dmg`.
- Staged app `Info.plist` reports `CFBundleShortVersionString=26.6.5` and
  `CFBundleVersion=26.6.5`.
- Bundled `Contents/Resources/nu/bin/defcoind` reports `Defcoin Core Nu version
  v26.6.5`.
- `codesign --verify --deep --strict` passed. `spctl --assess` rejects the
  ad-hoc-signed local build as expected without Developer ID notarization.
- `mdls` reports `kMDItemKind = "Application"` and
  `kMDItemContentType = "com.apple.application-bundle"` for the staged app.

Risks / follow-up:
- Large `NuRpcService.cpp` and `NuRpcService.h` diffs are mechanical
  formatting churn. Review functional patches separately from this style
  baseline when debugging regressions.

### 26.6.4cf - 2026-06-10 - Traffic graph identity and instance relaunch guard

Big picture:
- Metrics > Traffic now treats Quick Clone correctly as UDP traffic, not as a
  fourth transport family. The chart and footer show TCP, UDP, and total
  traffic only; the Quick Clone operational copy rate remains on Metrics >
  Status.
- Duplicate-instance startup handling now re-checks the lock after the user
  presses OK. It no longer exits after one warning while leaving the user to
  guess whether the first instance closed.

Porting priority:
- Lion Intel: required. Port the graph/footer simplification and the
  single-instance re-check dialog.
- Catalina UTM: required for UI parity.
- Windows: required for startup parity; use the Windows task close path in
  `requestSingleInstanceOwnerClose()`.
- Server: not required; no server behavior changed.

Changed behavior:
- Traffic graph line contract:
  solid green/blue are total received/sent, dashed teal/blue are TCP
  received/sent, dotted lime/purple are UDP received/sent.
- Quick Clone bytes are still counted by `recordLanFastSyncUdpTraffic()` into
  `m_lan_fast_sync_udp_bytes_*`; clone-mode datagrams additionally update the
  Quick Clone subset counters for Status text only.
- The traffic footer is a 2x3 data grid: TCP, UDP, Total traffic.
- If another Nu window owns the GUI lock, pressing OK checks the lock again.
  The dialog reappears if the other window is still open, and includes a
  `Close Other Instance` action.

Changed files and important details:
- `src/qt/nu/qml/Components/NuTimelineGraph.qml`: removed Quick Clone as a
  separate series; assigned distinct colors and labels to each remaining
  traffic series.
- `src/qt/nu/qml/Views/NodeView.qml`: removed the Quick Clone footer column.
- `src/qt/nu/app/main.cpp`: added single-instance helper functions and a
  re-check loop around the GUI `QLockFile`.
- `src/qt/nu/tools/nu_test_launch_gate.sh`: stopped using AppleScript
  application-name quit commands because macOS can resolve `Defcoin Core Nu` to
  a stale test bundle and launch it while trying to quit it. The helper now
  closes already-running Nu frontends by PID.
- `src/clientversion.h`, `src/qt/nu/app/CMakeLists.txt`: version advanced to
  `26.6.4cf`.

Compatibility notes:
- Do not remove the Quick Clone counters from C++; Status still uses them to
  report Quick Clone copy rate. Only the graph/footer should hide the separate
  Quick Clone column.
- UDP totals must include both Fast Sync UDP and Quick Clone UDP.

Verification performed:
- Pending final Tahoe rebuild and smoke launch after this entry.

Risks / follow-up:
- Confirm the duplicate-instance dialog uses acceptable wording on Lion's older
  Qt stack.

### 26.6.4ce - 2026-06-09 - Traffic graph protocol and Quick Clone breakdown

Big picture:
- Metrics > Traffic now separates total, TCP, UDP, and Quick Clone copy
  telemetry. Quick Clone is a UDP subset, not a fourth transport added to the
  total.
- The Status page Quick Clone row now includes measured live and average copy
  rates so users can see whether Quick Clone is actually moving data.

Porting priority:
- Lion Intel: required for UI parity. Port the same C++ counters, QML graph
  series, footer grid, status row text, and CSV columns.
- Catalina UTM: required before parity testing the Metrics page.
- Windows: required before the next Windows parity build.
- Server: not required; this is Nu GUI telemetry. Server responder code only
  needs the underlying Fast Sync/Quick Clone wire behavior.

Changed behavior:
- `trafficSamples` now contains `received`, `sent`, `tcpReceived`, `tcpSent`,
  `udpReceived`, `udpSent`, `quickCloneReceived`, and `quickCloneSent`.
- Graph style contract:
  solid lines are total traffic, dashed lines are TCP, dotted lines are UDP,
  and dot-dash lines are Quick Clone.
- Footer contract:
  rows are `Total rec'd:` and `Total sent:`; columns are TCP, UDP, Quick
  Clone, and Total traffic.
- Quick Clone status now appends live total/in/out rate, observed average,
  received/sent totals, and packet counts.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.h`: added Quick Clone traffic properties,
  per-session counters, and in-flight transfer `clone_mode`.
- `src/qt/nu/app/NuRpcService.cpp`: classifies clone-mode UDP datagrams,
  computes TCP/UDP/Quick Clone sample rates, extends CSV export, and appends
  Quick Clone rate telemetry to the Metrics status row.
- `src/qt/nu/qml/Components/NuTimelineGraph.qml`: draws protocol breakouts
  and updates legend/hover text.
- `src/qt/nu/qml/Views/NodeView.qml`: replaces the old total-only footer with
  a tight protocol grid.

Compatibility notes:
- Older peers that do not echo `clone_mode` on served chunks may still show
  their bytes in UDP/total without the Quick Clone subset. Tahoe/Lion parity
  builds should both carry the `clone_mode` chunk header.
- Do not double-count Quick Clone in total traffic. Total remains TCP plus UDP.

Build/package notes:
- Tahoe source version was advanced to `26.6.4ce`.

Verification performed:
- `git diff --check`: clean before build.
- `make -j6 src/defcoind src/defcoin-cli src/defcoin-tx src/defcoin-wallet`:
  succeeded with existing AppleClang/Boost/BDB warnings.
- `cmake --build build/nu-qml-arm64-26.6.4ce --target DefcoinCoreNu -j 6`:
  succeeded after adding the missing async lambda capture for `clone_request`.

Risks / follow-up:
- Smoke-test the rendered Metrics > Traffic legend/footer on Tahoe and Lion
  after packaging. The footer is intentionally denser than before.

### 26.6.4cc - 2026-06-09 - Fast Sync UDP all-modes scheduler fix

Big picture:
- Current Tahoe/Lion testing proved UDP transport could work when Core TCP
  block copy was disabled, but all-modes sync was still mostly losing because
  the GUI asked Core to reserve the exact next local height for LAN peers.
- With Core TCP enabled, Core usually already had that height queued or stored
  before UDP could win, producing repeated `block-already-have-data` deferrals.
- The long-term rule is now explicit: UDP Fast Sync is only a transport choice.
  When normal Core TCP sync is active, UDP must use Core's own `reserve-next`
  scheduling so Core chooses a safe unscheduled block.

Porting priority:
- Lion Intel: required and already applied to the physical iMac source for
  `26.6.4cc-Lion-alpha`.
- Catalina UTM: required before any Catalina Fast Sync test.
- Windows: required before the next Windows Fast Sync build.
- Server: required for requester behavior only if the server is also being used
  as a Fast Sync requester. Responder-only serving can keep existing serve path,
  but version parity should still receive the backend reservation scan.

Changed behavior:
- Normal all-modes sync (`Core TCP` enabled, `Fast Sync UDP` enabled) now calls
  `reservefastsyncblock reserve-next <nodeid>` even for LAN/private peers.
- Explicit-height LAN reservations remain for UDP-only benchmarking and
  Core-TCP-disabled debug launches.
- The backend `reserve-next` RPC asks Core for a wider candidate set and filters
  out blocks already active, already stored, or already in flight before
  returning a UDP reservation.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.cpp::requestLanFastSyncBlock()`: changed
  `direct_lan_reservation` to depend only on `core_tcp_blocks_disabled`.
- `src/net_processing.cpp::ReserveNextFastSyncBlockInFlight()`: changed the
  non-explicit path from a single candidate to a bounded scan of
  `MAX_BLOCKS_IN_TRANSIT_PER_PEER + MAX_FAST_SYNC_EXTRA_BLOCKS_IN_TRANSIT_PER_PEER + 32`
  and a one-block filtered result.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: bumped Tahoe label
  to `26.6.4cc`.
- Lion equivalent changes were applied in
  `src/qt/nu/legacy-osx107/main.cpp`, `src/net_processing.cpp`,
  `src/clientversion.h`, `src/qt/nu/legacy-osx107/DefcoinCoreNuLegacy.pro`,
  and `src/qt/nu/legacy-osx107/Info.plist`.

Compatibility notes:
- Do not reintroduce the old `coreTcpBlocksDisabled || LAN/private` condition
  for all-modes sync. That condition is correct for UDP-only tests, but it
  races Core TCP in normal sync.
- Seeing occasional `no-downloadable-block-in-window` is expected when Core TCP
  is already filling the best nearby blocks. It is no longer proof that UDP is
  blocked; look for current-run `NU_UDP_FASTSYNC_SERVE` and
  `UDP fast sync accepted block` evidence.

Build/package notes:
- Tahoe staged app:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.4cc-20260609/apple-silicon/Defcoin Core Nu.app`.
- Tahoe staged DMG:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.4cc-20260609/apple-silicon/Defcoin-Core-Nu-v26.6.4cc-macOS-AppleSilicon.dmg`.
- Lion staged app:
  `/Users/david/_Distribution_Versions/Defcoin Core Nu/Nu-26.6.4cc-Lion-alpha-20260609-iMac/stage/Defcoin Core Nu.app`.

Verification performed:
- Tahoe staged app reports frontend `26.6.4cc`, bundled backend
  `Defcoin Core Nu version v26.6.4cc`, deep codesign verifies, and `hdiutil
  verify` reports the DMG checksum is valid.
- Lion staged app reports frontend `26.6.4cc-Lion-alpha` and bundled backend
  `v26.6.4cc-Lion-alpha-40e4ee1-dirty`.
- Fresh Lion public chain reset with all three modes enabled and Quick Clone
  declined: Lion accepted current-run UDP Fast Sync blocks from Tahoe while
  normal Core TCP sync remained active. Observed examples include UDP-accepted
  blocks `3005`, `3006`, `3015`, `16962`, `17864`, and `19368`.
- Tahoe current-run log showed matching `NU_UDP_FASTSYNC_SERVE` rows to
  `192.168.0.189` and `[2603:808c:f40:200::48b]`.
- Persistence check: Lion stopped cleanly at block `21559`, relaunched without
  deleting chain data, and resumed at block `22632`, then continued to block
  `27024` with additional UDP accepts.

Risks / follow-up:
- In all-modes sync UDP is currently supplemental rather than dominant; Core
  TCP still advances most blocks. Future optimization should tune the
  candidate scan/window only after measuring CPU cost and avoiding duplicate
  reservations.
- The old iMac produced a short-lived child-process crash report at
  `2026-06-09 20:35:00 -0500`, but the main frontend/backend continued and
  the safe-stop/relaunch persistence check passed. Inspect if repeated.

### 26.6.4ca - 2026-06-09 - Metrics details parity and compact UDP status

Big picture:
- Tahoe and Lion should present the same Metrics/Peers affordances. The user
  noticed Lion lacked the compact Details switches that Tahoe already had, which
  made the Lion build look stale and raised valid concern that backend parity
  might also be stale.
- The simple Status page should answer the first-order operator question:
  "Is syncing working, and is UDP contributing?" without forcing the user to
  read packet-level debug counters.
- Keep packet/probe/checksum details available, but only behind Details.

Porting priority:
- Lion Intel: required. Port the compact `Details` switches for Status and
  Peers, the simple/detail row split, the concise UDP summary, and the
  `dns-sd`/`awk` probe cleanup.
- Catalina UTM: required for UI parity if it is using the Qt 5 legacy UI.
- Windows: port the concise UDP summary/detail split if it uses the QML service
  rows; verify the `Details` switch already exists in QML.
- Server: no UI work. Backend version identity only if server release labels
  are being aligned.

Changed behavior:
- `Fast Sync (UDP)` in simple Status now reports UDP block share, average data
  rate, recent block rate or warmup progress, peers successful/attempted/failed,
  sent/received bytes, and failure count.
- Detailed UDP diagnostics moved into `Fast Sync (UDP) counters`, which is only
  shown when Details is enabled.
- Lion `Metrics > Status` and `Metrics > Peers` now use a smaller `Details`
  toggle instead of the older Simple/Detailed combo-box presentation.
- Lion Bonjour workstation probes now kill their helper process tree after
  completion/timeout to avoid leaking `dns-sd`, `awk`, and shell processes.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.cpp` and `.h`: Tahoe QML service split
  `fastSyncUdpSummary()` into concise simple text plus
  `fastSyncUdpDetailSummary()` for Details-only counters.
- `src/clientversion.h`: Tahoe backend public release identity updated to
  `26.6.4ca` so staged frontend/backend labels agree.
- `src/qt/nu/tools/nu_lion_remote_safe_stop.sh`: default physical-Lion app path
  now points to `Nu-26.6.4ca-Lion-alpha-20260609-iMac`, with `NU_LION_APP`
  override preserved.
- Lion-only files changed on the physical iMac source tree:
  `src/qt/nu/legacy-osx107/main.cpp`,
  `src/qt/nu/legacy-osx107/DefcoinCoreNuLegacy.pro`, and
  `src/qt/nu/legacy-osx107/Info.plist`.
- Lion backend release identity patched in the full backend workspace under
  `/Users/david/_Development/Defcoin Core Nu Lion/Build_Workspaces/.../src`.

Compatibility notes:
- Do not overwrite Lion backend sources wholesale with Tahoe files. Lion has
  portability-specific dirty changes. Compare and port the narrow Fast Sync
  backend logic only.
- On the old Automake Lion backend tree, avoid
  `make src/defcoind src/defcoin-cli`: it can run two recursive makes that race
  on shared objects. Use `make -C src -j2 defcoind defcoin-cli`.

Build/package notes:
- Tahoe Apple Silicon raw CMake bundle does not contain QML resources until
  `stage_macos_distribution.sh` runs. Direct raw-app smoke tests will fail with
  `Main.qml: No such file or directory`; test the staged app instead.
- Tahoe staged app:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.4ca-20260609/apple-silicon/Defcoin Core Nu.app`.
- Tahoe staged DMG:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.4ca-20260609/apple-silicon/Defcoin-Core-Nu-v26.6.4ca-macOS-AppleSilicon.dmg`.

Verification performed:
- Tahoe staged app reports frontend `26.6.4ca`, backend
  `Defcoin Core Nu version v26.6.4ca`, QML `Main.qml` is present, deep code
  signing verifies, staged app smoke exits 0, and `hdiutil verify` reports the
  DMG checksum is valid.
- Lion frontend build linked warning-free after removing the stale
  `m_peerViewMode` member.
- Lion staged app now reports frontend `26.6.4ca-Lion-alpha`, backend
  `v26.6.4ca-Lion-alpha-433385a-dirty`, and CLI
  `v26.6.4ca-Lion-alpha-433385a-dirty`. The app signs cleanly, and the replaced
  backend binaries no longer contain `/opt/local` or `/usr/local` install names.

Risks / follow-up:
- Backend rebuilds on Tahoe still emit existing Boost/thread-safety and
  `-fstack-clash-protection` clang warnings. These are not from the new status
  UI changes, but they remain cleanup candidates.
- Confirm live Lion UI visually after launching through the crash/Allow gates;
  do not interpret UDP tests unless Tahoe Local Network Allow has been clicked
  for that exact build.

### 26.6.4bz - 2026-06-09 - Lion crash gate and clean UDP-only evidence

Big picture:
- Physical Lion testing must treat any crash dialog as a hard blocker before
  interpreting Fast Sync results. A visible or hidden Problem Reporter can make
  the GUI look alive while a prior child helper crash is still on screen.
- The live Lion crash reports observed in this pass were old child-process
  reports from 16:54-16:57 CDT. The current Lion frontend/backend remained
  running after the QProcess/nmap stability patch and no new ReportCrash process
  appeared during the gated UDP-only run.
- With Tahoe's Local Network Allow gate rechecked and Lion's crash gate clean,
  Lion accepted sequential UDP Fast Sync blocks from Tahoe. The test is valid
  for "UDP can communicate and Core accepts transported blocks", but not yet for
  throughput because Lion was still building headers and saturating CPU.
- A separate persistence fault was traced to test/build automation interrupting
  `defcoind` during shutdown. On the Lion iMac, a clean backend stop can take
  30-120 seconds while flushing chainstate. If the process is killed before
  `Shutdown: done`, the next launch may load an empty block index and appear to
  restart from genesis even though UDP block transfer had been working.

Porting priority:
- Lion Intel: required operational rule. Run the crash gate before every Lion
  launch/test interpretation and clear crash reporters before checking for LAN
  permission or UDP status.
- Catalina UTM: recommended if it has remote GUI/crash dialogs during tests.
- Windows: no direct script port, but preserve the same launch discipline:
  crash dialogs first, then network permission, then sync conclusions.
- Server: no change.

Changed behavior:
- Added a repeatable local test helper,
  `src/qt/nu/tools/nu_lion_remote_health_gate.sh`, which SSHes to the physical
  Lion iMac, records Nu frontend/backend/crash-reporter process state, records
  the newest `DefcoinCoreNu*.crash` timestamp, optionally captures a screenshot,
  clears crash reporters, and appends an audit row to
  `local-dev-notes/Defcoin Core Nu/nu_lion_remote_crash_gate_log.csv`.
- Hardened the Tahoe `nu_test_launch_gate.sh --kill-existing` path so it first
  asks the app to quit and requests `defcoin-cli stop`, then waits up to four
  minutes for `defcoind` to exit cleanly before any forced termination. This
  prevents the launch gate from invalidating block/header persistence tests.
- Added `src/qt/nu/tools/nu_lion_remote_safe_stop.sh` for the physical Lion
  iMac. Use it before Lion rebuilds/tests instead of ad hoc `kill`, `pkill`, or
  `killall` commands.
- This is test tooling only. It does not alter wallet, blockchain, firewall,
  TCC, or sync data.

Changed files and important details:
- `src/qt/nu/tools/nu_lion_remote_health_gate.sh`: new physical Lion crash and
  process audit helper. Defaults to `david@192.168.0.189` with
  `$HOME/.ssh/id_rsa_defcoin_intel_mac` and legacy ssh-rsa compatibility.
- `src/qt/nu/tools/nu_test_launch_gate.sh`: `--kill-existing` now means
  "cleanly stop the prior app/backend and wait for chainstate flush" rather than
  immediate process killing. This is important for all UDP/Quick Clone tests.
- `src/qt/nu/tools/nu_lion_remote_safe_stop.sh`: SSH helper that clears crash
  reporters, asks the Lion app/backend to stop, runs `defcoin-cli stop` against
  discovered Lion RPC configs, waits for `defcoind` to disappear, and records
  the result in the Lion gate CSV.

Verification performed:
- `nu_lion_remote_health_gate.sh --screenshot /tmp/lion-health-gate.png`
  returned `status=clean`; newest crash stayed
  `2026-06-09 16:57:11 -0500`; current Lion frontend PID `74599` and backend
  PID `74603` were running.
- Tahoe `nu_test_launch_gate.sh --recheck` for current `26.6.4bz` PID returned
  `status=no_prompt_visible`, so Tahoe Local Network permission was not blocking
  the current UDP run.
- Lion accepted UDP Fast Sync blocks after the reset marker:
  at least blocks 1-330 were accepted from Tahoe, with two recovered timeouts
  and zero reject/error events in the sampled period.
- Lion log comparison showed a clean shutdown at 20:04 took about 36 seconds
  from `Shutdown: In progress...` to `Shutdown: done`. Later test/build stops
  at 21:59 and 22:37 had `Shutdown: In progress...` and no matching
  `Shutdown: done`, after which the next launch loaded
  `CBlockFileInfo(blocks=0, size=0...)`. That makes hard-killing the backend a
  confirmed test contaminant.

Risks / follow-up:
- Throughput is still not representative while Lion is rebuilding headers
  (`Synchronizing blockheaders` was only about 45.77% during the sample) and CPU
  was fully saturated. For benchmark numbers, either let headers finish first or
  use a chain-reset method that preserves a valid header index.
- Do not delete or reset chain data to explain a "starts from zero" symptom
  until the previous stop has been proven to reach `Shutdown: done`.

### 26.6.4bz - 2026-06-09 - UDP Fast Sync timeout recovery and dual-stack peer TODO

Big picture:
- Tahoe `26.6.4by` was observed launched in the LAN-only UDP benchmark mode
  (`--debug-disable-core-tcp-sync --debug-disable-quick-clone
  --debug-fast-sync-lan-only`). That mode is valid for receiver benchmarking
  but invalid for a source node that is also expected to finish catching up to
  the public chain tip.
- Physical Lion reached block 458 over LAN UDP, then stopped after Tahoe served
  blocks 459-461. The receiver had active UDP transfers that did not recover
  quickly enough after chunks were lost or stranded by peer id churn.
- This build makes timed-out UDP block transfers actively mark that host as
  needing reprobe/reselection, releases the Core reservation, logs the timeout,
  and immediately reschedules the Fast Sync tick.
- Added a future TODO to collapse IPv4+IPv6 entries for the same trusted LAN
  workstation into one logical UI/source while preserving both transport lanes.

Porting priority:
- Lion Intel: required. Port the `NuRpcService.cpp` timeout/retry changes before
  retesting the block-458 stall.
- Catalina UTM: required if it uses the same QML/Qt Fast Sync frontend.
- Windows: required before Windows LAN Fast Sync testing.
- Server: no receiver-side change is required unless the server runs requester
  logic; serving-only Fast Sync does not need the UI timeout scheduler.

Changed behavior:
- Expired UDP block requests now call `recordUdpFastSyncPeerMiss(...)`, release
  their Core reservation, emit a `NU_UDP_FASTSYNC_TIMEOUT` debug line, and queue
  another scheduler tick.
- Each sent UDP block request now schedules a guarded post-timeout scheduler tick
  so a quiet event loop does not leave stale transfers parked forever.
- Unknown UDP chunks are logged as diagnostics instead of disappearing silently.
- Source-node testing should launch Tahoe normally when it must catch up to the
  public chain tip; reserve LAN-only/TCP-off flags for receiver benchmarks.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.cpp`: receiver timeout recovery, post-request
  timeout tick, and unknown-chunk diagnostics.
- `src/qt/nu/docs/fast-sync-protocol.md`: future dual-stack logical-peer cleanup
  item for IPv4+IPv6 LAN duplicate rows.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: Tahoe label moves to
  `26.6.4bz`; Lion should use `26.6.4bz-Lion-alpha`.
- `src/qt/nu/docs/release-notes-26.6.4bz.md`: user/developer note.

Compatibility notes:
- This does not change the Fast Sync wire format.
- This does not collapse IPv4+IPv6 peers yet; it only records the future design
  item so Core's reservation queue remains the current correctness boundary.

Verification performed:
- Pending rebuild/relaunch. The triggering evidence was Tahoe serving
  459-461 while Lion remained at 458 with no staged/accepted follow-up.

Risks / follow-up:
- If Tahoe is launched with `--debug-disable-core-tcp-sync` as a source node, it
  can still stop near the public tip because it has no higher LAN source.
- If Lion still stalls after this fix, inspect `NU_UDP_FASTSYNC_TIMEOUT`,
  `NU_UDP_FASTSYNC_REQUEST`, `NU_UDP_FASTSYNC_STAGED`, and peer disconnect lines
  together before changing the protocol.

### 26.6.4by - 2026-06-09 - LAN UDP benchmark log and Lion selector parity

Big picture:
- LAN UDP Fast Sync on the physical Lion iMac is now confirmed to request,
  receive, stage, and accept blocks from the Tahoe Mac mini with Core TCP block
  copy and Quick Clone disabled.
- The previous Lion pause after block 49 was caused by Lion still using the
  public UDP keepalive cadence for verified LAN peers. Tahoe already used the
  short LAN request interval.
- A staged-block debug log use-after-remove corrupted the `chunks=` field on
  both Tahoe and Lion. It did not corrupt block transfer, but it made benchmark
  logs untrustworthy.

Porting priority:
- Lion Intel: required. Port the verified-LAN request interval and the
  staged-log transfer-field capture before removal.
- Catalina UTM: required if it shares the legacy Lion frontend path.
- Windows: inspect for the same staged-log remove/read ordering if the Windows
  Fast Sync frontend code differs from Tahoe QML.
- Server: no change for this UI log fix; server Fast Sync serving remains
  backend/protocol code.

Changed behavior:
- Verified LAN UDP peers use `LAN_FAST_SYNC_MIN_REQUEST_INTERVAL_MS`.
- Staged-block logs read `expected_chunks` / `expectedChunks` before removing
  the transfer from the active-transfer map.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.cpp`: captures `expected_chunks` before
  `m_lan_fast_sync_transfers_by_id.remove(request_id)`.
- Lion `src/qt/nu/legacy-osx107/main.cpp`: mirrors the staged-log fix and uses
  the short interval for verified LAN UDP peers.
- Version labels moved to `26.6.4by` / `26.6.4by-Lion-alpha`.

Verification performed:
- Tahoe launched with
  `--debug-disable-core-tcp-sync --debug-disable-quick-clone --debug-fast-sync-lan-only`;
  Local Network prompt clicker returned `not_found` and Tahoe had UDP
  `*:10334` open.
- Physical Lion iMac chain folders `blocks`, `chainstate`, and `indexes` were
  cleared; wallet files were preserved.
- Lion `26.6.4bx` pre-log-fix run accepted blocks 1-137 over UDP with 0
  failures and 0 duplicates before this final log fix.

Risks / follow-up:
- Full-chain elapsed benchmark was not completed in this verification pass.
- Early-chain payload bytes/sec is not meaningful because those blocks are tiny;
  use blocks/sec and later larger-block ranges for protocol comparison.

### 26.6.4bu - 2026-06-09 - UDP Fast Sync reservation window

Big picture:
- Fixes the first LAN UDP-only benchmark bottleneck. UDP block bodies were
  proven to transfer, but the reservation helper kept asking only for active
  height + 1 during clean bootstrap/header fallback. That prevented Nu's
  out-of-order UDP cache from filling and made the benchmark look like a
  one-block-at-a-time path.

Porting priority:
- Lion Intel: required. Port the Core reservation window change and the larger
  legacy Fast Sync cache constants before retesting the Lion chain rebuild.
- Catalina UTM and Windows: required before publishing matching Fast Sync
  builds.
- Server: required for server-side Fast Sync parity, but Quick Clone/DCOL is
  still not a server feature.

Changed behavior:
- `reservefastsyncblock reserve-next` now scans a bounded header window and
  reserves the first missing, not-already-in-flight block in bootstrap fallback
  mode instead of only trying active height + 1.
- UDP Fast Sync receiver cache grows to 16 active blocks and 48 ready blocks.
- Quick Clone/Core reservation status backoff drops from 30 seconds to 5
  seconds so status and retry behavior no longer appears stuck during debug
  runs.
- Visible version label moves to `26.6.4bu`.

Changed files and important details:
- `src/net_processing.cpp`: `ReserveNextFastSyncBlockInFlight()` now skips
  already-present/in-flight blocks while scanning ahead; extra UDP transport
  slots increase from 1 to 4.
- `src/qt/nu/app/NuRpcService.cpp`: receiver-side in-flight/ready cache limits
  increased; reservation retry status backoff shortened.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: visible release
  label moves to `26.6.4bu`.
- `src/qt/nu/docs/release-notes-26.6.4bu.md`: release note.

Compatibility notes:
- No consensus changes and no packet format changes.
- This still uses Core reservation and `submitblock`; UDP remains transport
  only.
- Older peers that do not advertise `NODE_DEFCOIN_FASTSYNC` are not selected
  for UDP Fast Sync.

Verification performed:
- Pending: rebuild Tahoe and Lion, clear only Lion public chain folders, launch
  both with `--debug-disable-core-tcp-sync --debug-disable-quick-clone
  --debug-fast-sync-lan-only`, click Tahoe Local Network Allow if prompted, then
  verify higher UDP request concurrency and accepted block rate.

Risks / follow-up:
- If Core validation on Lion is the bottleneck, accepted block rate may still
  remain low despite faster UDP staging. In that case compare staged/sec versus
  accepted/sec before tuning packet size.

### 26.6.4bt - 2026-06-09 - UDP Fast Sync proof markers

Big picture:
- Adds explicit UDP Fast Sync transport markers to `debug.log` so LAN-only
  benchmark runs can prove request, serving, staging, submission, and accepted
  block flow. This was added because Lion block height advanced during the
  UDP-only test, but existing logs only showed probe acknowledgements and did
  not uniquely prove block-body transport source.

Porting priority:
- Lion Intel: required for the current LAN UDP-only benchmark. Port the same
  marker strings in the legacy Fast Sync request/serve/stage/submit paths.
- Catalina UTM and Windows: recommended for benchmark parity.
- Server: optional. Server Fast Sync serving can benefit from
  `NU_UDP_FASTSYNC_SERVE`, but no protocol change is required.

Changed behavior:
- Adds these unique grep markers:
  `NU_UDP_FASTSYNC_REQUEST`, `NU_UDP_FASTSYNC_SERVE`,
  `NU_UDP_FASTSYNC_STAGED`, `NU_UDP_FASTSYNC_ACCEPTED`,
  `NU_UDP_FASTSYNC_SUBMITTED`, and `NU_UDP_FASTSYNC_DUPLICATE`.
- Intended isolated benchmark launch remains:
  `--debug-disable-core-tcp-sync --debug-disable-quick-clone --debug-fast-sync-lan-only`.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.cpp`: logs request-block sends, source chunk
  serving, receiver staging, accepted transport counts, inconclusive submits,
  and duplicate/already-counted results.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: visible release
  label moves to `26.6.4bt`.
- `src/qt/nu/docs/release-notes-26.6.4bt.md`: release note.

Compatibility notes:
- No packet format, service-bit, consensus, or RPC contract changes.
- Extra log volume is expected during UDP-only benchmark runs.

Verification performed:
- Pending: rebuild Tahoe and Lion, clear only Lion public chain folders, launch
  both with the isolated benchmark flags, accept Tahoe Local Network prompt if
  shown, then grep Lion/Tahoe logs for `NU_UDP_FASTSYNC_*` and
  `NU_SYNC_BENCHMARK_COMPLETE`.

Risks / follow-up:
- If the log volume is too high for normal releases, gate the per-block markers
  behind a debug flag after the LAN benchmark is complete.

### 26.6.4bs - 2026-06-09 - LAN-only UDP Fast Sync benchmark switch

Big picture:
- Adds a controlled benchmark mode for testing Lion sync from LAN UDP Fast Sync
  only. The mode keeps Core peer/header negotiation alive, disables Core TCP
  block-body fetches when paired with the existing switch, disables Quick Clone
  when paired with the existing switch, and restricts frontend UDP Fast Sync
  targets to private/local LAN peers instead of public/server candidates.
- Adds a session sync benchmark metric and writes unique start/complete lines
  into `debug.log`, including `NU_SYNC_BENCHMARK_COMPLETE`, elapsed time,
  block range, UDP/Core block counts, byte totals, failures, and UDP source
  counts.

Porting priority:
- Lion Intel: required for the requested LAN UDP-only benchmark. Port the flag
  handling, `m_debug_fast_sync_lan_only`, target-filtering logic, and sync
  benchmark fields/functions.
- Catalina UTM and Windows: useful for parity if those builds need the same
  benchmark controls.
- Server: not required. This is a receiver/test harness and UI metric change,
  not a Fast Sync packet-format or service-bit change.

Changed behavior:
- New launch flag: `--debug-fast-sync-lan-only`.
- Intended isolated Fast Sync benchmark launch flags:
  `--debug-disable-core-tcp-sync --debug-disable-quick-clone --debug-fast-sync-lan-only`.
- When the LAN-only flag is active, `selectUdpFastSyncTargetHost()` rejects
  public/server UDP candidates even if they advertise `NODE_DEFCOIN_FASTSYNC`.
- Metrics > Status now includes `Sync benchmark`.
- Backend `debug.log` gets:
  `NU_SYNC_BENCHMARK_START ...` and
  `NU_SYNC_BENCHMARK_COMPLETE ...`.

Changed files and important details:
- `src/qt/nu/app/main.cpp`: clears and sets
  `DEFCOIN_NU_DEBUG_FAST_SYNC_LAN_ONLY` from the new launch flag.
- `src/qt/nu/app/NuRpcService.h/.cpp`: adds the LAN-only debug state, filters
  Fast Sync targets, records sync benchmark timing, and surfaces the benchmark
  metric.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: visible release
  label moves to `26.6.4bs`.
- `src/qt/nu/docs/release-notes-26.6.4bs.md`: user/developer release note.

Compatibility notes:
- Normal launches are unchanged. The LAN-only behavior exists only when the new
  debug flag is present.
- This mode is specifically for Fast Sync validation-preserving transport
  testing. It is not Quick Clone/DCOL and does not bypass Core validation.

Verification performed:
- Pending in this Tahoe thread: rebuild Tahoe, port Lion, clear only Lion chain
  folders, launch Tahoe with Local Network permission allowed, launch Lion with
  the isolated flags, and grep Lion `debug.log` for
  `NU_SYNC_BENCHMARK_COMPLETE`.

Risks / follow-up:
- If Lion spends substantial time rebuilding headers before blocks, the
  benchmark should be interpreted as full wallet sync elapsed time, not pure
  UDP block-transfer throughput. Use Fast Sync UDP metrics for transport rate.

### 26.6.4br - 2026-06-09 - Header sync ETA uses block-rate clock text

Big picture:
- The mast/header needed a clearer completion estimate while syncing. It now
  shows `ETA HH:MM:SS`, derived first from a smoothed accepted-block rate and
  only falling back to Core verification-progress deltas while the block-rate
  sample is still warming.
- This is a UI/status reporting change only. It does not alter Core block
  reservation, validation, Fast Sync, or Quick Clone behavior.

Porting priority:
- Lion Intel: required for UI parity if the current Lion build uses the shared
  `NuRpcService` status path. If Lion has a legacy status updater, port the same
  state variables and `HH:MM:SS` formatter there.
- Catalina UTM and Windows: required for UI parity if built from this shared
  QML app source.
- Server: not required. No Fast Sync protocol/server behavior changed.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.cpp`: `formatSyncEtaSeconds()` now returns
  fixed-width `HH:MM:SS`; `refreshNode()` maintains
  `m_sync_average_blocks_per_second` as a 75/25 EWMA of block-height
  advancement and labels the mast string with `ETA`.
- `src/qt/nu/app/NuRpcService.h`: adds
  `m_sync_average_blocks_per_second`.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: visible release
  label moves to `26.6.4br`.
- `src/qt/nu/docs/release-notes-26.6.4br.md`: user/developer release note.

Compatibility notes:
- ETA still shows `calculating` until either an accepted-block-rate sample or a
  verification-progress delta is available.
- When up to date, the ETA resets to `00:00:00`.

Verification performed:
- `git diff --check` passed.
- `cmake -S src/qt/nu/app -B build/nu-qml-arm64-26.6.4br -G Ninja
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
  -DQt6_DIR=/opt/homebrew/lib/cmake/Qt6
  -DDEFCOIN_NU_RELEASE_NAME=26.6.4br` configured successfully.
- `cmake --build build/nu-qml-arm64-26.6.4br --target DefcoinCoreNu -j4`
  and `DefcoinCoreNuResources` passed.
- Bundled `defcoind`, `defcoin-cli`, `defcoin-tx`, and `defcoin-wallet`
  reported `v26.6.4br`.

Risks / follow-up:
- None for protocol behavior. Package builds should still use a fresh build
  directory per version to avoid stale CMake cache release labels.

### 26.6.4bq - 2026-06-09 - Fast Sync direct reservation JSON type fix

Big picture:
- Fast Sync-only testing on Lion with Core TCP block bodies disabled reached
  Tahoe over UDP, but direct reservation failed with `JSON value is not a string
  as expected`. The frontend was sending a JSON number for
  `reservefastsyncblock reserve`'s optional `height_or_hash` argument.

Porting priority:
- Lion Intel: required. In `src/qt/nu/legacy-osx107/main.cpp`, direct
  LAN/Fast Sync reservation must pass `QString::number(wantedHeight)`.
- Catalina UTM and Windows: required if they carry the same frontend
  direct-reservation path.
- Server: backend tolerance only; serving does not depend on this UI path.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.cpp`: direct reserve now sends string height.
- `src/rpc/net.cpp`: `reservefastsyncblock` reads `height_or_hash` with
  `getValStr()` so numeric JSON values do not throw before validation.
- `src/qt/nu/docs/release-notes-26.6.4bq.md`: added release/build note.

Verification:
- Re-test Lion with `--debug-disable-core-tcp-sync --debug-disable-quick-clone`;
  accepted UDP Fast Sync blocks must appear instead of the JSON type error.

### 26.6.4bm - 2026-06-09 - Fast Sync block-source accounting and fair UDP test metrics

Big picture:
- Earlier Fast Sync status text mixed several different meanings of "UDP used":
  UDP probe success, serving chunks to another node, and accepting a UDP block
  through Core. That made the UDP-vs-TCP rate comparison hard to trust.
- This build separates receiver-side UDP block source accounting from generic
  transport history and stops isolated UDP tests from counting generic chain
  advancement as TCP/Core block success when Core TCP block-body sync is
  disabled.
- During Lion parity work, stale `dns-sd -B _smb._tcp` workstation-discovery
  helper processes were found consuming Lion process slots. Lion must use the
  bounded Bonjour browse snapshot already present in Tahoe, not a live pipe.

Porting priority:
- Lion Intel: required. Port the new source-accounting sets and status text to
  `src/qt/nu/legacy-osx107/main.cpp`; keep Qt 5.5-compatible explicit set
  removal loops. Also port the bounded Bonjour SMB browse script if missing.
- Catalina UTM: required if Fast Sync metrics are present.
- Windows: required if Fast Sync metrics are present.
- Server: requester-side server builds should take the counter split if they
  display or log Fast Sync requester metrics. Responder-only protocol behavior
  is unchanged.

Changed behavior:
- Tahoe visible version becomes `26.6.4bm`.
- `Sync overview` now reports `UDP sources N/M ok, X failed, served Y`.
- `Fast Sync (UDP)` now reports accepted UDP block sources, attempted sources,
  fully failed sources, served peers, and current datagram/chunk probe size.
- During debug launches with Core TCP block-body sync disabled,
  `recordCoreSyncPathProgress()` is not called for generic chain advancement.
  That prevents an isolated UDP test from crediting TCP/Core for local or
  non-UDP advancement.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.h`: added
  `m_udp_fast_sync_block_attempted_peer_hosts`,
  `m_udp_fast_sync_block_success_peer_hosts`, and
  `m_udp_fast_sync_block_served_peer_hosts`.
- `src/qt/nu/app/NuRpcService.cpp`: updated success, timeout, checksum, buffer,
  submit-failure, Quick Clone offline, Retest FastSync, and transport-clear
  paths to maintain the new sets. The Peers table still uses the broader
  `m_udp_fast_sync_used_peer_hosts` history so `TCP+UDP` remains available.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: version moved to
  `26.6.4bm`.
- `src/qt/nu/docs/release-notes-26.6.4bm.md`: user/developer release note.

Compatibility notes:
- No wire protocol, service bit, consensus, wallet, or storage format change.
- This is a metrics/status correction and test-isolation fix.

Build/package notes:
- Rebuild backend binaries after changing `src/clientversion.h`; otherwise the
  app and bundled daemon will report different suffixes.
- Tahoe build should use a fresh or explicitly configured Qt 6 arm64 build dir
  with the bundled Qt path, as in prior 26.6.4bl notes.

Verification performed:
- Tahoe QML app target compiled cleanly through `DefcoinCoreNuResources` before
  staging.

Risks / follow-up:
- The next test must launch the newest Tahoe bundle only after closing the old
  Nu process, then click the Tahoe Local Network Allow prompt if macOS shows it.
- Delete only Lion `blocks`, `chainstate`, and `indexes` for clean-sync tests.

### 26.6.4bl - 2026-06-09 - Fast Sync failed-node accounting cleanup

Big picture:
- 26.6.4bk added LAN-first Fast Sync source selection and carried the 26.6.4bj
  node success/failure counters, but one reset path could leave a peer in the
  UDP failed-node bucket after a user retested or cleared transport
  verification.
- This build keeps the protocol unchanged and fixes the visible diagnostic
  accounting so `UDP nodes N ok/M failed` describes the current test state.

Porting priority:
- Lion Intel: required. Port the same cleanup to legacy
  `src/qt/nu/legacy-osx107/main.cpp` so Tahoe and Lion status rows match.
- Catalina UTM: required if Fast Sync metrics are present.
- Windows: required if Fast Sync metrics are present.
- Server: requester-side builds should take the cleanup; responder-only service
  behavior is unchanged.

Changed behavior:
- Tahoe visible version becomes `26.6.4bl`.
- Retest FastSync and UDP verification reset no longer leave stale entries in
  the failed-node count.
- Quick Clone offline handling continues to mark the current source as failed
  until it later succeeds or is explicitly reset.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.cpp`: `clearUdpFastSyncTransportVerification()`
  now clears `m_udp_fast_sync_block_failed_peer_hosts`; Quick Clone offline
  handling inserts into that failed-node set; `refreshPeer()` clears it during
  manual Retest FastSync.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: visible build label
  moved to `26.6.4bl`.

Verification performed:
- Tahoe backend build passed for `defcoind`, `defcoin-cli`, `defcoin-tx`,
  and `defcoin-wallet`.
- Tahoe QML app configured in a fresh `build/nu-qml-arm64-26.6.4bl`
  directory to avoid stale Homebrew Qt cache paths, built
  `DefcoinCoreNuResources`, staged, code-signed, and DMG-verified.
- Staged app reports `CFBundleShortVersionString=26.6.4bl`; bundled backend
  reports `Defcoin Core Nu version v26.6.4bl`.
- Lion legacy source received the equivalent failed-node reset cleanup and is
  rebuilding as `26.6.4bl-Lion-alpha`.

Risks / follow-up:
- Launch Tahoe and Lion current builds together and use the macOS LAN-Allow
  clicker on Tahoe before treating UDP results as valid.

### 26.6.4bk - 2026-06-09 - Prefer LAN Fast Sync sources when available

Big picture:
- The Lion isolation run proved UDP Fast Sync can accept blocks through Core
  validation, but the selector could still choose public Fast Sync peers over a
  verified wired-LAN Tahoe peer because "previously used" public peers scored
  higher than "private/local" peers. Public UDP timeouts then made LAN UDP look
  slower than it really was.
- This build keeps Fast Sync as a transport-only path through Core reservation,
  but source selection now treats eligible private/local peers as the first
  choice pool. Public UDP peers compete only when no eligible LAN/private peer
  can provide the next block.

Porting priority:
- Lion Intel: required. This exact selector change must be ported before using
  Lion throughput results to judge LAN UDP performance.
- Catalina/Windows: required if those builds expose Fast Sync.
- Server: no change needed for responder-only service, but requester-side server
  builds should take the same source-selection rule.

Changed behavior:
- Tahoe visible version becomes `26.6.4bk`.
- If at least one eligible private/local Fast Sync source is ahead of the local
  chain, UDP block requests are selected only from that private/local pool.
- Public Fast Sync peers remain available as fallback when no eligible LAN
  source exists.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.cpp`: `selectUdpFastSyncTargetHost()` now first
  detects eligible LAN/private candidates, then filters the scoring pass to that
  pool when present. The existing Core reservation and block submission path is
  unchanged.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: visible build label
  moved to `26.6.4bk`.

Verification performed:
- Tahoe backend build passed for `defcoind`, `defcoin-cli`, `defcoin-tx`,
  and `defcoin-wallet`.
- Tahoe QML app configured, built, staged, code-signed, and DMG-verified as
  `26.6.4bk`.
- Staged app reports `CFBundleShortVersionString=26.6.4bk`; bundled backend
  reports `Defcoin Core Nu version v26.6.4bk`.
- Clean Tahoe launch used the LAN-Allow clicker immediately after first run of
  the new bundle; the clicker reported a successful Accessibility click.
- `getnetworkinfo` from the bundled backend reports
  `/DefcoinCoreNu:26.6.4bk/` and service name `DEFCOIN_FASTSYNC`.
- Tahoe `getpeerinfo` saw the Lion peer at `192.168.0.189` advertising
  `/DefcoinCoreNu:26.6.4bi-Lion-alpha/` and `DEFCOIN_FASTSYNC`.
- Tahoe debug log showed a UDP Fast Sync probe acknowledgement sent to the Lion
  peer after the `26.6.4bk` launch, proving the new Tahoe responder was active
  and not blocked by macOS LAN permission for this run.

Risks / follow-up:
- If UDP remains slow after Lion parity, inspect Core reservation pacing and
  block validation throughput. Raw Ethernet should not be the limiting factor
  for the tiny early-chain blocks seen in the current Lion rebuild.

### 26.6.4bj - 2026-06-09 - Fast Sync metrics and verified LAN pacing

Big picture:
- The Lion/Tahoe clean UDP test showed UDP Fast Sync accepted real blocks, but
  Metrics made UDP look worse because it compared UDP block-body transfer
  against Core header traffic from normal P2P. This build separates Core header
  bytes from Core block-body bytes and reports UDP node success/failure by real
  accepted blocks.
- Verified LAN Fast Sync peers no longer wait behind the public-probe
  keepalive interval before refilling the UDP request window. This is intended
  to make wired LAN tests reflect request/validation limits rather than an
  accidental 5-second pacing gate.

Porting priority:
- Lion Intel: required. Port the same `NuRpcService` changes so the physical
  iMac reports the same Metrics rows and uses the same verified-LAN pacing.
- Catalina UTM: required if Catalina builds include the current Fast Sync UI.
- Windows: required if Windows builds expose the same Metrics rows.
- Server: no GUI Metrics port. Review only requester-side Fast Sync helper code
  if the server build includes it; responder behavior is unchanged here.

Changed behavior:
- Tahoe visible version becomes `26.6.4bj`.
- Sync overview now reports `Block data` using Core block-body bytes plus UDP
  block bytes. Core headers are a separate field.
- Fast Sync UDP now reports `nodes N ok/M failed`; a peer is counted as OK only
  after a UDP block from that peer is accepted through Core.
- UDP checksum, timeout, buffer, and submit failures mark the sender as failed
  until a later accepted UDP block clears it.
- Verified private/local UDP peers use the LAN request interval instead of the
  5-second public probe interval when the receiver needs more blocks.
- UDP receive window increased from 4 to 8 active blocks and ready queue from
  16 to 24 blocks. The 64 MiB buffer cap remains the hard safety limit.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.cpp`: Metrics separates `headers`,
  Core block-body messages, and UDP bytes; verified LAN retry interval is
  narrowed to actual private/local addresses; UDP peer OK/fail accounting moves
  from chunk receipt to block acceptance.
- `src/qt/nu/app/NuRpcService.h`: adds Core message counters and the UDP block
  failed peer set.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: visible build label
  moved to `26.6.4bj`.

Compatibility notes:
- This does not change consensus rules or the backend reservation RPC contract.
- It intentionally does not claim public internet UDP can refill as fast as LAN
  peers; public probing stays conservative.

Build/package notes:
- Nu-only change. Do not copy or rebuild Defcoin Core Explore as part of this
  build unless the Explore thread explicitly requests it.

Verification performed:
- Tahoe backend build passed for `defcoind`, `defcoin-cli`, `defcoin-tx`,
  and `defcoin-wallet`.
- Tahoe QML app configured, built, staged, code-signed, and DMG-verified as
  `26.6.4bj`.
- Staged app reports `CFBundleShortVersionString=26.6.4bj`; bundled backend
  reports `Defcoin Core Nu version v26.6.4bj`.
- Clean Tahoe launch used the LAN-Allow clicker immediately after first run of
  the new bundle; the clicker reported a successful Accessibility click.
- `getnetworkinfo` from the bundled backend reports
  `/DefcoinCoreNu:26.6.4bj/` and service name `DEFCOIN_FASTSYNC`.
- Tahoe `getpeerinfo` saw the Lion peer at `192.168.0.189` advertising
  `/DefcoinCoreNu:26.6.4bi-Lion-alpha/` and `DEFCOIN_FASTSYNC`.
- Tahoe debug log showed a UDP Fast Sync probe acknowledgement sent to the Lion
  peer, proving Tahoe was no longer blocked by the macOS LAN permission prompt
  for this launch.

Risks / follow-up:
- If corrected UDP block-body rate is still low, inspect reservation churn,
  one-at-a-time Core submission, and UI chunk-status churn before changing
  packet sizes again.

### 26.6.4bi - 2026-06-08 - Debug environment guard and clean UDP proof

Big picture:
- Prior Fast Sync and Quick Clone tests were contaminated by hidden macOS
  launchd environment variables. The physical Lion iMac still had
  `DEFCOIN_NU_DEBUG_DISABLE_QUICK_CLONE=1`, so launches that were intended to
  test Quick Clone silently disabled it.
- This build makes command-line debug switches the normal test path and ignores
  inherited debug disable variables unless explicitly allowed. That prevents
  stale launchd/session state from changing sync behavior without being visible
  in the launch command.
- With current Tahoe and Lion builds, a reset Lion chain, and Core TCP block
  downloads disabled on Lion, UDP Fast Sync accepted blocks through Core
  validation. After clearing the stale Quick Clone disable flag, Quick Clone
  also accepted LAN blocks through Core validation.

Porting priority:
- Lion Intel: required and already ported to the physical iMac source. Add the
  same startup guard in legacy `main.cpp`.
- Catalina UTM: required if it uses the same debug launch switches.
- Windows: required if the Windows launcher or app honors
  `DEFCOIN_NU_DEBUG_DISABLE_*` variables.
- Server: no UI port. Server-side Fast Sync code is unchanged, but test scripts
  should avoid persistent debug environment variables.

Changed behavior:
- Tahoe visible version becomes `26.6.4bi`.
- Lion visible version becomes `26.6.4bi-Lion-alpha`.
- `DEFCOIN_NU_DEBUG_DISABLE_CORE_TCP_SYNC`,
  `DEFCOIN_NU_DEBUG_DISABLE_CORE_SYNC`,
  `DEFCOIN_NU_DEBUG_DISABLE_FAST_SYNC`,
  `DEFCOIN_NU_DEBUG_DISABLE_QUICK_CLONE`, and
  `DEFCOIN_NU_QUICK_CLONE_NOW` are cleared at GUI startup unless
  `--debug-use-env` or `DEFCOIN_NU_ALLOW_DEBUG_ENV=1` is present.
- Explicit command-line switches still work and are used for repeatable tests:
  `--debug-disable-core-tcp-sync`, `--debug-disable-core-sync`,
  `--debug-disable-fast-sync`, `--debug-disable-quick-clone`, and
  `--quick-clone-now`.

Changed files and important details:
- `source/src/qt/nu/app/main.cpp`: Tahoe startup now sanitizes inherited debug
  environment before translating command-line switches into process-local debug
  environment values for `NuRpcService`.
- `source/src/qt/nu/legacy-osx107/main.cpp`: Lion legacy startup mirrors the
  same behavior.
- `source/src/clientversion.h`,
  `source/src/qt/nu/app/CMakeLists.txt`,
  `source/src/qt/nu/legacy-osx107/Info.plist`, and
  `source/src/qt/nu/legacy-osx107/DefcoinCoreNuLegacy.pro`: version labels
  updated.

Compatibility notes:
- This does not change the UDP wire format, service bit, Core reservation RPC,
  validation behavior, wallet files, or datadir layout.
- Quick Clone remains the validated LAN block-copy scaffolding in this build;
  the validation-bypass DCOL snapshot installer remains future work.

Verification performed:
- Tahoe `26.6.4bh` was relaunched from the exact staged app path and the LAN
  Allow clicker was run. No prompt was present; backend advertised
  `DEFCOIN_FASTSYNC`.
- Lion chain folders `blocks`, `chainstate`, and `indexes` were deleted while
  preserving `wallets/wallet.dat`.
- Lion launched with `--debug-disable-core-tcp-sync --debug-disable-quick-clone`
  accepted UDP Fast Sync blocks through Core validation.
- After clearing `DEFCOIN_NU_DEBUG_DISABLE_QUICK_CLONE` from launchd, Lion
  launched with `--debug-disable-core-tcp-sync --quick-clone-now` accepted
  Quick Clone LAN blocks through Core validation.

Risks / follow-up:
- Add a visible warning if any debug launch switch is active during normal UI
  use, so future manual tests cannot confuse a disabled path with a failed
  protocol.
- Keep Quick Clone and Fast Sync tests isolated first, then re-enable Core TCP
  competition after the isolated path is proven.

### 26.6.4be - 2026-06-08 - Lion iMac source refresh and peer Methods parity

Big picture:
- The latest UTM Lion working tree was copied to the physical Lion iMac so the
  iMac build no longer lags the UTM test source. Tahoe and Lion were then
  checked for Fast Sync/Quick Clone invariant parity. The low-level backend
  transport logic remains aligned: UDP is only a transport for Core-selected
  block reservations, and blocks still submit through Core validation.
- Lion's peer table transport column now uses the same visible label as Tahoe:
  `Methods`. The data remains the observed transport method string, such as
  `P2P TCP`, `UDP FS`, or `P2P TCP + UDP FS`.

Porting priority:
- Lion Intel: already ported into the local Lion source and must be copied to
  the physical iMac before building.
- Catalina UTM: UI wording parity only if Catalina has the legacy peers table.
- Windows: UI wording parity only if its peers table still says Observed
  Traffic for the transport-method column.
- Server: no code change; server Fast Sync logic should already match the
  reservation RPC and service-bit behavior.

Changed behavior:
- Tahoe visible version becomes `26.6.4be`.
- Lion visible version becomes `26.6.4be-Lion-alpha`.
- Lion Metrics > Peers simple and detailed tables rename the transport column
  from `Observed Traffic` to `Methods`, matching Tahoe.

Changed files and important details:
- Tahoe `src/clientversion.h`: `DEFCOIN_RELEASE_VERSION_STR` to `26.6.4be`.
- Tahoe `src/qt/nu/app/CMakeLists.txt`: `DEFCOIN_NU_RELEASE_NAME` to
  `26.6.4be`.
- Lion `src/clientversion.h`: `DEFCOIN_RELEASE_VERSION_STR` to
  `26.6.4be-Lion-alpha`.
- Lion `src/qt/nu/legacy-osx107/DefcoinCoreNuLegacy.pro`: compile define to
  `26.6.4be-Lion-alpha`.
- Lion `src/qt/nu/legacy-osx107/main.cpp`: fallback version string and peers
  table column labels updated.

Compatibility notes:
- This build does not change the UDP wire format, service bit 29, block
  reservation RPCs, or Quick Clone request semantics.
- The physical iMac's current Bonjour-resolved address was
  `Library-Archives-Cataloging-iMac.local` / `192.168.0.189`; the old
  `192.168.2.19` address was not reachable during this port.

Verification performed:
- `rg` invariant scan confirmed Tahoe and Lion both contain the debug sync
  switches, Quick Clone, UDP Fast Sync capability string, service-bit label,
  and `reservefastsyncblock` path.
- `cmp` confirmed `src/net_processing.h`, `src/protocol.cpp`,
  `src/protocol.h`, and `src/rpc/net.cpp` match between Tahoe and Lion; the
  `src/net_processing.cpp` Fast Sync differences were line-number drift only in
  the targeted reservation-symbol diff.

Risks / follow-up:
- The Lion working tree metadata on UTM/iMac still points at the Mac Mini
  worktree gitdir and is invalid on those hosts. Build from source works, but
  git status on the remote Lion machines is not authoritative until that
  worktree metadata is repaired.
- Live UDP/Quick Clone testing still requires launching current Tahoe and Lion
  builds and ensuring Tahoe's macOS Local Network permission prompt is accepted
  for each fresh Tahoe build.

### 26.6.4bb - 2026-06-06 - Fast Sync early-header automatic scheduling

Big picture:
- Live Tahoe/Lion testing proved the 26.6.4ba low-level explicit reservation
  fallback works: `reservefastsyncblock reserve <peer> 1` returned `reserved`
  while Lion had only the first few thousand headers. The automatic
  `reserve-next` path was still too conservative because a partially synced
  `pindexBestKnownBlock` below `nMinimumChainWork` made it return
  `headers-below-minimum-chain-work`. This build allows automatic Fast Sync to
  reserve the next active-chain block from the local header chain during early
  header sync, while still submitting received data through Core validation.

Porting priority:
- Lion Intel/UTM: required. Tahoe and Lion must use identical reservation logic
  or they will disagree about when UDP can start during clean bootstrap.
- Catalina UTM: required if Fast Sync is tested there.
- Windows: required for parity before Windows UDP testing.
- Server: required after local Tahoe/Lion accepted-UDP-block tests pass.

Changed behavior:
- `reservefastsyncblock reserve-next` no longer waits for the peer's
  best-known block chain work to reach minimum chain work if UDP transport is
  verified and the local header chain already has the next needed header.
- Explicit reservation behavior from 26.6.4ba is unchanged.
- The block still goes through `MarkBlockAsInFlight` and normal block
  acceptance; this does not bypass consensus validation.

Changed files and important details:
- `src/net_processing.cpp`: in `ReserveNextFastSyncBlockInFlight()`, compute
  `next_height` before the minimum-chain-work gate and switch to the
  `FastSyncHeaderFallbackIndex()` path when the peer's known header chain is
  below minimum work. Keep this exact logic in Tahoe, Lion, server, and Windows.
- Tahoe version metadata: bumped to `26.6.4bb`.
- Lion version metadata: bumped to `26.6.4bb-Lion-alpha`.

Verification performed:
- Pre-patch UTM Lion 26.6.4ba saw Tahoe 26.6.4ba as peer 2 with
  `DEFCOIN_FASTSYNC`, but `reserve-next` returned
  `headers-below-minimum-chain-work`.
- The same session showed `reserve 2 1` returned `reserved`, proving the lower
  block reservation path can work during early header sync.
- Build/test verification pending; update after Tahoe/Lion 26.6.4bb packaging
  and isolated UDP retest.

Risks / follow-up:
- This intentionally starts UDP earlier than Core's normal block-download
  minimum-chain-work gate. The payload is still validated by Core, but watch
  logs for wasted early reservations if a peer's starting height is misleading.

### 26.6.4ba - 2026-06-06 - Fast Sync early-header reservation fallback

Big picture:
- UDP Fast Sync was reaching service-bit negotiation and UDP probe/ack, but
  Lion could not reserve even block 1 from Tahoe because Core had not populated
  that peer's `pindexBestKnownBlock` yet. This build keeps UDP as a transport
  only, but allows verified Fast Sync peers to reserve locally-known early
  headers when the peer's VERSION `startingheight` proves it should have that
  height. Blocks are still submitted through normal Core validation.

Porting priority:
- Lion Intel/UTM: required. The same `src/net_processing.cpp` fallback must be
  present or Lion will remain stuck at `peer-best-block-unknown` against Tahoe.
- Catalina UTM: required if it uses the same Fast Sync reservation RPC.
- Windows: required for parity before Windows Fast Sync testing.
- Server: required after Tahoe/Lion prove accepted UDP blocks locally; server
  should advertise bit 29 and use the same requester/responder reservation
  semantics.

Changed behavior:
- `reservefastsyncblock reserve` and `reserve-next` no longer fail solely
  because `pindexBestKnownBlock` is unset for a verified Fast Sync peer.
- Fallback is conservative: it requires UDP transport verification,
  `nStartingHeight >= requested height`, a locally known validated header at
  that height, and normal `MarkBlockAsInFlight` plus later `submitblock`
  validation. It does not trust UDP payloads or bypass consensus.

Changed files and important details:
- `src/net_processing.cpp`: added `FastSyncHeaderFallbackIndex()` and fallback
  branches in `ReserveFastSyncBlockInFlight()` and
  `ReserveNextFastSyncBlockInFlight()`. Keep this backend code identical across
  Tahoe/Lion/server where possible.
- Tahoe version metadata: bumped to `26.6.4ba`.
- Lion version metadata: bumped to `26.6.4ba-Lion-alpha`.

Compatibility notes:
- Legacy 1.0.0 peers are unaffected because they do not advertise the Defcoin
  Fast Sync service bit and cannot pass UDP transport verification.
- This remains compatible with normal TCP/Core sync; if UDP fails, Core can keep
  syncing by its normal path unless disabled for testing.

Verification performed:
- Pre-patch live test showed Lion peer id 11 for Tahoe with
  `servicesnames` including `DEFCOIN_FASTSYNC`, but `synced_headers=-1` and
  `reservefastsyncblock reserve-next 11` returned
  `peer-best-block-unknown`.
- Build/test verification pending in this entry; update after packaging and
  Tahoe/Lion UDP retest.

Risks / follow-up:
- If headers are still too slow on Lion, inspect why header chain state is not
  persisted or why header download is throttled. Do not mistake header latency
  for UDP failure.

### 26.6.4az - 2026-06-06 - Trustworthy UDP failure accounting and Tahoe LAN prompt automation

Big picture:
- This build fixes two problems that were poisoning Fast Sync test results:
  Tahoe's Local Network Allow helper could accidentally match Codex chat text
  through whole-screen OCR, and UDP Metrics collapsed probe misses, request
  timeouts, checksum failures, buffer failures, and submit failures into one
  vague failure count. Future Fast Sync tests should treat any run before a
  confirmed Tahoe Allow click as invalid.

Porting priority:
- Lion Intel/UTM: required. Port the separated UDP status counters and wording
  so Lion reports the same evidence as Tahoe during Tahoe-to-Lion testing.
- Catalina UTM: required if it shows Fast Sync Metrics or runs the same
  requester-side transport logic.
- Windows: port the Metrics wording/counter split if Windows exposes the same
  Fast Sync rows.
- Server: after Tahoe/Lion prove UDP block transfer works, update server code to
  the same Fast Sync requester/responder behavior. Server does not need the
  macOS Allow helper.

Changed behavior:
- Metrics now separates UDP probe misses from real block payload failures.
- Fast Sync UDP details split payload failures into timeout/checksum/buffer/
  submit categories, plus request/probe send failures.
- The macOS Local Network Allow helper is Accessibility-first by default. It no
  longer uses whole-screen OCR unless `--ocr-fallback` is explicitly supplied.
  This prevents false positives caused by the prompt wording appearing in Codex
  or another visible document.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.h/.cpp`: added reason buckets for UDP failure
  accounting; updated status text to show probe misses and block failure kinds.
- `src/qt/nu/tools/macos_click_lan_allow.swift`: defaults to native
  Accessibility prompt search; OCR fallback must now be explicitly requested.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: Tahoe visible build
  label bumped to `26.6.4az`.
- Lion equivalent: `src/qt/nu/legacy-osx107/main.cpp`,
  `src/qt/nu/legacy-osx107/DefcoinCoreNuLegacy.pro`, and
  `src/clientversion.h` use `26.6.4az-Lion-alpha`.

Compatibility notes:
- Consensus and block acceptance are unchanged. This is accounting, status, and
  test automation reliability work.
- When testing Tahoe UDP, launch the current Tahoe build and run the Allow
  helper after the OS prompt appears or with a long retry window. Do not infer
  UDP failure from a blocked Local Network prompt.

Build/package notes:
- Build only Defcoin Core Nu. Defcoin Core Explore remains a separate app and
  distribution cycle.

Verification performed:
- `git diff --check -- src/qt/nu/app/NuRpcService.cpp src/qt/nu/app/NuRpcService.h src/qt/nu/tools/macos_click_lan_allow.swift` passed in Tahoe source.
- `git diff --check -- src/qt/nu/legacy-osx107/main.cpp` passed in Lion source.
- The updated Tahoe Allow helper returns `contextFound:false` and
  `No native Local Network Allow prompt was found` on a screen where only Codex
  contains prompt wording.

Risks / follow-up:
- Rebuild Tahoe and Lion, test UDP-only Fast Sync after the Tahoe Allow prompt
  is confirmed, then install matching Fast Sync behavior on the server only if
  live UDP block transfer succeeds.

### 26.6.4ay - 2026-06-05 - Header-gated UDP scheduling diagnostics

Big picture:
- Fresh Tahoe-to-UTM Lion testing was restarted with current builds and the
  macOS LAN prompt allowed. The key observation changed: Tahoe acknowledged the
  Lion UDP probe, so UDP reachability was proven, but Lion was still rebuilding
  headers from block zero and Core could not yet schedule a downloadable block.
  That is a header/scheduler gate, not a UDP packet failure.

Porting priority:
- Lion Intel/UTM: required. Port the same backend reservation reasons, status
  formatter, startup error normalization, and bounded Bonjour lookup helper.
- Catalina UTM: required if Catalina shares the same Nu service and LAN
  workstation-name helper.
- Windows: port the reservation/status wording if Windows uses this frontend.
  The Bonjour helper fix is macOS-only.
- Server: no responder change from this entry. Server requester-side Fast Sync
  should report the same scheduling reasons if it calls `reserve-next`.

Changed behavior:
- `reservefastsyncblock reserve-next` now returns specific early-gate reasons
  before falling through to the generic downloader search: `peer-best-block-unknown`,
  `peer-chain-not-ahead`, or `headers-below-minimum-chain-work`.
- Fast Sync and Quick Clone use one shared status formatter for Core scheduling
  waits. In UDP-only test mode it says Core TCP block copy is off instead of
  claiming normal TCP sync remains active.
- The startup RPC batch path normalizes transient backend transport errors to
  "Starting Defcoin backend..." instead of surfacing raw `Connection refused`.
- The macOS Bonjour/SMB LAN workstation lookup no longer pipes an infinite
  `dns-sd -B` browser through a shell. It samples for a bounded interval and
  kills the child process so peer refreshes do not leak helper processes.

Changed files and important details:
- `source/src/net_processing.cpp`: added explicit prechecks in
  `ReserveNextFastSyncBlockInFlight()` after `ProcessBlockAvailability()`.
- `source/src/qt/nu/app/NuRpcService.cpp`: added
  `coreSchedulingWaitStatus()` and wired it into both Fast Sync and Quick
  Clone reservation callbacks; expanded diagnostic detail with header/local
  block counts; bounded the Bonjour helper; normalized batch RPC transport
  startup errors.
- `source/src/qt/nu/app/NuRpcService.h`: declares the new formatter.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  build metadata bumped to `26.6.4ay`.

Compatibility notes:
- This does not change consensus or block validation.
- UDP remains a transport for a Core-selected block reservation. If headers are
  still below minimum chainwork, no UDP block request should be sent yet.
- Treat this as a correction to prior testing assumptions: an allowed UDP probe
  does not mean Core is ready to request block bodies while headers are still
  catching up from zero.

Build/package notes:
- Tahoe build target: `26.6.4ay`.
- Lion build target: `26.6.4ay-Lion-alpha`.

Verification performed:
- Live UTM screen check: Lion was at block 0 with headers advancing and no OK
  modal blocking the app.
- Live logs/RPC: Lion probe reached Tahoe and Tahoe sent UDP probe ACK;
  `reservefastsyncblock transport-verified` succeeded for the Tahoe peer.
- Live RPC: `reservefastsyncblock reserve-next` returned no schedulable block
  while headers were still building, matching the new diagnostic path.

Risks / follow-up:
- After Lion headers reach a schedulable state, retest actual accepted UDP block
  delivery with current Tahoe and Lion builds only.
- If block delivery still fails after scheduling opens, inspect request/chunk
  logs rather than revisiting LAN permission as the first assumption.

### 26.6.4ar - 2026-06-05 - ACK-proven UDP peers and honest sync percent

Big picture:
- Tahoe-to-UTM Lion testing showed two separate issues. The sync dialog could
  display `Progress 100%` while `blocks < headers` because the backend rounded
  `verificationprogress` to an integer. Separately, UDP Fast Sync target
  selection could reject peers that looked public before sending the safe UDP
  probe, even though UTM can expose a same-machine/LAN peer as a globally routed
  IPv6 endpoint.

Porting priority:
- Lion Intel: required. The selector and datagram-size changes were already
  applied to `legacy-osx107/main.cpp`.
- Catalina UTM: required if it shares the Lion legacy frontend.
- Windows: port the selector concept if Windows uses this frontend logic.
- Server: no frontend sync-dialog change. Requester-side Fast Sync code should
  not reject safe probes before ACK.

Changed behavior:
- Sync progress is capped below `100%` while blocks are still behind headers.
  The dialog should only clear through the existing not-syncing path when Core
  reports the chain is actually caught up.
- UDP selectors may choose a public-looking peer for a safe-sized probe.
- Once a peer ACKs a UDP Fast Sync probe, it is treated as a proven target for
  larger datagram sizing. The serving peer still caps based on what it sees and
  block chunks remain checksum-protected.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: sync progress integer capping;
  added `isPrivateLocalOrProvenUdpFastSyncTarget()`; selector scoring and
  datagram sizing now include ACK-proven peers.
- `source/src/qt/nu/app/NuRpcService.h`: declares the new helper.
- `source/src/qt/nu/legacy-osx107/main.cpp`: equivalent selector and
  datagram-size changes for Lion.
- Version metadata bumped to `26.6.4ar`; Lion label is
  `26.6.4ar-Lion-alpha`.

Compatibility notes:
- This does not bypass Core validation or normal peer selection.
- The safe probe remains small; larger chunks happen only after UDP ACK and the
  serving side's cap logic.

Verification performed:
- Pending rebuild and Tahoe/Lion live test.

Risks / follow-up:
- If UDP still fails after ACK, inspect request/chunk logs on the serving side
  for the normalized sender host and reply port.

### 26.6.4ao - 2026-06-05 - TCP-off launch mode forces UDP selector

Big picture:
- The `--debug-disable-core-tcp-sync` launch switch already reached the backend
  as `-defcoindisablecoretcpblocks=1`, but the frontend Fast Sync selector still
  spent quota on the normal Core/TCP path. That made isolated UDP testing noisy
  because the UI could keep waiting for a TCP block-body path that was
  intentionally disabled.

Porting priority:
- Lion Intel: required. Port the same selector behavior so UTM/iMac Lion tests
  use the same UDP-only debug mode as Tahoe.
- Catalina UTM: port if Catalina uses the same Nu Fast Sync selector.
- Windows: port if Windows exposes the same debug launch switch.
- Server: no change unless the server has a requester-side test mode that
  intentionally disables TCP block-body fetches.

Changed behavior:
- `--debug-disable-core-tcp-sync` and
  `DEFCOIN_NU_DEBUG_DISABLE_CORE_TCP_SYNC=1` still leave peers, headers, and
  service-bit negotiation active.
- In that mode only, frontend Fast Sync allocates zero Core/TCP quota and uses
  UDP probes/reservations whenever eligible peers are present and UDP is not in
  cooldown.
- The legacy `--debug-disable-core-sync` alias remains accepted but is treated
  as TCP-block-copy-only for this test path.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: `resetFastSyncProtocolWindow()` and
  `shouldAttemptUdpFastSync()` now special-case
  `m_debug_disable_core_sync`.
- `source/src/qt/nu/legacy-osx107/main.cpp`: same logic using
  `m_debugDisableCoreSync`.
- `source/src/clientversion.h` and app build metadata bumped to `26.6.4ao`;
  Lion uses `26.6.4ao-Lion-alpha`.

Compatibility notes:
- Normal launches are unchanged. This is a debug/test launch behavior only.
- Full Core network shutdown is still only appropriate for Quick Clone/DCOL
  tests, not Fast Sync transport isolation.

Verification performed:
- Pending rebuild and Tahoe/Lion live UDP test.

Risks / follow-up:
- If Lion remains in header-building state, UDP requests may still defer until
  Core's peer/header state can reserve a specific block. That is expected and
  should be logged as reservation deferral, not as UDP packet failure.

### 26.6.4ak - 2026-06-05 - Fast Sync frontend timing parity

Big picture:
- After the backend reservation parity fix in `26.6.4aj`, the Tahoe and Lion
  frontend Fast Sync constants were compared. The lower-level reservation and
  service-bit behavior matched, but Lion still used older probe/timer timings.
- Lion now uses Tahoe's 500 ms Fast Sync timer and 2500 ms UDP probe timeout so
  both builds probe, expire, and retry with the same expectations.
- Tahoe was bumped to the same suffix so package labels stay aligned even
  though the timing code change itself is Lion-side.

Porting priority:
- Lion Intel: ported in this pass.
- Catalina UTM: align any legacy frontend constants to Tahoe's 500 ms tick and
  2500 ms UDP probe timeout.
- Windows: no code change unless the Windows frontend carries divergent timing
  constants.
- Server: no change from this frontend timing entry.

Changed behavior:
- Lion no longer waits 6 seconds before declaring a UDP probe expired. It now
  uses Tahoe's 2.5 second probe timeout and 500 ms tick.

Changed files and important details:
- Tahoe `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: version bump
  to `26.6.4ak`.
- Lion `src/clientversion.h`, `src/qt/nu/legacy-osx107/DefcoinCoreNuLegacy.pro`,
  `src/qt/nu/legacy-osx107/Info.plist`, and
  `src/qt/nu/legacy-osx107/main.cpp`: version bump to
  `26.6.4ak-Lion-alpha`.
- Lion `src/qt/nu/legacy-osx107/main.cpp`: `LAN_FAST_SYNC_TIMER_INTERVAL_MS`
  changed from 750 to 500; `LAN_FAST_SYNC_PROBE_TIMEOUT_MS` changed from 6000
  to 2500.

Verification performed:
- Backend reservation function diff between Tahoe and Lion returned clean.
- Live UTM/Tahoe UDP probe test succeeded in the UTM-to-Tahoe direction.
- Synthetic UTM Quick Clone-style `request-block` received a Tahoe
  `block-chunk` response with height/hash/checksum metadata.

Risks / follow-up:
- UTM Lion is NATed at `10.0.2.15`; Tahoe cannot initiate UDP directly to the
  guest listener without bridged networking or forwarding. Receiver-initiated
  UTM-to-Tahoe UDP works.

### 26.6.4aj - 2026-06-05 - Fast Sync reservation parity audit

Big picture:
- Tahoe and Lion were audited for Fast Sync and Quick Clone receiver/listener
  behavior. The intended shared rule is now explicit: Core selects and reserves
  the peer/block; UDP is only the transport used to deliver that one reserved
  block; `submitblock` remains the normal Core acceptance path.
- Lion still had an older header-chain fallback inside
  `ReserveFastSyncBlockInFlight()` / `ReserveNextFastSyncBlockInFlight()`. That
  fallback could reserve a block Tahoe would refuse, making the two builds
  expect different behavior during LAN tests.
- Tahoe now treats `submitblock` result `inconclusive` the same way Lion does:
  as a delivered block sample handed to Core during IBD, not as a UDP transport
  failure.

Porting priority:
- Lion Intel: ported in this pass. Keep the backend reservation functions
  byte-for-byte aligned with Tahoe after this entry.
- Catalina UTM: remove any header-chain fallback or guessed-height reservation
  path if present; accept `inconclusive` as a non-error submit result.
- Windows: accept `inconclusive` in the QML/Qt UDP submit callback if the
  Windows UI uses `NuRpcService.cpp`.
- Server: requester-side Fast Sync must use Core-selected reservations only.
  Responder-only services are unaffected.

Changed behavior:
- Fast Sync receiver:
  - probes service-bit peers over UDP;
  - marks transport verified only after a valid probe acknowledgement;
  - calls `reservefastsyncblock reserve-next <nodeid>`;
  - requests only the returned height/hash over UDP;
  - validates chunk and block checksums;
  - submits the assembled raw block through Core.
- Fast Sync listener:
  - advertises `NODE_DEFCOIN_FASTSYNC` only when launched with
    `-defcoinfastsync=1`;
  - answers valid probes and block requests on UDP 10334;
  - serves chunks only for heights it already has locally.
- Quick Clone receiver:
  - is a trusted-LAN/manual/session request layered on the same UDP transport;
  - uses LAN candidates only;
  - still submits every received block through Core in this build;
  - does not use snapshot replacement yet.
- Quick Clone listener:
  - keeps advertising LAN availability through beacons/discovery;
  - serves the same checksum-protected UDP block chunks as Fast Sync.

Changed files and important details:
- Tahoe `source/src/qt/nu/app/NuRpcService.cpp`: `submitblock` handling now
  accepts `inconclusive` alongside empty/null and `duplicate`.
- Lion `src/net_processing.cpp`: removed `nFastSyncReserveScanHeight`, removed
  fallback helper functions, and matched Tahoe's Core-selected reservation
  functions.
- Tahoe and Lion version metadata bumped to `26.6.4aj` /
  `26.6.4aj-Lion-alpha`.

Compatibility notes:
- Older Defcoin Core 1.0.x peers are unaffected. They do not advertise bit 29
  and continue normal TCP block sync.
- If a peer has not reached usable Core peer state yet, the expected reason is
  now `peer-best-block-unknown` or another Core scheduler reason on both
  platforms, not a platform-specific fallback reservation.

Verification performed:
- `diff` of Tahoe vs Lion `ReserveFastSyncBlockInFlight()` through
  `ReleaseFastSyncBlockInFlight()` returned no differences after the patch.
- `rg` found no remaining Lion fallback symbols:
  `FastSyncFallback`, `nFastSyncReserveScanHeight`, `header-chain fallback`,
  or `local-block-data-scan`.

Risks / follow-up:
- This simplifies behavior but may wait for Core peer state instead of forcing
  a UDP request earlier. That is intentional: it keeps UDP from bypassing Core's
  scheduler.

### 26.6.4ai - 2026-06-05 - Metrics sync-method labeling cleanup

Big picture:
- Metrics > Status now names the three sync paths by what they actually do:
  `Core Sync (TCP)`, `Fast Sync (UDP)`, and `Quick Clone (LAN UDP)`.
- The old visible label `Fast Sync TCP` was misleading because that row was
  backed by Core's normal P2P/validation path, not by a TCP version of Fast
  Sync.

Porting priority:
- Lion Intel: ported in this pass; keep the same labels in the legacy
  `populateDiagnosticsStatus()` rows.
- Catalina UTM: port the same Status labels if it has the Nu metrics page.
- Windows: port the same Status labels if its QML Status table is built from
  `NuRpcService::rebuildNodeMetrics()`.
- Server: no server behavior change; this is UI/telemetry wording only.

Changed behavior:
- `Sync overview` shows combined sync throughput.
- `Core Sync (TCP)` shows Core's normal TCP P2P/validation path.
- `Fast Sync (UDP)` and its decision/probe rows are grouped together.
- `Quick Clone (LAN UDP)` rows are grouped together.
- Status rows with one visible line should no longer reserve unnecessary
  two-line height.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: renamed node metric rows and kept
  the explanatory nuance in hover text instead of adding a noisy note row.
- `source/src/qt/nu/qml/Views/NodeView.qml`: narrowed the metric column a bit
  and capped Status row wrapping to two lines so the table stays compact.
- `source/src/qt/nu/legacy-osx107/main.cpp`: applied matching Lion row labels,
  removed the separate `Fast Sync TCP note`, shortened UDP sample text, and
  tightened single-line row heights after `resizeRowsToContents()`.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible Tahoe version is `26.6.4ai`.
- Lion source version/plist files: visible Lion version is
  `26.6.4ai-Lion-alpha`.

Compatibility notes:
- This does not change Fast Sync or Quick Clone networking. It only prevents
  the UI from implying that Fast Sync has a TCP mode.

Verification performed:
- Pending build/smoke in this thread. Grep should show no remaining visible
  `Fast Sync TCP` Status labels after this entry.

Risks / follow-up:
- If long runtime status values still wrap unexpectedly, shorten the value text
  first; avoid adding more explanatory prose to Metrics rows.

### 26.6.4ae - 2026-06-04 - Quick Clone command-line test hook and Lion parity

Big picture:
- Tahoe and Lion now share the same Quick Clone/Fast Sync reservation boundary:
  UDP is only a transport for a block Core has reserved from normal peer state.
- A temporary but intentional test hook was added so Codex can launch a build
  and force Quick Clone initiation without walking through the UI. This exists
  to make Tahoe/Lion LAN testing reproducible.
- Lion's apparent "lost sync progress" after relaunch was checked before
  deleting any chain data. The persisted best block did not roll back; the UI
  appeared to lose percent progress because the header target changed after
  relaunch while the absolute block height was still persisted.

Porting priority:
- Lion Intel: already ported in the Lion workspace as `26.6.4ae-Lion-alpha`;
  keep the same command-line trigger and Core reservation behavior.
- Catalina UTM: port the command-line trigger if it needs automated Quick Clone
  testing. Keep architecture-specific build flags separate.
- Windows: port only if Windows needs automated Quick Clone launch tests.
- Server: no GUI trigger needed. Requester-side server Fast Sync should still
  use Core-selected/reserved blocks, not guessed heights.

Changed behavior:
- Launching Nu with `--quick-clone-now`, or with
  `DEFCOIN_NU_QUICK_CLONE_NOW=1`, schedules `syncUsingQuickCloneNow()` shortly
  after startup.
- Lion Quick Clone now calls `reservefastsyncblock reserve-next` with a
  `lan-fast-copy-reserve` context before sending a UDP block request.
- Duplicate Quick Clone submit results are treated as stale work and do not
  count as progress.
- Added a local test helper that watches Nu logs for UDP evidence and alerts
  with `beep`/`say` if the launch test appears blocked by macOS Local Network
  permission.

Changed files and important details:
- `source/src/qt/nu/app/main.cpp`: Tahoe command-line Quick Clone trigger.
- `source/src/clientversion.h`, `source/src/qt/nu/app/CMakeLists.txt`,
  `source/src/qt/nu/docs/README.md`,
  `source/src/qt/nu/docs/functionality-map.md`: visible release label
  `26.6.4ae`.
- `source/src/qt/nu/tools/udp_lan_permission_gate.sh`: Tahoe-side test helper
  for the first UDP LAN blocker check. This is not a product feature and does
  not change firewall/TCC state.
- Lion equivalent files:
  `src/qt/nu/legacy-osx107/main.cpp`, `src/clientversion.h`,
  `src/qt/nu/legacy-osx107/DefcoinCoreNuLegacy.pro`, and
  `src/qt/nu/legacy-osx107/Info.plist`.

Compatibility notes:
- Consensus, wallet storage, service bits, packet format, checksums, and Core
  block validation are unchanged.
- Older TCP-only peers and v1.0.x peers are unaffected.

Build/package notes:
- Build/package only Defcoin Core Nu for this entry. Explore/ExpFor remains its
  own app and release cycle.
- Before live tests, close any previous Nu app/backend instance on both Tahoe
  and Lion. The GUI/backend are not designed to run multiple versions against
  the same datadir.

Verification performed:
- Tahoe backend/tools built and report `v26.6.4ae`.
- Tahoe Qt bundle built and staged at
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.4ae-20260604/Defcoin Core Nu.app`.
- Staged Tahoe app passed deep codesign verification; bundled `defcoind`,
  `defcoin-cli`, and `Info.plist` all report `26.6.4ae`; Spotlight kind is
  `Application`.
- Lion pre-build persistence check showed the backend reloaded the same
  persisted absolute height (`15781`) after relaunch; no blockchain rollback was
  observed.

Risks / follow-up:
- Live Tahoe/Lion UDP testing must first confirm macOS Local Network permission
  is not blocking UDP. If UDP probes cannot pass, alert locally before trying to
  diagnose protocol behavior.
- After Lion package is complete, launch Tahoe and Lion with the new test hook
  and verify real UDP block acceptance plus Quick Clone reservation behavior.

### 26.6.4ad - 2026-06-04 - Quick Clone uses Core block reservation

Big picture:
- Lion could show that a UDP block arrived but Core already had it. That is
  possible when the GUI schedules a block from stale height state while Core's
  normal sync accepts the same height through TCP, or when late UDP chunks
  arrive after Core has already advanced.
- The root issue was that normal UDP Fast Sync already used
  `reservefastsyncblock reserve-next`, but the Quick Clone scaffolding path was
  still directly requesting `m_block_height + 1`.
- Quick Clone now uses the same Core reservation boundary as Fast Sync. UDP is
  again only a transport for a block Core selected from a connected peer.

Porting priority:
- Lion Intel: port directly to `src/qt/nu/legacy-osx107/main.cpp` after the
  current Lion build thread is clear. This is the fix for Lion's
  `already had it` UDP message.
- Catalina UTM: port if its Quick Clone/LAN copy path guesses the next height.
- Windows: port if it shares the QML/Qt Quick Clone path.
- Server: requester-side behavior should match this if the server can request
  Fast Sync blocks; responder-only behavior is unchanged.

Changed behavior:
- `lanQuickCloneTick()` now requires a Core peer id, asks Core to reserve the
  next missing block, and requests that reserved height/hash over UDP.
- Quick Clone no longer issues multiple `reservefastsyncblock` calls at once.
- Duplicate Quick Clone submit results are treated as stale/skipped work and
  are not counted as Quick Clone progress.
- Ordinary TCP sync remains active unless a future real snapshot install stage
  explicitly pauses it.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: Quick Clone scheduling now mirrors
  the lower-level Fast Sync reservation path instead of guessing a height.
- `source/src/qt/nu/docs/quick-clone-status-language.md`: added reservation and
  stale-skip status phrases.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4ad`.
- `source/src/qt/nu/docs/release-notes-26.6.4ad.md`: user-facing notes.

Compatibility notes:
- Consensus, wallet storage, service bits, packet format, checksums, and Core
  block validation are unchanged.
- Older TCP-only peers and v1.0.x peers are unaffected.

Build/package notes:
- Build/package only Defcoin Core Nu for this entry. Explore/ExpFor remains its
  own app and release cycle.

Verification performed:
- Tahoe backend build succeeded with:
  `make -C source/src defcoind defcoin-cli defcoin-tx defcoin-wallet -j8`.
- Tahoe Qt bundle build succeeded with:
  `cmake --build build/nu-qml-arm64-26.6.4ad --target DefcoinCoreNu -j 8`
  and `DefcoinCoreNuResources`.
- Staged app verifies as a macOS app at
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.4ad-20260604/Defcoin Core Nu.app`.
- Bundled `defcoind --version` and `defcoin-cli --version` both report
  `v26.6.4ad`.
- Launch smoke test succeeded after closing `26.6.4ac`: frontend/backend ran
  from the `26.6.4ad` app, RPC `getnetworkinfo` reported subversion
  `/DefcoinCoreNu:26.6.4ad/`, `DEFCOIN_FASTSYNC`, and `networkactive=true`;
  RPC `getblockchaininfo` reported main chain at matching blocks/headers.
- Lion port/test remains blocked until the separate Lion build thread is clear.

Risks / follow-up:
- After Lion is clear, port `26.6.4ac` and `26.6.4ad` together. Success
  criteria: Lion's UDP status progresses from Core reservation to accepted
  non-duplicate blocks, or gives a clear Core scheduling reason; it should not
  repeatedly request blocks it already has.

### 26.6.4ac - 2026-06-04 - Quick Clone no longer parks Core P2P while probing

Big picture:
- Live Tahoe/Lion rebuild testing found that the Quick Clone scaffolding path
  could pause Core networking before a real snapshot/install stage existed.
- On Lion this produced `networkactive=false`, zero peers, and no useful Fast
  Sync reservations after the public chain folders were removed for a clean
  rebuild test.
- Quick Clone should only isolate ordinary networking during a future final
  snapshot install/swap. While it is listening, probing, or requesting
  Core-accepted block data, Core P2P must remain active so normal peer
  selection and Fast Sync reservation can work.

Porting priority:
- Lion Intel: port directly to `src/qt/nu/legacy-osx107/main.cpp`, but do not
  touch the Lion host while another build thread is active there.
- Catalina UTM: port the same behavior if Quick Clone/LAN copy scaffolding can
  pause network activity before install.
- Windows: port if the Windows build uses the same Quick Clone tick path.
- Server: not required unless the server UI/controller has equivalent Quick
  Clone scaffolding. Fast Sync service-bit and UDP responder behavior are
  unchanged.

Changed behavior:
- Quick Clone no longer calls `setNetworkActive(false)` simply because a trusted
  LAN source exists.
- If Quick Clone detects it had previously paused Core networking, it now
  resumes Core P2P and reports that it is listening on LAN.
- The active receive status now says `Quick Clone receiving blockchain over LAN:
  requesting block <height> from <host>.`

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: `lanQuickCloneTick()` now resumes a
  stale paused-network state instead of entering it during ordinary
  listen/probe/request work.
- `source/src/qt/nu/docs/quick-clone-status-language.md`: reviewable status
  taxonomy grouped by waiting/listening, supplying, and receiving.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4ac`.
- `source/src/qt/nu/docs/release-notes-26.6.4ac.md`: user-facing notes.

Compatibility notes:
- Consensus, wallet storage, service bits, packet format, checksums, and Core
  block validation are unchanged.
- Older TCP-only peers and v1.0.x peers are unaffected.

Build/package notes:
- Build/package only Defcoin Core Nu for this entry. Explore/ExpFor remains its
  own app and release cycle.

Verification performed:
- Tahoe backend built with `make -C source/src defcoind defcoin-cli defcoin-tx
  defcoin-wallet -j8`.
- Tahoe Qt app built with CMake/Ninja into
  `build/nu-qml-arm64-26.6.4ac`; `DefcoinCoreNuResources` bundled the backend
  tools and verified the app bundle.
- Staged app:
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.4ac-20260604/Defcoin Core Nu.app`.
- Bundle verification passed: `codesign --verify --deep --strict`.
- Bundled backend and CLI reported `v26.6.4ac`; Info.plist reported
  `CFBundleShortVersionString=26.6.4ac`; Spotlight kind reported
  `Application`.
- Old local Tahoe Nu frontend/backend were stopped before relaunching the new
  build. Relaunch smoke test showed one frontend, one bundled backend,
  `networkactive=true`, and `localservicesnames` includes `DEFCOIN_FASTSYNC`.
- Lion port/test is intentionally paused until the separate Lion build thread is
  clear.

Risks / follow-up:
- After Lion is clear, port the matching legacy fix and retest from a clean
  public-chain rebuild. Success criteria: Lion keeps Core networking active,
  sees Tahoe as a peer, and UDP accepted block counts increase instead of
  staying at advertised/checking.

### 26.6.4ab - 2026-06-04 - UDP receiver already-has-block cleanup

Big picture:
- Live Tahoe/Lion testing moved past the earlier non-peer gate: Tahoe accepted
  Lion's LAN UDP Fast Sync probe and served chunks.
- The next failure was on the receiver side. Lion could log an accepted or
  already-known LAN block, then keep the same UDP transfer marked in-flight and
  later time out. In the Lion legacy code this happened when Core already had
  the requested height while late UDP chunks were still being processed.
- This build makes that state explicit: if Core already has the requested
  height while chunks arrive, the UDP attempt is completed without counting it
  as a packet failure, the reservation is released, and the next tick can choose
  the next missing block/source.

Porting priority:
- Lion Intel: port directly to `src/qt/nu/legacy-osx107/main.cpp`. This is the
  receiver-side fix needed after the `26.6.4aa` mapped-LAN sender fix.
- Catalina UTM: port the same guard in its receiver chunk handler if present.
- Windows: port if the Windows build uses this Qt UDP helper path.

Changed behavior:
- UDP Fast Sync no longer leaves a request in-flight after Core has already
  advanced to the chunk's block height.
- Quick Clone no longer treats that already-have state as an offline source or
  missing-chunk timeout.
- No consensus, wallet, service-bit, packet-format, checksum, or block
  validation behavior changes.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: `handleLanFastSyncChunk()` now
  resets the transfer when `height <= m_block_height` after the request id and
  expected height match.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4ab`.
- `source/src/qt/nu/docs/release-notes-26.6.4ab.md`: user-facing notes.

Verification performed:
- Pending Tahoe build/test in this entry.
- Port and live-test on Lion before calling Fast Sync fixed.

Risks / follow-up:
- Retest with Lion after the equivalent legacy patch. Success criteria: Lion
  shows accepted UDP block count increasing without immediately timing out or
  demoting Tahoe as an offline source.

### 26.6.4aa - 2026-06-04 - IPv4-mapped UDP LAN sender fix

Big picture:
- Live Tahoe `26.6.4z` testing proved UDP packets from Lion reached Tahoe, but
  Tahoe still logged `dropped UDP Fast Sync block request from non-peer` for
  `192.168.0.189:10334`.
- The reason was not firewall or service-bit negotiation. Tahoe's UDP socket is
  IPv6-capable, and Qt can surface an IPv4 UDP sender as an IPv4-mapped address.
  `normalizedFastSyncHost()` already handled this, but the private/LAN helper
  only checked `address.protocol()` and therefore missed `192.168.0.189` when it
  arrived through that mapped form.

Porting priority:
- Lion Intel: port directly. This is required for Lion and Tahoe to recognize
  each other as private/LAN UDP senders across mixed IPv4/IPv6 socket paths.
- Catalina UTM and Windows: port directly if their UDP socket can receive mapped
  IPv4 addresses.
- Server: port only if its Fast Sync UDP listener uses the same Qt helper path.

Changed behavior:
- `isInvalidLanDiscoveryAddress()` now checks `toIPv4Address(&ok)` before
  relying on `address.protocol()`, so IPv4-mapped addresses are filtered with
  the same invalid/broadcast/multicast rules as normal IPv4.
- `isPrivateOrLocalFastSyncAddress()` now checks `toIPv4Address(&ok)` before
  relying on `address.protocol()`, so private IPv4 ranges are accepted even when
  the UDP socket reports the sender through an IPv6 wrapper.
- Public internet behavior is unchanged.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: helper-only fix. Packet format,
  service bits, request ids, chunk checksums, and Core block validation are
  unchanged.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4aa`.
- `source/src/qt/nu/docs/release-notes-26.6.4aa.md`: user-facing notes.

Compatibility notes:
- Older TCP-only peers are unaffected.
- The fix only changes whether a private/LAN UDP sender is recognized as LAN;
  it does not admit public UDP block requests.

Build/package notes:
- Build/package only `DefcoinCoreNuResources` for Nu. Explore remains separate.

Verification performed:
- Pending Tahoe build/test in this entry.

Risks / follow-up:
- Retest Lion after restarting or after the UDP quiet period expires. Success
  criteria: Tahoe no longer logs `non-peer` drops for `192.168.0.189` and Lion
  receives accepted UDP chunks or logs a later-stage serving/validation error.

### 26.6.4z - 2026-06-04 - LAN UDP requests without clone_mode

Big picture:
- Live Tahoe `26.6.4y` testing showed one remaining failure after the old app
  was replaced: Lion retried UDP after its quiet period and Tahoe still logged
  `dropped UDP Fast Sync block request from non-peer - 192.168.0.189:10334`.
- The y fix was too narrow because it only admitted trusted-LAN requests when
  the packet had `clone_mode=true`. Lion's request path can issue LAN block
  requests without that flag.

Porting priority:
- Lion Intel: port directly. The same gate must be used when Lion receives LAN
  UDP requests or chunks.
- Catalina UTM: port directly if Fast Sync is enabled.
- Windows: port directly.
- Server: port equivalent behavior if the server serves LAN/private UDP block
  requests with this transport layer.

Changed behavior:
- Private/LAN UDP `request-block` datagrams now reach the guarded serving
  handler even if the packet is not marked `clone_mode`.
- Private/LAN UDP `block-chunk` datagrams now reach the guarded chunk handler;
  the handler still validates request id, height, checksums, and expected hash
  before accepting data.
- Public internet peers still need the normal Fast Sync peer verification before
  request/chunk packets are accepted.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: expanded only the UDP dispatcher and
  handler pre-gates for private/LAN senders. Packet format is unchanged.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4z`.
- `source/src/qt/nu/docs/release-notes-26.6.4z.md`: user-facing notes.

Compatibility notes:
- Older Defcoin Core peers are unaffected because they do not use the Nu UDP
  transport. Normal TCP/Core sync remains unchanged.
- The LAN exception only serves public block data and still goes through the
  existing chunk/request validation path.

Build/package notes:
- Build/package only `DefcoinCoreNuResources` for Nu. Explore remains separate.

Verification performed:
- `git diff --check` passed.
- Tahoe arm64 app configured and built with Qt 6 and `DEFCOIN_NU_RELEASE_NAME=26.6.4z`.
- Backend tools rebuilt from the same source tree; bundled `defcoind` and
  `defcoin-cli` report `v26.6.4z`.
- Built app passed `codesign --verify --deep --strict`.

Risks / follow-up:
- Retest with Lion after its 300-second UDP quiet period or after restarting
  Lion. Success criteria: no new `non-peer` drop on Tahoe and Lion logs accepted
  UDP blocks/chunks rather than Quick Clone timeouts.

### 26.6.4y - 2026-06-04 - LAN UDP request dispatcher and provisional peer fix

Big picture:
- Live Tahoe/Lion test showed UDP was reaching Tahoe, but Tahoe logged repeated
  `dropped UDP Fast Sync block request from non-peer - 192.168.0.189:10334`.
- This was a source-side protocol gate problem, not a firewall/LAN permission
  problem. Tahoe answered Lion probes, then rejected Lion's follow-up block
  requests before the serving handler ran.
- Quick Clone had the same structural bug: the deeper handler allowed trusted
  LAN clone requests, but the outer dispatcher dropped them first.

Porting priority:
- Lion Intel: port directly. Lion needs the same dispatcher fix for receiving
  Quick Clone chunks and the same provisional-LAN peer behavior when it acts as
  a source.
- Catalina UTM: port directly if Fast Sync/Quick Clone is enabled there.
- Windows: port directly.
- Server: port the dispatcher/provisional-peer behavior if the server has this
  QML/Nu UDP transport layer or equivalent request handling.

Changed behavior:
- `request-block` dispatch now allows a packet through when it is either from a
  normal Fast Sync peer or is a `clone_mode` request from a trusted private/LAN
  Quick Clone source.
- `block-chunk` dispatch now allows trusted-LAN Quick Clone chunks through to
  the chunk handler instead of dropping them early.
- `handleLanFastSyncProbe()` now treats a valid private/LAN Fast Sync probe as a
  provisional LAN Fast Sync peer before sending the probe ack. The ack's
  `peer_confirmed` flag now matches the source's willingness to serve the next
  block request.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: changed only the UDP dispatcher and
  probe acknowledgement path. Packet format is unchanged.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4y`.
- `source/src/qt/nu/docs/release-notes-26.6.4y.md`: user-facing notes.

Compatibility notes:
- This remains compatible with older Defcoin Core peers because the UDP path is
  only used after Defcoin Nu Fast Sync probing. Normal TCP/Core block sync is
  untouched.
- Provisional admission is limited to private/LAN addresses and public block
  serving; it does not expose wallet data.

Build/package notes:
- Build/package only `DefcoinCoreNuResources` for Nu. Explore is separate and
  should not be copied into the Nu distribution folder.

Verification performed:
- `cmake -S source/src/qt/nu/app -B build/nu-qml-arm64-26.6.4y ...`
  completed successfully for arm64 Release.
- `cmake --build build/nu-qml-arm64-26.6.4y --target DefcoinCoreNu -j 8`
  completed successfully.
- `cmake --build build/nu-qml-arm64-26.6.4y --target DefcoinCoreNuResources -j 8`
  completed successfully and bundled only Nu resources.
- `codesign --verify --deep --strict build/nu-qml-arm64-26.6.4y/DefcoinCoreNu.app`
  passed.
- Copied only `Defcoin Core Nu.app` into
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.4y-20260604/`.
- Distribution bundle `codesign --verify --deep --strict` passed.
- Distribution bundle smoke test exited with status 0.

Risks / follow-up:
- Retest with Tahoe serving Lion. Success criteria: Tahoe logs chunk serving or
  no longer logs `non-peer`, and Lion logs accepted UDP blocks/chunks instead of
  Quick Clone timeouts.

### 26.6.4x packaging correction - 2026-06-04 - Explore is separate from Nu distribution

Big picture:
- Defcoin Core Explore is a separate application with its own build thread and
  distribution folder. It can inherit Nu's visible build number, but it should
  not be copied into `Distribution_Versions/Defcoin Core Nu/...` during a
  Nu-only build.
- The current `Nu-26.6.4x-20260604` distribution folder was corrected so it
  contains only `Defcoin Core Nu.app`.

Porting priority:
- Lion Intel: keep Explore out of the Lion Nu distribution folder unless the
  Explore thread explicitly requests an Explore build.
- Catalina UTM: same separation.
- Windows: same separation; Nu setup/portable folders should not contain the
  Explore app.
- Server: no effect.

Changed behavior:
- CMake no longer includes `DefcoinCoreExplore` or `DefcoinCoreExploreResources`
  in the default Nu `ALL` build. Explore remains buildable through explicit
  targets for its own thread.

Changed files and important details:
- `source/src/qt/nu/app/CMakeLists.txt`: `DefcoinCoreExplore` is marked
  `EXCLUDE_FROM_ALL`; `DefcoinCoreExploreResources` is no longer an `ALL`
  custom target.
- `source/src/qt/nu/docs/build-and-installer-runbook.md`: Nu and Explore output
  paths are now separated.

Compatibility notes:
- This is a build/distribution boundary correction only. It does not alter Nu
  runtime behavior, backend behavior, wallet storage, Fast Sync, or Quick Clone.

Build/package notes:
- For Nu-only fixes, build/package `DefcoinCoreNuResources` and copy only
  `Defcoin Core Nu.app`.
- For Explore fixes, the Explore thread should explicitly build
  `DefcoinCoreExploreResources` and stage under `Distribution_Versions/Defcoin
  Core Explore/...`.

Verification performed:
- Removed `Defcoin Core Explore.app` from
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.4x-20260604/`.
- `cmake -S source/src/qt/nu/app -B build/nu-qml-arm64-26.6.4x ...` configured
  successfully after the CMake target change.
- `ninja -C build/nu-qml-arm64-26.6.4x -t query all` now lists
  `DefcoinCoreNu.app/Contents/MacOS/DefcoinCoreNu` and
  `DefcoinCoreNuResources`, with no Explore target in the default `all`
  dependency chain.

Risks / follow-up:
- Existing older Nu distribution folders may still contain historical Explore
  copies. Correct them only when preparing those specific folders for use.

### 26.6.4x - 2026-06-04 - Peer row actions and Quick Clone offline source acknowledgement

Big picture:
- Fix a Metrics > Peers interaction bug where `Retest FastSync` could report
  "Select one peer row first" even when the user had visually selected one row.
- Make Quick Clone receiver state honest when a trusted LAN source disappears:
  a source that times out or cannot receive the UDP request is marked offline
  and removed from active verified source sets until it reappears through a
  later beacon/probe.

Porting priority:
- Lion Intel: port this directly. The user hit the row-selection failure on the
  Tahoe UI, and the same table/action pattern exists in Lion.
- Catalina UTM: port the QML row-key helper and Peer button validation if the
  same QML table is present.
- Windows: port directly so setup/portable builds keep the same peer-action
  behavior.
- Server: no UI port needed. Server Quick Clone/Fast Sync code should use the
  same offline-source demotion if/when it runs receiver-side Quick Clone logic.

Changed behavior:
- `Retest FastSync` and `Ban peer` now call the backend only with one numeric
  node id resolved from the current table rows. Stale or non-row selections no
  longer pass through as invalid ids.
- `NuDataTable.selectedDataRowKeys()` returns selected row keys from real
  current rows and falls back from a selected cell/range to its data row.
- Quick Clone stores the current source host per in-flight request. On timeout
  or send failure, the receiver removes that host from Quick Clone candidate,
  snapshot candidate, UDP available, UDP used, and current target sets, records a
  diagnostic, and reports that the source was marked offline.

Changed files and important details:
- `source/src/qt/nu/qml/Components/NuDataTable.qml`: added
  `selectedDataRowKeys()` helper. It filters row keys against the current sorted
  rows to avoid stale selection keys.
- `source/src/qt/nu/qml/Views/NodeView.qml`: Peer actions now use
  `selectedSinglePeerRowId()` instead of `selectedPeerNodeIds[0]`.
- `source/src/qt/nu/app/NuRpcService.h/.cpp`: added
  `m_lan_fast_sync_current_host` and
  `acknowledgeLanQuickCloneSourceOffline(...)`; Quick Clone timeouts and send
  failures now demote the exact source host.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4x`.
- `source/src/qt/nu/docs/release-notes-26.6.4x.md`: user-facing release notes.

Compatibility notes:
- The Quick Clone change does not alter UDP packet format, service bits, Core
  validation, or wallet data. It is receiver-side source bookkeeping.
- A source can be admitted again when it later sends a beacon/probe response.

Build/package notes:
- Build with `-DDEFCOIN_NU_RELEASE_NAME=26.6.4x`.
- Run resource bundle targets before copying distribution apps; otherwise the
  app can launch with missing splash/QML resources.
- Nu-only fixes should copy only `Defcoin Core Nu.app` into the Nu distribution
  folder. Explore has its own distribution cycle and output folder.

Verification performed:
- `qmllint -I source/src/qt/nu/qml -I build/nu-qml-arm64-26.6.4w/DefcoinCoreNu.app/Contents/Resources/qml source/src/qt/nu/qml/Components/NuDataTable.qml source/src/qt/nu/qml/Views/NodeView.qml` exited 0; it still reports the known local `Defcoin.Nu` import warning.
- `git diff --check` passed.
- `cmake -S source/src/qt/nu/app -B build/nu-qml-arm64-26.6.4x -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 -DQt6_DIR=/opt/homebrew/lib/cmake/Qt6 -DDEFCOIN_NU_RELEASE_NAME=26.6.4x` configured successfully.
- `cmake --build build/nu-qml-arm64-26.6.4x --target DefcoinCoreNu DefcoinCoreExplore -j 8` passed before the Explore distribution boundary correction.
- `cmake --build build/nu-qml-arm64-26.6.4x --target DefcoinCoreNuResources DefcoinCoreExploreResources -j 8` passed before the Explore distribution boundary correction.
- `codesign --verify --deep --strict` passed for the Nu build and distribution app.
- Distribution `Defcoin Core Nu.app/Contents/MacOS/DefcoinCoreNu --smoke-test` exited 0.

Risks / follow-up:
- If a LAN source is temporarily overloaded rather than offline, this build
  still demotes it after the timeout. That is intentional for the current
  trusted-LAN copy flow because another source should be tried promptly.

### 26.6.4w - 2026-06-04 - Shared QML interaction polish

Big picture:
- Broad UI polish pass over shared QML controls rather than per-screen
  redesign. The goal is better perceived quality everywhere with low behavioral
  risk.
- Buttons, nav items, tabs, combo boxes, text fields, and metric rows now have
  smoother hover/focus/press feedback.
- Combo box arrow clicks and keyboard activation are more reliable, which helps
  Wallet selector, Send address book, Mining pool picker, and other drop-downs.
- Metric rows now have a subtle hover surface, improving discoverability of
  dense status/tooltips without taking more vertical space.

Porting priority:
- Lion Intel: port these shared QML component changes unless Qt 5.5/5.6 lacks a
  specific animation or handler. If so, keep the visual intent and simplify the
  animation, not the layout.
- Catalina UTM: port directly if the QML shell matches Tahoe.
- Windows: port directly; this also improves keyboard and drop-down behavior on
  Windows builds.
- Server: no server changes.

Changed behavior:
- `NuActionButton` and `NuNavButton` press with a very small scale animation and
  animate focus/hover colors.
- `NuActionButton` adds a restrained bottom activity line on hover/focus/press.
- `NuComboBox` supports Return/Enter/Space popup toggling and the indicator area
  opens the drop-down reliably.
- `NuTabButton` gets rounded tabs, animated hover/focus colors, and a selected
  bottom rule.
- `NuTextField` animates focus/hover borders.
- `NuMetricRow` is now a small hoverable rectangle with tighter internal spacing.

Changed files and important details:
- `source/src/clientversion.h`: visible release label is `26.6.4w`.
- `source/src/qt/nu/app/CMakeLists.txt`: app bundle release label is
  `26.6.4w`.
- `source/src/qt/nu/qml/Theme/Tokens.qml`: adds `motionFast` and
  `motionNormal` constants for shared animations.
- `source/src/qt/nu/qml/Components/NuActionButton.qml`: hover/focus/press
  motion and bottom affordance.
- `source/src/qt/nu/qml/Components/NuComboBox.qml`: keyboard popup toggle,
  animated chevron, and click target on the indicator.
- `source/src/qt/nu/qml/Components/NuMetricRow.qml`: hover surface and tighter
  row layout.
- `source/src/qt/nu/qml/Components/NuNavButton.qml`: press motion and animated
  hover/focus colors.
- `source/src/qt/nu/qml/Components/NuTabButton.qml`: rounded/animated tab
  treatment and selected rule.
- `source/src/qt/nu/qml/Components/NuTextField.qml`: animated focus/hover
  border.

Compatibility notes:
- No backend, RPC, wallet, or protocol behavior changed.
- If any older Qt target has trouble with grouped-property color animations,
  remove only that animation line; the static states should remain identical.

Build/package notes:
- Rebuild both `DefcoinCoreNu` and `DefcoinCoreExplore` because shared QML assets
  changed.
- On macOS, do not copy the app immediately after building only the executable
  targets. The runnable bundles are produced by `DefcoinCoreNuResources` and
  `DefcoinCoreExploreResources` or by building the default `ALL` target. Copying
  after only `DefcoinCoreNu`/`DefcoinCoreExplore` leaves a binary-only `.app`
  with no `Contents/Resources/nu` payload, which shows a logo-less splash and
  then exits when QML cannot load.

Verification performed:
- `qmllint -I source/src/qt/nu/qml -I build/nu-qml-arm64-26.6.4v/qml
  source/src/qt/nu/qml/Components/NuActionButton.qml
  source/src/qt/nu/qml/Components/NuComboBox.qml
  source/src/qt/nu/qml/Components/NuMetricRow.qml
  source/src/qt/nu/qml/Components/NuNavButton.qml
  source/src/qt/nu/qml/Components/NuTabButton.qml
  source/src/qt/nu/qml/Components/NuTextField.qml
  source/src/qt/nu/qml/Views/HomeView.qml source/src/qt/nu/qml/Main.qml`
  exited successfully. Existing context-property import/unqualified warnings
  remain, but no new syntax or shadowing error was reported for this pass.
- `git diff --check` passed.
- `cmake -S source/src/qt/nu/app -B build/nu-qml-arm64-26.6.4w -G Ninja
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
  -DQt6_DIR=/opt/homebrew/lib/cmake/Qt6
  -DDEFCOIN_NU_RELEASE_NAME=26.6.4w` completed.
- `cmake --build build/nu-qml-arm64-26.6.4w --target DefcoinCoreNu
  DefcoinCoreExplore -j 8` completed.
- `cmake --build build/nu-qml-arm64-26.6.4w --target DefcoinCoreNuResources
  DefcoinCoreExploreResources -j 8` completed and deployed QML/assets, bundled
  backend tools, Qt frameworks/plugins/QML imports, and ad-hoc signing.
- Both app bundles report `CFBundleShortVersionString` and `CFBundleVersion` as
  `26.6.4w`.
- Verified the repaired bundle contains
  `Contents/Resources/nu/assets/brand/defcoin-nu-coin-stack-hires.png`,
  `Contents/Resources/nu/qml/Main.qml`, and
  `Contents/Resources/nu/bin/defcoind`.
- `codesign --verify --deep --strict` passed for both repaired app bundles.
- The repaired distribution `Defcoin Core Nu.app` passed `--smoke-test`.
- Copied Apple Silicon apps to
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.4w-20260604/`.

Risks / follow-up:
- Visual smoke test should click the Wallet selector, Mining pool picker, Send
  address book selector, tabs, and Advanced tools toggle.

### 26.6.4v - 2026-06-04 - Quick Clone warning and streaming scheduler contract

Big picture:
- Quick Clone now has a warning before the manual `Sync using Quick Clone now`
  action arms the feature. The automatic missing-chain prompt already warned
  users; the manual path now carries the same trust/partial-copy warning.
- The authoritative Fast Sync/DCOL spec now defines the Quick Clone receiver
  scheduler: receiver-controlled, two ranges in flight per source at startup,
  replenish only after streaming checksum success, retry timed-out ranges from
  another compatible source, and send best-effort cancel messages for stale
  requests.
- The checksum direction is intentionally speed-first: no paranoid UI mode.
  Quick Clone should use one deterministic streaming checksum family and update
  it while bytes are already being read/written.
- This build still does not install copied chainstate. It defines the contract
  and UI warning while preserving the manifest gate added in 26.6.4u.

Porting priority:
- Lion Intel: port the manual Quick Clone warning dialog and the documentation
  contract. Do not add a second competing clone implementation.
- Catalina UTM: port the warning dialog if the QML Settings surface exists.
- Windows: port the warning dialog; Windows wording can mention firewall if a
  later build adds a platform-specific prompt.
- Server: update docs only. The server should not advertise Quick Clone snapshot
  availability until it can create immutable manifests.

Changed behavior:
- Clicking `Sync using Quick Clone now` opens a selectable warning first.
- The warning states that Quick Clone is trusted-LAN only, copies public
  blockchain data only, partial copies are not usable chain state, and final
  install requires staged-copy verification and a backend restart/swap.
- Automatic Quick Clone prompt text also says partial clones are not usable and
  snapshot replacement is gated by manifest plus streaming-checksum checks.

Changed files and important details:
- `source/src/clientversion.h`: visible release label is `26.6.4v`.
- `source/src/qt/nu/app/CMakeLists.txt`: app bundle release label is
  `26.6.4v`.
- `source/src/qt/nu/qml/Views/SettingsView.qml`: manual Quick Clone button now
  opens `quickCloneStartDialog`; accept calls `NuService.syncUsingQuickCloneNow`.
- `source/src/qt/nu/app/NuRpcService.cpp`: automatic prompt and user message
  include partial-copy and streaming-checksum warnings.
- `source/src/qt/nu/docs/fast-sync-protocol.md`: adds the receiver scheduler
  and streaming checksum contract.

Compatibility notes:
- Existing Fast Sync packet transport remains unchanged in this pass.
- The active snapshot mover remains blocked until immutable source manifests and
  receiver staging/install code exist.

Build/package notes:
- Rebuild both `DefcoinCoreNu` and `DefcoinCoreExplore` because the shared
  service and QML Settings surface changed.

Verification performed:
- `git diff --check` passed.
- `qmllint -I source/src/qt/nu/qml -I build/nu-qml-arm64-26.6.4v/qml
  source/src/qt/nu/qml/Views/SettingsView.qml source/src/qt/nu/qml/Main.qml`
  completed with the existing context-property warnings and no syntax errors.
- `cmake -S source/src/qt/nu/app -B build/nu-qml-arm64-26.6.4v -G Ninja
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
  -DQt6_DIR=/opt/homebrew/lib/cmake/Qt6 -DDEFCOIN_NU_RELEASE_NAME=26.6.4v`
  configured successfully.
- `cmake --build build/nu-qml-arm64-26.6.4v --target DefcoinCoreNu
  DefcoinCoreExplore -j 8` passed.
- `plutil -p build/nu-qml-arm64-26.6.4v/DefcoinCoreNu.app/Contents/Info.plist`
  and the matching Explore bundle both reported `CFBundleShortVersionString`
  and `CFBundleVersion` as `26.6.4v`.
- Copied both apps to
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.4v-20260604/`.

Risks / follow-up:
- Implement the actual staged snapshot transfer only after source manifests,
  range checksums, cancel messages, and atomic receiver swap are present.

### 26.6.4u - 2026-06-04 - Quick Clone menu surface and validation guardrails

Big picture:
- The visible trusted-LAN copy concept is now **Quick Clone**. DCOL / Direct
  Copy Over LAN remains the technical name in help text and developer docs.
- The previous visible `LAN Fast Copy` wording has been removed from the app
  surface. Existing internal member names such as `lanQuickCloneEnabled` remain
  implementation scaffolding for now to keep the Tahoe/Lion diff smaller.
- Quick Clone is treated as a trusted-LAN public-chain workflow. It must never
  copy wallets, private keys, passphrases, config files, peers, bans, address
  books, or RPC cookies.
- The destructive snapshot install step is intentionally gated by future
  manifest/export proof. This build adds the menu surface, prompt cycle,
  manual arming action, and Core `verifychain` validation action without
  allowing a live `chainstate` folder to be copied unsafely.

Porting priority:
- Lion Intel: port the same Settings > Connectivity card, signal/property
  surface, prompt-cycle logic, and `verifychain` button. Keep any Lion-specific
  UDP transport fixes intact.
- Catalina UTM: same UI/API port if the QML Nu shell is present.
- Windows: same user-facing naming and validation controls; platform firewall
  messaging remains Windows-specific where applicable.
- Server: no server change required for this UI pass. Server Fast Sync remains
  transport-only and should not advertise Quick Clone/DCOL snapshot availability
  until immutable manifest exports exist.

Changed behavior:
- Settings > Connectivity now has a **Quick Clone** card with:
  `Allow Quick Clone from trusted LAN nodes`, `Automatically validate blocks
  after Quick Clone`, `Sync using Quick Clone now`, and
  `Validate existing blockchain`.
- `Validate existing blockchain` runs Core RPC `verifychain 4 0` and reports
  success, failure, or unsupported backend state without touching wallet files.
- A Quick Clone prompt can be emitted once per missing-chain cycle when LAN
  discovery is enabled, the node is more than 5% behind, and a LAN Nu candidate
  has been seen. If rejected, it does not nag again until the node catches up
  below the 5% threshold and later falls behind again.
- Metrics remains read-only. It can show Quick Clone status and validation
  status, but does not expose Quick Clone controls.

Changed files and important details:
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4u`.
- `source/src/qt/nu/app/NuRpcService.h/.cpp`: added Quick Clone auto-validate
  property, validation status/running state, prompt signal, prompt-cycle helper
  methods, `syncUsingQuickCloneNow()`, `acceptQuickClonePrompt()`,
  `declineQuickClonePrompt()`, and `validateExistingBlockchain()`.
- `source/src/qt/nu/qml/Views/SettingsView.qml`: replaced the old LAN Fast
  Copy checkbox with a Quick Clone card and manual validation controls.
- `source/src/qt/nu/qml/Main.qml`: added a selectable/copyable Quick Clone
  prompt dialog with `Use Quick Clone` and `Keep normal sync`.
- `source/src/qt/nu/docs/fast-sync-protocol.md`,
  `source/src/qt/nu/docs/defcoin-core-nu-goals.md`, and
  `source/src/qt/nu/docs/functionality-map.md`: updated the conceptual
  boundary so Quick Clone is the only visible name and DCOL is the technical
  manifest-gated snapshot workflow.

Compatibility notes:
- Existing settings key `LanQuickCloneEnabled` is preserved so current users do
  not lose their preference during the rename.
- The current UDP block-body code still submits assembled blocks through Core
  validation. A true validation-bypass Quick Clone must wait for immutable
  source exports plus manifest/hash verification before replacing any public
  chain directories.
- Quick Clone remains LAN/trusted-owner only. Public internet Fast Sync stays
  separate and validation-preserving.

Verification performed:
- `git diff --check` passed.
- `cmake -S source/src/qt/nu/app -B build/nu-qml-arm64-26.6.4u -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 -DQt6_DIR=/opt/homebrew/lib/cmake/Qt6 -DDEFCOIN_NU_RELEASE_NAME=26.6.4u` configured successfully.
- `cmake --build build/nu-qml-arm64-26.6.4u --target DefcoinCoreNu -j 8` passed.
- `cmake --build build/nu-qml-arm64-26.6.4u --target DefcoinCoreExplore -j 8` passed because the shared `NuRpcService` changed.
- `plutil -p build/nu-qml-arm64-26.6.4u/DefcoinCoreNu.app/Contents/Info.plist` reported `CFBundleShortVersionString=26.6.4u` and `CFBundleVersion=26.6.4u`.
- `qmllint` on the touched QML files completed without syntax errors. It still reports the known context-property/unqualified-access warnings for `NuService`, `NuPlatform`, and build metadata, which predate this change.

Risks / follow-up:
- Implement immutable source export advertisements:
  manifest id, source height, best block hash, complete file list, byte sizes,
  per-file hashes, and export status.
- Implement receiver staging and atomic replacement only after the receiver
  backend is stopped and the manifest verifies.
- Do not allow any `blocks`, `chainstate`, or `indexes` replacement without the
  manifest gate.

### server-fast-sync-20260604 - 2026-06-04 - dc903 responder parity with current Fast Sync probes

Big picture:
- The public dc903 Fast Sync responder was updated to match the current Nu
  requester wire behavior. Current wallets probe first; a server that only
  accepts old `request-block` packets will stay stuck at `Advertised` or
  `Probe sent`.
- This is a server-side deployment plus protocol-doc update, not a new desktop
  version bump.

Porting priority:
- Lion Intel: ensure the Lion requester expects `probe -> probe-ack` before
  block requests and continues using service bit 29, not User-Agent text, for
  capability.
- Catalina UTM: same as Lion if Fast Sync is present there.
- Windows: same requester behavior as Tahoe; do not special-case server peers.
- Server: deploy `source/src/qt/nu/tools/defcoin_fast_syncd.py` when the
  requester protocol changes; do not leave the server on an older responder.

Changed behavior:
- The server sidecar now answers `probe` packets with `probe-ack`.
- Server authorization is based on connected Core TCP peers advertising
  `NODE_DEFCOIN_FASTSYNC` in `getpeerinfo.services`; User-Agent is diagnostics
  only.
- The sidecar remains responder-only. It does not request blocks from clients,
  does not bypass validation for clients, and does not change legacy v1.0.x TCP
  behavior.

Changed files and important details:
- `source/src/qt/nu/docs/fast-sync-protocol.md`: added a server feature parity
  section and deployment checks requiring loopback probe and block request
  verification.
- `/usr/local/sbin/defcoin-fast-syncd` on dc903: replaced with the current
  Tahoe Nu script. Remote backup:
  `/usr/local/sbin/defcoin-fast-syncd.bak-20260604-122130`.
- `/Volumes/TB5_4TB/d/litecoincore/Defcoin Core Nu/local-dev-notes/SERVER_CHANGELOG.md`:
  local operational server changelog updated.
- `/Volumes/TB5_4TB/server_backups/dc903_dfc_2026-04-15/REMOTE_FINDINGS_2026-04-15.txt`:
  live server evidence trail updated.

Compatibility notes:
- Public server requests are capped to internet-safe datagram sizing unless the
  requester is private/local.
- Older Defcoin Core peers do not advertise bit 29 and are therefore never
  placed in the UDP allowlist.

Verification performed:
- `python3 -m py_compile source/src/qt/nu/tools/defcoin_fast_syncd.py` passed.
- Remote service restart passed; `defcoind`, `p2pool-defcoin`, and
  `defcoin-fast-syncd` were active.
- `ss -lunp` showed UDP listeners on `0.0.0.0:10334` and `[::]:10334`.
- Remote loopback probe returned `probe-ack`, then block 1 with matching chunk
  and whole-block SHA-256 checksums.
- Public Tahoe probe to `defcoin.dc903.org:10334` returned `probe-ack`, then
  block 1 with matching checksums.
- TCP communication checks succeeded for Core P2P `10332`, P2Pool `1337`, and
  `https://defcoin.dc903.org/pool`.

Risks / follow-up:
- A real wallet should still be observed accepting at least one server-sourced
  UDP block during IBD before calling public Fast Sync fully proven.
- The server backend still reports `/DefcoinCoreNu:26.6.1/`; that does not
  block the responder sidecar, but a future server-core upgrade should keep the
  Fast Sync service bit and RPC behavior aligned with Tahoe.

### 26.6.4t - 2026-06-04 - LAN Fast Copy naming, Metrics row density, macOS bundle metadata

Big picture:
- This build separates three concepts that had drifted together in the UI:
  Fast Sync, LAN Fast Copy, and Quick Clone/DCOL.
- Fast Sync remains a transport-only path. It must not skip Core validation.
- LAN Fast Copy is the current online LAN block-copy mode. It pauses ordinary
  P2P on the receiver and requests checksum-protected block bytes from trusted
  LAN Nu peers, but still submits each block through Core acceptance.
- Quick Clone is now reserved as the human-friendly name for DCOL, a future
  trusted-LAN snapshot workflow intended to bypass historical validation by
  copying verified public chain state. Quick Clone/DCOL is not implemented in
  this build.
- The Metrics Status table now sizes one-line rows compactly while still
  allowing wrapped rows to grow.
- Apple Silicon macOS app bundles now stamp explicit macOS metadata to avoid
  System Information misclassifying builds.

Porting priority:
- Lion Intel: port the user-facing naming and docs concepts where the Lion UI
  exposes this setting. Do not rename backend internals mechanically unless the
  Lion source is already being touched for nearby reasons.
- Catalina UTM: port the naming, Metrics table row-height behavior if that UI
  exists, and the macOS bundle metadata pattern. Choose a deployment target that
  honestly matches the Qt libraries used by Catalina, not Tahoe's `26.0`.
- Windows: port naming and Metrics row-density behavior. The macOS plist work is
  not relevant.
- Server: no immediate code change from this entry. Server docs should preserve
  the same distinction: Fast Sync is transport-only; Quick Clone/DCOL is future
  snapshot copy.

Changed behavior:
- Settings no longer says `Quick Clone blocks from trusted LAN peers`; it says
  `LAN Fast Copy from trusted peers`.
- Metrics no longer labels the row `Quick Clone (LAN)`; it labels it `LAN Fast
  Copy`.
- Runtime status text now says LAN Fast Copy for the current validated LAN block
  transfer path.
- Quick Clone/DCOL is documented as future validation-bypass snapshot mode,
  limited to `blocks`, `chainstate`, and optional `indexes`; it must never copy
  wallets, keys, settings, peers, ban files, or RPC cookies.
- Metrics Status rows with one line of text no longer use the old fixed wrapped
  row height.

Changed files and important details:
- `source/src/clientversion.h`: visible backend/client label is `26.6.4t`.
- `source/src/qt/nu/app/NuRpcService.cpp` and `.h`: user-visible strings were
  renamed from Quick Clone to LAN Fast Copy. Internal member names such as
  `m_lan_quick_clone_status` intentionally remain for now to avoid a noisy
  refactor.
- `source/src/qt/nu/qml/Views/SettingsView.qml`: checkbox text and hover help
  explain that LAN Fast Copy still uses Core acceptance and that Quick
  Clone/DCOL is future work.
- `source/src/qt/nu/qml/Components/NuDataTable.qml`: row height calculation now
  accepts row data and estimates wrapped text lines from column widths. This is
  why one-line Status rows shrink but long rows can still wrap.
- `source/src/qt/nu/qml/Views/NodeView.qml`: Status table sets
  `wrapBodyText: true`, `maxWrappedBodyLines: 3`, and `compact: true`.
- `source/src/qt/nu/docs/fast-sync-protocol.md`: now defines Fast Sync, LAN
  Fast Copy, and Quick Clone/DCOL as separate mechanisms.
- `source/src/qt/nu/docs/defcoin-core-nu-goals.md`: goal 8 was updated to keep
  those concepts distinct.
- `source/src/qt/nu/app/MacOSXBundleInfo.plist.in`: new explicit macOS plist
  template. It sets `CFBundleSupportedPlatforms=MacOSX`,
  `LSApplicationCategoryType=public.app-category.finance`, high-resolution
  capable flags, and `LSMinimumSystemVersion`.
- `source/src/qt/nu/app/CMakeLists.txt`: both Nu and Explore targets use the
  custom plist template. The default Tahoe deployment target is `26.0` because
  Homebrew Qt 6.11.1 on Tahoe has QtQuick frameworks stamped with `minos 26.0`.

Compatibility notes:
- The Tahoe default `CMAKE_OSX_DEPLOYMENT_TARGET=26.0` is correct for Tahoe's
  current Homebrew Qt package set, but it is not a universal recommendation.
  Lion and Catalina must use Qt libraries built for their target OS and set the
  deployment target to match those libraries.
- If a cross-build uses older Qt libraries with lower `minos`, it should pass an
  explicit `CMAKE_OSX_DEPLOYMENT_TARGET` for that platform instead of inheriting
  Tahoe's default.
- The macOS `Kind: iOS` concern should be investigated by checking plist keys
  and Mach-O load commands, not by guessing from Qt Creator alone:
  `CFBundleSupportedPlatforms`, `LSMinimumSystemVersion`, `LSRequiresIPhoneOS`,
  `UIDeviceFamily`, `DTPlatformName`, and `vtool -show-build`.

Build/package notes:
- Tahoe build directory used for verification:
  `build/nu-qml-arm64-26.6.4t`.
- Staged app:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.4t-20260604/Defcoin Core Nu.app`.
- Qt Creator was installed but no project-local `.user` kit file or saved kit
  config was found. The verified CMake cache/build metadata is the source of
  truth for this build.

Verification performed:
- Backend tools report `v26.6.4t`:
  `defcoind`, `defcoin-cli`, `defcoin-tx`, and `defcoin-wallet`.
- `git diff --check` passed before commit.
- Nu app smoke launch passed with `DEFCOIN_NU_NO_BACKEND_AUTOSTART=1` and
  `--smoke-test --route metrics`.
- Codesign verification passed:
  `codesign --verify --deep --strict --verbose=2`.
- Plist checks on the staged app showed:
  `CFBundleSupportedPlatforms=MacOSX`,
  `LSMinimumSystemVersion=26.0`,
  `CFBundlePackageType=APPL`,
  `CFBundleShortVersionString=26.6.4t`.
- Spotlight metadata showed:
  `kMDItemKind=Application`,
  `kMDItemCFBundleIdentifier=org.defcoincore.DefcoinCoreNu`,
  `kMDItemExecutableArchitectures=(arm64)`.
- `vtool -show-build` showed platform `MACOS` for app and bundled Qt binaries.
  No iOS-only plist keys were found.

Risks / follow-up:
- LAN Fast Copy still validates blocks, so it will not deliver the full speed
  gain expected from Quick Clone/DCOL. Implement DCOL later as a stopped-backend
  or coherent-snapshot copy of public chain state.
- The row-height calculation uses rough text-width estimation. If a future QML
  table uses unusual icons or custom delegates, verify row picking and scrolling.
- If future Homebrew Qt changes its deployment target again, rerun the plist and
  `vtool` checks rather than hard-coding assumptions.

## 26.6.4ak - 2026-06-05 - Fast Sync reservation parity audit

Scope:
- Tahoe and Lion now use the same lower-level Fast Sync reservation rule:
  UDP is only a transport option after Core has selected a peer/block through
  normal peer state.
- The old Lion-only header-chain/local-block fallback scheduler was removed.

Protocol behavior:
- `reservefastsyncblock transport-verified <nodeid>` only marks UDP transport
  as proven for that peer.
- `reservefastsyncblock reserve-next <nodeid>` now relies on
  `ProcessBlockAvailability()`, `pindexBestKnownBlock`, and
  `FindNextBlocksToDownload()`.
- If Core has no eligible block, the call reports a Core-derived reason such as
  `peer-best-block-unknown`, `waiting-for-block-window`, or
  `no-downloadable-block`.
- `submitblock` result `inconclusive` is treated as validation-still-running,
  not a hard UDP transfer failure.

Cross-build note:
- Port the backend reservation function as a unit. Do not re-add independent
  Fast Sync height scanning on Lion or Catalina.

## 26.6.4al - 2026-06-05 - Fast Sync self-address guard

Scope:
- Added a self-address exclusion to Fast Sync candidate collection.
- This prevents a NATed test VM from making the host see an inbound peer as the
  host's own LAN IP and then probing itself over UDP.

Protocol behavior:
- The node may still answer valid UDP probe/request packets arriving from LAN
  peers.
- The node no longer adds its own interface address to the outbound UDP Fast
  Sync / Quick Clone candidate set.

Verification:
- Tahoe and Lion backend reservation function bodies diff clean.
- Both builds advertise service bit 29 / `DEFCOIN_FASTSYNC`.
- Lion UTM successfully received a `probe-ack` and a `block-chunk` from Tahoe
  using the framed `DFCLAN1` UDP packet format.

## 26.6.4ao - 2026-06-05 - TCP-off launch mode for UDP testing

Scope:
- Added `--debug-disable-core-tcp-sync` and
  `DEFCOIN_NU_DEBUG_DISABLE_CORE_TCP_SYNC=1`.
- The switch disables Core TCP block-body fetches only. Header sync, peer
  negotiation, service-bit discovery, and Core reservation logic remain active.
- Superseded by 26.6.4aq: `--debug-disable-core-sync` is no longer treated as
  the TCP-only test alias. Use `--debug-disable-core-tcp-sync` for UDP Fast Sync
  isolation.

Cross-build note:
- Use this mode to isolate UDP Fast Sync. Total Core sync shutdown is for
  Quick Clone/DCOL tests only.

## 26.6.4ap - 2026-06-05 - UDP-only selector in TCP-off test mode

Scope:
- When Core TCP block copy is disabled by debug launch switch, Tahoe and Lion
  now force UDP quota whenever at least one Fast Sync peer is visible.
- Removed the selector-side update of the global probe timestamp before a probe
  is actually sent in this debug mode.
- Added throttled `UDP target selection empty` diagnostics with peer, verified,
  used, failed, and debug-mode counts.

Cross-build note:
- If a legacy build sees service bit 29 but sends no UDP probe, compare its
  selector and target-selection logic against this release before touching the
  backend reservation RPC.

## 26.6.4aq - 2026-06-05 - Split Core TCP-off from Core P2P-off

Scope:
- `--debug-disable-core-tcp-sync` now disables only Core TCP block-body fetching.
- `--debug-disable-core-sync` now disables Core P2P sync and is reserved for
  Quick Clone/DCOL isolation tests.
- Tahoe and Lion both pass `-defcoindisablecoretcpblocks=1` when either switch
  is active, but only the full Core Sync switch passes `-networkactive=0`.

Cross-build note:
- UDP Fast Sync tests should use
  `--debug-disable-core-tcp-sync --debug-disable-quick-clone`.
- In that mode, backend launch args must include `-networkactive=1` so peer
  negotiation, header sync, service bit 29, and Core reservation state remain
  alive while TCP block bodies are suppressed.

## 26.6.4bn - 2026-06-09 - UDP Fast Sync LAN pacing and source stats

Scope:
- Clean Tahoe-to-Lion testing with the current `26.6.4bm` builds and Tahoe's
  macOS Local Network prompt allowed proved that UDP Fast Sync can deliver
  accepted blocks while Core TCP block-body fetching is disabled on Lion.
- The remaining slowness was not raw LAN throughput. Lion accepted UDP blocks
  through Core validation, but the frontend mostly waited for each
  `submitblock` call before reserving the next block.
- Tahoe now computes the next not-yet-pending UDP height and, for verified LAN
  targets or UDP-only tests, asks Core to reserve that exact height. This keeps
  the existing UDP ready-block cache useful while validation finishes earlier
  blocks.

Protocol behavior:
- Fast Sync remains validation-preserving. It still calls Core
  `reservefastsyncblock` before sending a UDP request and still submits raw
  blocks through Core `submitblock`.
- This is not Quick Clone/DCOL and does not bypass validation.
- Public/non-LAN mode can still use Core's `reserve-next` path. The direct
  height reservation is used for private/LAN or explicit UDP-only test cases.
- Metrics now expose UDP block source counts: successful source hosts, attempted
  source hosts, failed source hosts, and served source hosts.

Cross-build note:
- Port `nextLanFastSyncWantedHeight()`, the relaxed submit-in-flight tick gate,
  and the direct LAN/test reservation call as a unit.
- On Lion, make the same changes in `src/qt/nu/legacy-osx107/main.cpp`.
- A correct UDP-only test launch is:
  `--debug-disable-core-tcp-sync --debug-disable-quick-clone`.
- A clean test must use the current Tahoe and Lion builds and Tahoe's first-run
  Local Network prompt must be allowed before interpreting any UDP failure.

## 26.6.4bo - 2026-06-09 - Metrics detail filtering and Peers switch polish

Scope:
- Replaced the Peers `Simple | Detailed` segmented control with a compact
  `Details` switch on Tahoe and Lion.
- Added the same `Details` switch to `Metrics > Status`.
- Status rows now have an explicit normal-vs-detail classification. The default
  non-detailed view shows the primary sync/transport/traffic/chain rows; the
  detailed view adds selector internals, probe status, backend paths, launch
  defaults, chain tips, and P2P message breakdowns.
- Removed the full TCP/UDP method summary from the `Syncing` row to avoid
  duplicating the dedicated Core Sync, Fast Sync, and Sync overview rows.

Lion performance note:
- The Lion Qt 5.5 Metrics route now refreshes only the visible Metrics tab.
  Entering Metrics no longer preloads Status, Log, Peers, and banned-peer
  tables together.
- Lion `populateDiagnosticsStatus()` now exits when Status is not visible and
  skips table rebuild/autofit work when the visible row signature has not
  changed.

Cross-build note:
- Tahoe implements detail filtering through `meta.detail` on `nodeMetrics` rows.
- Lion implements the same concept with a local `StatusRow { metric, value,
  detail }` list before writing the `QTableWidget`.
- Keep the row order consistent: Syncing, Sync overview, Core Sync (TCP), Fast
  Sync (UDP), Quick Clone (LAN UDP), Traffic, Network active, Connections,
  Blocks, Headers, Verification, followed by detail-only rows.

## 26.6.4bp - 2026-06-09 - UDP transport verification survives peer id churn

Scope:
- Tahoe-to-Lion testing with current `26.6.4bo` showed that macOS LAN UDP was
  no longer the immediate blocker: Tahoe received and acknowledged UDP probes
  from Lion.
- The failing state was lower level. Lion's Core peer for Tahoe changed from an
  IPv4 node id to an IPv6 node id after the probe path had verified transport.
  `reservefastsyncblock reserve-next <nodeid>` then returned
  `fast-sync-udp-transport-unverified` for the new live node id.
- A manual `reservefastsyncblock transport-verified <nodeid>` immediately made
  Core willing to reserve the next block, proving the reservation path was sound
  and the frontend had failed to re-apply verification to the current node id.

Implementation:
- Added `m_udp_fast_sync_core_verified_node_ids` to remember live Core node ids
  that have already accepted `transport-verified`.
- During `getpeerinfo` refresh, Nu now intersects that cache with live node ids,
  then re-applies `transport-verified` for any currently connected host that is
  already in the frontend's UDP-available or UDP-used host sets.
- `setUdpFastSyncPeerTransportVerified()` updates the cache only after Core
  reports success, preventing repeated duplicate verification RPCs.

Cross-build note:
- Port the header member and both `NuRpcService.cpp` changes exactly to Lion.
- This is required for both UDP Fast Sync and Quick Clone because both rely on
  Core's per-node `fFastSyncUdpTransportVerified` gate before block
  reservations.

## 26.6.4bv - 2026-06-09 - Lion UDP scheduler parity

Scope:
- Tahoe `26.6.4bu` already allowed UDP Fast Sync to keep reserving/requesting
  future block bodies while Core was validating the current staged block.
- Physical Lion still had an older `m_lanFastSyncSubmitInFlight` early return
  in `lanFastSyncTick()`, so it usually kept only one UDP block active and did
  not fill the in-flight/cache window during validation.

Implementation:
- Remove the submit-in-flight early return from Lion
  `src/qt/nu/legacy-osx107/main.cpp::lanFastSyncTick()`.
- Keep the reserve-in-flight and buffer-cap checks in place. This preserves
  Core reservation ordering while allowing UDP prefetch to overlap Core
  validation.

Cross-build note:
- Tahoe already has this behavior in `NuRpcService::lanFastSyncTick()`.
- If future branch diffs reintroduce a submit-in-flight return before
  `requestLanFastSyncBlock()`, UDP-only LAN tests will appear to work but will
  run far below the intended in-flight window.

## 26.6.4bw - 2026-06-09 - Lion explicit LAN Fast Sync reservations

Scope:
- Tahoe label moves to `26.6.4bw`.
- Lion alpha label moves to `26.6.4bw-Lion-alpha`.
- Lion Fast Sync now matches Tahoe's LAN-only benchmark behavior by asking
  Core to reserve an explicit missing LAN height when Core TCP block copying is
  disabled or the target is a LAN/private Fast Sync peer.
- Public/non-LAN Fast Sync still uses Core's normal `reserve-next` scheduling.

Implementation:
- Port Tahoe's `hasLanFastSyncPendingHeight()` and
  `nextLanFastSyncWantedHeight()` helper logic into
  `src/qt/nu/legacy-osx107/main.cpp`.
- In Lion `requestLanFastSyncBlock()`, choose `reserve <node> <height>` for
  LAN/private or Core-TCP-disabled test runs, and keep `reserve-next <node>` for
  ordinary public mode.
- Preserve the existing single reserve-RPC guard and buffer caps; this changes
  the selected height, not Core validation or consensus acceptance.

Test focus:
- Relaunch Tahoe and Lion with:
  `--debug-disable-core-tcp-sync --debug-disable-quick-clone --debug-fast-sync-lan-only`.
- Clear only Lion's public chain folders before the run.
- Confirm Lion logs `NU_UDP_FASTSYNC_REQUEST`, `NU_UDP_FASTSYNC_STAGED`, and
  `NU_UDP_FASTSYNC_ACCEPTED`, with active requests rising above the old mostly
  one-at-a-time pattern.
