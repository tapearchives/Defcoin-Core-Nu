# Defcoin Core Nu Changelog

## 26.6.8l-alpha Core Memories

Defcoin Core Nu `26.6.8l-alpha` is a Tahoe Mining > Pools and Benchmark
Pools table/report polish build over the active `26.6.8-alpha` line.

- Corrects the `pool.defcoin.fun` preset and auto-detection label from `NOMP`
  to `UNOMP`, including existing saved `.fun` rows.
- Fixes reusable table Shift-click range selection so clicking one cell and
  then Shift-clicking the opposite corner immediately selects the full cell
  range across tables.
- Strengthens Mining > Pools drag-to-reorder feedback with open/closed hand
  cursors, row-target highlighting, and more reliable drag capture from the
  No. column.
- Decimal-aligns Benchmark Pools result columns that show decimal values by
  using fixed precision in the numeric table cells.
- Reworks the saved benchmark PNG into `Defcoin Core Nu's Pool Benchmark` with
  a centered title, auto-fitted one-line legend, footer-based run summary,
  `Conducted on` timestamp, and clearer fairness explanation. The dashed
  average overlays are restored with labels placed to the right of the averaged
  bars.
- For benchmark runs with more than three passes per pool, writes the main PNG
  as a full-width accepted-work comparison and saves hashrate/HTTPing
  diagnostics to a separate `*-diagnostics.png` sidecar file.

## 26.6.8k-alpha Core Memories

Defcoin Core Nu `26.6.8k-alpha` is a Tahoe Mining > Benchmark Pools countdown
correction build over the active `26.6.8-alpha` line.

- Keeps the idle `Time left` display aligned with the current per-pool,
  cycle, and pool-count fields instead of showing a stale ETA loaded from a
  previous benchmark artifact.
- Removes the fixed ten-second-per-pool backend ETA padding so the live
  countdown starts from configured pool runtime and adds only observed restart
  overhead once restart samples exist.
- Moves the live cycle/status text into the Benchmark Pools control row after
  `Time left`, reserves that row space while idle, removes the thick progress
  divider, tightens the seconds/cycles fields, and keeps the action buttons
  right-aligned on the same row.
- Adds a compact `Diff` result column for total accepted share difficulty,
  expands Work/s hover/chart notes to explain that the fairer speed score sums
  accepted `Submitted Diff` values per second, uses a conservative
  target-equivalent fallback only for accepted shares without a matched
  difficulty row, and places chart average labels to the right of each averaged
  bar group so labels do not collide with candles.

## 26.6.8j-alpha Core Memories

Defcoin Core Nu `26.6.8j-alpha` is a Tahoe Mining > Pools and Benchmark
Pools table/chart polish build over the active `26.6.8-alpha` line.

- Restores Mining > Pools to Nu's reusable selectable/copyable/sortable table
  component, while preserving drag-to-reorder from the No. column.
- Tightens table auto-fit padding and shrink-to-content sizing so pool preset
  and benchmark tables do not leave blank trailing columns or unnecessary
  scrollbars when the content fits.
- Lowers the benchmark minimum per-pool runtime to 10 seconds, clamps lower
  entries to that value, and fixes the estimated runtime math to reflect pool
  time instead of adding a large fixed overhead per run.
- Removes the retired `cpu.defcoin.host:13370` preset and shortens unknown
  backend labels to `Unk. stratum`.
- Reworks the 1920x1080 benchmark chart: one-line legend, larger/sharper text,
  accepted work/s chart occupying the full left side, hashrate top-right,
  endpoint latency bottom-right, and per-bar plus average value labels.

## 26.6.8i-alpha Core Memories

Defcoin Core Nu `26.6.8i-alpha` is a Tahoe Mining > Pools and Benchmark
Pools polish build over the active `26.6.8-alpha` line.

- Changes the benchmark fair-comparison metric back to accepted work per
  second and scales the display by 1,000,000 so values are readable while still
  using accepted share difficulty over elapsed seconds.
- Enlarges the Benchmark Pools chart preview, removes the restart column, moves
  hashrate and endpoint-latency units into table headers, and shortens
  sub-minute durations.
