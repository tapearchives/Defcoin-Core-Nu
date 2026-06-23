# Defcoin Core Nu Cross-Build Change Log

This ledger tracks Nu wallet changes that must stay aligned across Tahoe,
Lion/Catalina, and Windows builds. Keep entries Nu-only: sibling products,
screenshots, packaging artifacts, and roadmap notes do not belong in this
repository unless explicitly requested for a Nu release.

## Current Public Boundary

- The Nu repository builds and packages `DefcoinCoreNu` only.
- Nu release artifacts live under `Distribution_Versions/Defcoin Core Nu/...`.
- External block explorer URLs are settings-controlled browser links only; no
  sibling product is bundled into Nu.
- Wallet, node, mining, Metrics, RPC Console, Debug Log, Fast Sync, Quick
  Clone, and packaging changes must be ported or intentionally documented for
  each supported platform.

## Entries

### 26.6.8l-alpha - 2026-06-23 - Mining benchmark table and report polish

Big picture:
- Keep Mining > Pools and Benchmark Pools interactions predictable while making
  the saved benchmark report more production quality.

Changed behavior:
- `pool.defcoin.fun` is labeled `UNOMP` in defaults, auto-detection, and
  normalized saved rows.
- Reusable table Shift-click range selection now lets a first normal cell click
  establish the anchor, then a Shift-click on the opposite corner select the
  full rectangular range immediately.
- Mining > Pools drag-to-reorder uses open/closed hand cursor feedback, target
  row highlighting, and drag capture from the No. column.
- Benchmark result columns that display decimals use fixed precision so the
  right-aligned monospace table cells decimal-align cleanly.
- The 1920x1080 benchmark PNG uses a centered `Defcoin Core Nu's Pool
  Benchmark` title, auto-fitted one-line legend, footer summary/timestamp, and
  clearer fairness wording. Dashed average overlays are restored.
- When a benchmark has more than three runs for a pool, the main chart becomes
  a full-width accepted-work comparison and a `*-diagnostics.png` sidecar holds
  hashrate and HTTPing charts.

Porting notes:
- Windows and Lion ports should take the `NuDataTable` Shift-click/reorder
  behavior together with the Mining > Pools/Benchmark Pools QML and service
  chart changes.

### 26.6.8k-alpha - 2026-06-23 - Mining benchmark countdown correction

Big picture:
- Keep Benchmark Pools runtime labels internally consistent for short test
  runs.

Changed behavior:
- The idle `Time left` label now mirrors the current configured estimate
  instead of showing the ETA value from a previously loaded benchmark artifact.
- The running backend ETA no longer adds a fixed ten-second-per-pool latency
  padding; it starts from configured pool time and adds observed restart
  overhead only after restart samples exist.
- Benchmark Pools moves the live cycle/status text into the control row after
  `Time left`, keeps that row reserved while idle, removes the thick progress
  divider, tightens the seconds/cycles fields, and keeps action buttons aligned
  on the same row.
- Benchmark result rows include a compact `Diff` column for total accepted
  share difficulty. Work/s tooltips and the PNG note explain that the fairer
  score sums accepted `Submitted Diff` values per second, scales by 1,000,000,
  and only uses conservative target-equivalent minimum fallback when an accepted
  share lacks a matched difficulty row.
- The PNG chart positions per-pool average labels to the right of the averaged
  bar group so labels do not collide with individual candle/bar values.

Porting notes:
- Windows and Lion mining benchmark ports should use the same idle/live split:
  idle labels come from current fields, live labels come from backend progress.
- Ports should preserve the accepted difficulty `Diff` column, Work/s
  explanation text, conservative unmatched-accept fallback, and average-label
  clearance behavior.

Verification targets:
- `git diff --check`.
- Focused Mining > Benchmark Pools launch check shows matching idle runtime and
  time-left values.

### 26.6.8j-alpha - 2026-06-23 - Tahoe mining pool table and chart fit polish

Big picture:
- Bring the Tahoe Mining > Pools table back onto the reusable Nu table
  component and make the benchmark chart/table layout fit the data instead of
  leaving empty frames.

Changed behavior:
- Mining > Pools now uses `NuDataTable`, restoring selectable cells, drag
  ranges, copy-to-clipboard, and sortable columns. Dragging the No. column
  still reorders saved presets.