- Makes Mining > Pools presets reorderable by dragging the No. column and adds
  optional per-pool payout address/password overrides that inherit the general
  mining settings when left blank.
- Stops redacting the miner launch `-p` argument in the Monitor log because
  Stratum pools usually treat it as a dummy worker password.
- Replaces the Stratum benchmark probe with a TCP-connect latency check only,
  avoiding invalid HTTP bytes on Stratum ports such as `pool.defcoin.io:4044`.

## 26.6.8h-alpha Core Memories

Defcoin Core Nu `26.6.8h-alpha` is a Tahoe Mining > Pools and benchmark
latency polish build over the active `26.6.8-alpha` line.

- Adds an editable Mining > Pools preset table with separate pool name,
  stratum address, and pool software fields.
- Persists custom pool presets through Nu settings, with add, update, remove,
  use-selected, and reset-defaults actions.
- Migrates the Defcoin Host CPU/USB/ASIC P2Pool presets to IP-based stratum
  endpoints while keeping the human-readable host:port pool names.
- Replaces the benchmark subprocess ping call with a built-in Qt HTTPing-style
  TCP endpoint probe so the packaged app does not depend on command-line ping.

## 26.6.8g-alpha Core Memories

Defcoin Core Nu `26.6.8g-alpha` is a Tahoe mining benchmark polish build over
the active `26.6.8-alpha` line.

- Removes the restart-time graph from Mining > Benchmark Pools PNG output,
  leaving accepted work/ms, hashrate, and ping.
- Changes the benchmark fair-comparison metric display from work/s to work/ms
  while keeping compatibility fields in saved JSON.
- Removes pool numbers and per-pool numeric labels from the chart and legend.
- Places the preview chart to the right of a compact benchmark table, removes
  the Status display column, and keeps the whole result grid easier to scan.
- Pings only the bare stratum host name, not the host plus port.

## 26.6.8f-alpha Core Memories

Defcoin Core Nu `26.6.8f-alpha` is a Tahoe mining monitor and benchmark polish
build over the active `26.6.8-alpha` line.

- Changes Mining Monitor wording from Follow tail to Output focus and Recent
  Logs to Top to Latest output on top.
- Keeps the Mining Monitor view anchored where the user is reading unless
  Output focus is enabled.
- Adds monotonic miner-output line numbers that continue past the 4K-line
  rolling buffer limit.
- Makes Mining Benchmark results selectable, copyable, sortable, and clearer
  about Pool No., Pool software, ping failures, completion time, and accepted
  work/s caveats.
- Regenerates benchmark charts as 1920x1080 bar charts with readable numeric
  labels, average markers, log-scale fallback for extreme ranges, and no raw
  accepted-shares comparison chart.
- Groups the Defcoin Host CPU/USB/ASIC P2Pool presets together and adds the
  Defcoin.io solo mining preset.
- Reuses the last export folder across Nu export/save dialogs.
- Passes the saved Defcoin user-agent filtering preference to the managed
  backend so non-Defcoin peers are rejected when filtering is enabled.

## 26.6.8e-alpha Core Memories

Defcoin Core Nu `26.6.8e-alpha` is a wallet, mining, networking, and packaging
polish release over the public `26.6.8-alpha` line.

- Rebuilds the current Tahoe and Windows packages from a Nu-only source tree
  after removing stale sibling-product source, assets, changelog entries, and
  packaging rules from this repository.
- Refreshes the Defcoin Core Nu logo, splash, About panel, app icon, and DMG
  presentation so the visible brand system uses one locked Nu identity.
- Expands Wallets with clearer wallet status columns, address counts, better
  create-wallet validation, passphrase visibility controls, BIP39 phrase
  creation, phrase restore progress, and SQL descriptor restore options.
- Restores the Debug Log surface with line-numbered viewing, filtering, find,
  copy, save, and open-log controls.
- Adds the `explorer.defcoin.fun` external block explorer preset and preserves
  separate transaction and address custom URL templates.
- Improves Paper Wallet rendering, BIP38 import handling, and key-generation
  guardrails while keeping private key material local and transient.
- Improves peer inspection, LAN workstation naming, seed-source attribution,
  Quick Clone controls, UDP Fast Sync status wording, and sync-path statistics.
- Improves Mining Monitor behavior with follow-tail controls, visible log
  buffering limits, accepted/share rate display, and an experimental pool
  benchmarking workflow.
- Updates the macOS, Windows, and Lion build surfaces toward parity for wallet
  tables, Metrics ordering, hover text, RPC Console behavior, and advanced
  tooling.
- Documents known experimental areas in release notes: Quick Clone, UDP Fast
  Sync, and Mining Pool Benchmarking still need focused verification before
  being described as stable.

## 26.6.7 Core Memories

Defcoin Core Nu `26.6.7` focused on release readiness and cross-platform polish.

- Reworked logo spacing, coin/text ratios, splash/About/menu usage, and Finder
  icon sizing for the Nu app.
- Improved Wallets table layout, responsive button wrapping, visible scroll
  hints, copyable table fields, and wallet action wording.
- Added and refined Messages signing guidance, paper-wallet design controls,
  peer traceroute tooling, and Debug Log placement.
- Hardened shutdown messaging so users can see backend and helper-process
  cleanup progress.
- Brought Tahoe, Windows, and Lion builds closer to visible feature parity.

## 26.6.5 Core Memories

Defcoin Core Nu `26.6.5` focused on startup, UI resilience, and packaging.

- Improved frontend launch behavior, splash visibility, and startup diagnostics.
- Tightened Metrics and peer display copy so sync and network state are easier
  to interpret.
- Continued packaging fixes for app metadata, bundled backend tools, Qt runtime
  dependencies, and platform-specific launch behavior.

## 26.6.4 Core Memories

Defcoin Core Nu `26.6.4` focused on Fast Sync, Quick Clone, and Python tooling.

- Clarified Fast Sync transport rules: Core reserves the peer/block pair first,
  then UDP may carry only the reserved block body.
- Tightened Fast Sync service-bit, probe/ack, reservation, and checksum logging.
- Added local macOS Local Network permission testing helpers for LAN UDP work.
- Added Python formatting and lint settings for Nu helper scripts.
- Improved peer filtering, LAN discovery, and workstation-name enrichment while
  keeping consensus validation in the backend.

## 26.6.3 Core Memories

Defcoin Core Nu `26.6.3` focused on LAN discovery and Fast Sync peer discovery.

- Added explicit Nu LAN announcement beacons for workstation name, Nu build,
  P2P port, and Fast Sync port.
- Queued valid local beacon senders through `addnode host:1337 add` after RPC
  readiness so LAN wallets are more likely to become real P2P peers.
- Kept UDP discovery separate from Fast Sync negotiation and block acceptance.
- Rejected pseudo workstation names and raw network artifacts while preserving
  fallback discovery through local network metadata.
- Ensured display-only workstation lookup failures do not disqualify normal P2P
  or Fast Sync probing.

## 26.6.2 Core Memories

Defcoin Core Nu `26.6.2` focused on URL handling, UI clarity, and package
staging.

- Tightened external block explorer URL validation and error reporting.
- Improved Settings copy for external transaction/address explorer templates.
- Hardened app launch, link opening, help opening, and clipboard feedback.
- Improved packaging folder naming, Qt runtime deployment, and macOS bundle
  staging.
- Continued UI fixes for wrapped text, tables, scroll regions, and advanced
  tools.

## 26.6.1 Core Memories

Defcoin Core Nu `26.6.1` focused on the new Nu Qt Quick wallet shell.

- Introduced the Home, Send, Receive, Transactions, Wallet, Mining, RPC
  Console, Metrics, and Settings surfaces.
- Added bundled backend autostart, RPC connection handling, launch diagnostics,
  and current-launch log viewing.
- Added LAN node discovery, UDP Fast Sync, Quick Clone scaffolding, and clearer
  peer/network metrics while keeping normal Core validation authoritative.
- Added wallet basics including receive requests, transaction inspection, PSBT
  tools, message signing, wallet backup, encryption, and external explorer
  links.
- Added Paper Wallet generation and local QR rendering without sending private
  key material through RPC.