- Table auto-fit padding is tighter and shrink-to-content mode avoids blank
  trailing columns and unnecessary scrollbars when a table already fits.
- Benchmark per-pool runtime clamps at 10 seconds, and the estimated runtime is
  based on configured pool seconds times cycles and pools rather than a large
  fixed overhead.
- The retired `cpu.defcoin.host:13370` preset is removed from defaults and
  migrated saved presets; unknown pool software displays as `Unk. stratum`.
- Benchmark charts keep a one-line legend, larger text, a full-height accepted
  work/s panel on the left, hashrate on the upper right, endpoint latency on the
  lower right, and readable labels for each bar and each pool average.

Porting notes:
- Windows and Lion should carry the reusable-table shrink/reorder behavior,
  default-preset migration, 10-second benchmark minimum, and chart layout when
  the mining benchmark view is ported.

Verification targets:
- `git diff --check`.
- Tahoe app bundle metadata and bundled backend tools report the same
  `26.6.8j-alpha` label.
- Focused Mining > Pools and Benchmark Pools launch check passes on Tahoe.

### 26.6.8i-alpha - 2026-06-23 - Tahoe mining pool benchmark and preset polish

Big picture:
- Make the Tahoe pool benchmark easier to read and avoid sending invalid
  protocol traffic to Stratum servers before mining starts.

Changed behavior:
- Mining > Benchmark Pools now displays accepted work per second scaled by
  1,000,000 instead of work/ms. The raw sortable metric remains accepted share
  difficulty divided by elapsed seconds, so larger values are still better and
  different pool share difficulty is normalized.
- Benchmark result rows no longer show a Restart column. Hashrate and endpoint
  latency units live in wrapped headers, sub-minute durations display as
  seconds, numeric columns align more tightly, and the preview chart is much
  larger beside the table.
- Mining > Pools presets can be reordered by dragging the No. column. Presets
  now also support optional per-pool payout address and password fields; blank
  values inherit the general mining payout/password.
- The miner Monitor log shows the actual `-p` argument in the launch command.
- The benchmark latency check now performs a ten-try TCP connect check only. It
  no longer sends an HTTP HEAD request to Stratum ports, which can confuse or
  trip servers such as `pool.defcoin.io:4044`.

Porting notes:
- Windows and Lion should carry the same pool-preset schema, monitor log, and
  TCP-only latency probe in their next parity build.

Verification targets:
- `git diff --check`.
- Tahoe app bundle metadata and bundled backend tools report the same
  `26.6.8i-alpha` label.
- Focused Mining > Pools, Monitor, and Benchmark Pools launch check passes on
  Tahoe.

### 26.6.8h-alpha - 2026-06-23 - Tahoe mining pool preset table and HTTPing probe

Big picture:
- Make Mining > Pools a real editable preset table and remove the benchmark
  dependency on system ping binaries.

Changed behavior:
- Mining > Pools now shows saved presets in a table with separate Pool name,
  Stratum address, and Pool software columns.
- Users can add, update, remove, use, and reset pool presets; the list is saved
  in Nu settings and restored on launch.
- Defcoin Host CPU/USB/ASIC presets keep readable `*.defcoin.host:port` names
  but use the requested IP stratum endpoints:
  `135.148.43.187:13370`, `135.148.43.188:13371`, and
  `135.148.43.189:13372`.
- Mining benchmark latency checks now use an internal ten-try HTTPing-style Qt
  TCP connection probe against the stratum endpoint instead of launching
  `/sbin/ping` or `ping`.

Porting notes:
- Windows and Lion should carry the same service property, QML table, preset
  migration, and internal HTTPing probe in their next parity build.

Verification targets:
- `git diff --check`.
- Tahoe app bundle metadata and bundled backend tools report the same
  `26.6.8h-alpha` label.
- Focused Mining > Pools and Benchmark Pools launch check passes on Tahoe.

### 26.6.8g-alpha - 2026-06-23 - Tahoe mining benchmark work/ms polish

Big picture:
- Tighten the Tahoe Mining > Benchmark Pools result view so the data table and
  chart preview fit together on the screen while keeping the fair-comparison
  metric readable.

Changed behavior:
- Benchmark PNGs now use three panels only: accepted work/ms, hashrate, and
  ping. The restart-time graph is removed.
- Pool numbers are no longer printed in the chart legend or pool labels, and
  per-pool numeric bar labels are removed from the chart body.
- Benchmark result rows use accepted share difficulty per millisecond
  (`work/ms`) instead of per second, and the JSON keeps both per-second and
  per-millisecond fields for compatibility.
- The table preview sits to the left of the chart preview, uses compact
  auto-fit columns, and no longer displays the Status column.
- Benchmark ping uses the bare stratum host name without the pool port.

Porting notes:
- Windows and Lion should carry the same QML and `NuRpcService` changes in
  their next parity build.

Verification targets:
- `git diff --check`.
- Tahoe app bundle metadata and bundled backend tools report the same
  `26.6.8g-alpha` label.
- Focused Mining > Benchmark Pools launch check passes on Tahoe.

### 26.6.8f-alpha - 2026-06-23 - Tahoe mining monitor and benchmark polish

Big picture:
- Refine the Tahoe Mining > Monitor and Benchmark Pools surfaces before the
  next Mac test build.
- Preserve the expectation that Windows and Lion receive these shared-source
  changes in their next parity build, while this pass stages Tahoe only.

Changed behavior:
- Mining Monitor uses `Output focus` and `Latest output on top` wording. New
  miner output no longer jumps the view unless Output focus is enabled, and
  latest-output-on-top no longer disables or hides the focus control.
- Miner output lines show monotonic total line numbers, even after the rolling
  4K-line buffer drops old content.
- Benchmark results use a selectable, copyable, sortable table with Pool No.,
  Pool software, completion timestamps, and tooltips that explain pool metrics.
- Benchmark chart generation produces 1920x1080 bar-chart PNGs, removes raw
  accepted-shares as a cross-pool comparison chart, emphasizes accepted
  share-difficulty work/s, avoids exponent labels, marks pool averages, and
  switches to log scale for radically different values.
- Export dialogs reuse the last successful export directory across chart,
  stats, wallet, PSBT, traffic, and transaction exports.
- Managed backend startup now passes the saved Defcoin user-agent filtering
  flag explicitly, matching the frontend setting and preventing non-Defcoin
  peers from being accepted when filtering is enabled.

Porting notes:
- The QML and `NuRpcService` changes are shared source and should be carried
  into the next Windows and Lion builds with the same visible behavior.

Verification targets:
- `git diff --check`.
- Tahoe app bundle metadata and bundled backend tools report the same
  `26.6.8f-alpha` label.
- Focused Mining > Monitor and Benchmark Pools launch checks pass on Tahoe.

### 26.6.8e-alpha - 2026-06-22 - Nu-only release boundary and Windows parity

Big picture:
- Carry the active Tahoe alpha work forward after removing stale sibling-product
  source, assets, screenshots, changelog entries, and packaging rules from the
  Nu repository.
- Produce a matching Windows 11 x86_64 build from the same Nu-only source state.

Porting notes:
- Windows must package only `DefcoinCoreNu` resources and must not carry
  non-Nu QML, data files, icons, screenshots, or release notes.
- Tahoe and Windows visible labels, About/build metadata, bundled backend tools,
  portable ZIP names, installer names, and checksum assets should all use
  `26.6.8e-alpha`.

Verification targets:
- `git diff --check`.
- Tahoe app bundle metadata and bundled backend tools report the same
  `26.6.8e-alpha` label.
- Nu Apple Silicon app and DMG verify locally.
- Windows setup and portable ZIP contain only Nu app/runtime files and no
  source companion docs or Finder metadata.

### 26.6.8d-alpha - 2026-06-22 - Mining pool benchmarking

Big picture:
- Add a Tahoe Mining > Benchmark Pools tab for comparing saved preset/custom
  mining pools with repeated timed runs.

Changed behavior:
- The benchmark reuses saved miner settings, cycles through preset pools plus a
  distinct custom pool, pings each host before mining, records hashrate, raw
  accepted shares, accepted share-difficulty work/s, ping, and restart timing,
  and autosaves latest plus timestamped JSON/PNG chart artifacts.
- Pool comparison uses accepted work/s rather than raw accepted share count
  because pools may assign different share difficulty.
- The live benchmark line shows current pool elapsed time and time left, while
  the summary uses `Time left` instead of ETA wording.

Porting notes:
- Windows builds need the same bounded miner-log parser, accepted-rate mast
  field, and benchmark chart/stat persistence.

### 26.6.8c-alpha - 2026-06-22 - LAN peer polish and scoped IPv6 discovery

Big picture:
- Keep peer-table grouping readable without corrupting Core peer ids, and keep
  LAN discovery usable on dual-stack networks where macOS advertises scoped
  IPv6 link-local addresses.

Changed behavior:
- LAN discovery beacons include usable IPv6 link-local addresses with scope ids,
  and Tahoe sends discovery to IPv6 all-nodes multicast in addition to IPv4
  broadcasts.
- Core P2P addnode attempts skip scoped IPv6 link-local endpoints that Core
  cannot route reliably, while Nu UDP can still probe and request Quick Clone
  data from those addresses.
- Quick Clone wait text identifies the receiver-local backend scheduling or
  peer-identification gate instead of saying "waiting for Core peer selection".
- Peer table grouping stays display-only: the Node column remains Core's raw
  numeric peer id and same-node groups are shown in the source/workstation
  column as `G1: Name`.

Porting notes:
- Port the Nu LAN behavior together across Tahoe, Windows, and Lion. IPv6
  link-local scope ids must be preserved for Nu UDP discovery, probes, and
  Quick Clone requests, IPv6 all-nodes multicast should be joined/sent per
  active interface, and scoped link-local endpoints must not be handed to Core
  `addnode`.

### 26.6.8a-alpha - 2026-06-21 - SQL descriptor managers and Lion parity fixes

Big picture:
- New SQL descriptor wallets should be structurally ready for every Defcoin
  descriptor type the current code can parse and store, without making future
  paths active before they are supported in the product.

Changed behavior:
- Newly created SQLite descriptor wallets store active external/internal P2PKH,
  P2SH-SegWit, and Bech32 managers plus inactive reserved MWEB receive/change
  descriptors.
- Missing inactive manager lookups return `nullptr` silently instead of writing
  scary debug-log noise for every absent output type.

Porting notes:
- Port the wallet changes together across Tahoe, Lion, and Windows backend
  trees: `wallet.cpp`, `scriptpubkeyman.cpp`, and `scriptpubkeyman.h`.

### 26.6.8-alpha - 2026-06-20 - Nu alpha release rollup

Big picture:
- Visible Nu release label advances from the local `26.6.7z` candidate line to
  `26.6.8-alpha`.
- This alpha consolidates superseded 26.6.x local candidate notes into a
  release-test line for the Nu wallet.
- Known experimental areas remain Fast Sync, Quick Clone/DCOL, and Mining Pool
  Benchmarking.

Changed behavior:
- Wallets tab adds richer wallet table stats, create/restore refinements,
  passphrase validation, BIP39 phrase creation/restore, optional SQL descriptor
  recovery, watch-only address tools, and message-signing guidance.
- Paper Wallet supports local entropy collection, BIP38 handling, preview,
  pop-out review, print controls, and Design 1 polishing.
- RPC Console includes the restored Debug Log tab with line numbers, filters,
  find, copy, save, open-log, and font-size controls.
- Settings > Display includes external blockchain explorer presets and separate
  transaction/address custom URL templates.
- Peer, seed, Trippy, LAN discovery, UDP Fast Sync, Quick Clone, shutdown, and
  mining monitor UI were tightened for clearer status and cross-platform parity.
- Nu branding uses the locked DEFCOIN / CORE NU logo ratios for splash, About,
  navigation, icons, and DMG artwork.

### 26.6.7p - 2026-06-17 - Nu bundle pruning

- Nu staging removes source-only `.agent.md` companion notes from the runtime
  bundle.
- Generated Finder/Python/Ruff cache files and stale paper-wallet placeholder
  art were removed from the active Nu source tree.
- The staged Nu bundle was verified to exclude `.agent.md` files, `.DS_Store`,
  and stale placeholder images.
