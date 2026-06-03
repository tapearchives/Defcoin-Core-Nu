# Defcoin Core Changelog

## 26.6.4a Core Memories

Defcoin Core Nu `26.6.4a` is a Fast Sync protocol and Python tooling update
over `26.6.3l`.

- Clarifies the simplified Fast Sync transport rule: Core reserves the
  peer/block pair first, then UDP may carry only that reserved block body.
- Tightens the headless Fast Sync sidecar wording and logging around
  `NODE_DEFCOIN_FASTSYNC`; User-Agent text is no longer treated as a
  compatibility or authorization signal.
- Adds Ruff configuration plus editor on-save settings for Python formatting
  and automatic safe fixes.
- Runs Ruff formatting across the Nu Python Fast Sync and macOS bundle-repair
  helpers.

## 26.6.3l Core Memories

Defcoin Core Nu `26.6.3l` is a Nu Explore UI polish update over
`26.6.3k`.

- Treats a loaded Droid Trails cache as a healthy mast state, so cached
  Coindroids analysis no longer appears as an inactive grey indicator.
- Adds a compact Fit action to the embedded and pop-out Movement Map controls
  for resetting dragged node positions and rerunning the graph layout.

## 26.6.3k Core Memories

Defcoin Core Nu `26.6.3k` is a Nu Explore UI polish update over
`26.6.3j`.

- Moves Droid Trails Refresh, Pop out, and PDF actions into the page header so
  the loaded status line and story body can use the full content width.
- Brings the published Coindroids anchor table higher in the Droid Trails story
  before lower-priority explanatory footnotes.
- Reduces the embedded Movement Map default to a more readable `Top 15` graph
  and shortens/clamps address labels so edge nodes do not clip their labels.
- Lowers the initial Movement Map node scale and gives the embedded graph more
  usable vertical bounds so the first view settles into multiple readable lanes.
- Adds a shutdown guard to `NuDataTable` repeaters so smoke exits do not log
  row/cell delegate incubation warnings.

## 26.6.3j Core Memories

Defcoin Core Nu `26.6.3j` is a Nu Explore UI polish update over
`26.6.3i`.

- Compacts the Network Pulse embedded view by moving chart/sample controls into
  the header action area.
- Gives the Network Pulse history table a stable minimum height so the table
  remains useful on standard laptop and 1080p displays.
- Aligns the Network Pulse pop-out with the embedded view and adds a direct
  status-copy action.

## 26.6.3i Core Memories

Defcoin Core Nu `26.6.3i` is a Nu Explore Network Pulse update over
`26.6.3h`.

- Adds recent average block time to the mast beside hashrate and difficulty.
- Adds a Network Pulse Analyze section with selectable history charts for
  estimated hashrate, difficulty, and sampled block spacing.
- Builds Network Pulse history from the existing Explorer block index, with
  block-linked table rows and a pop-out chart.

## 26.6.3h Core Memories

Defcoin Core Nu `26.6.3h` is a Nu Explore Coindroids readability update over
`26.6.3g`.

- Removes hard height caps from Coindroids header, status, and pop-out
  narrative text so wrapped text remains visible and selectable.
- Makes the Coindroids tab body and each Coindroids pop-out scroll safely when
  long notes, chart captions, or tables exceed the current window height.
- Adds full-value hover text for compact metric rows and truncated data-table
  headers/cells, preserving table density while keeping the hidden text
  readable on demand.

## 26.6.3g Core Memories

Defcoin Core Nu `26.6.3g` is a Nu Explore Droid Trails and Relationship Graph
UI update over `26.6.3f`.

- Removes the Explorer index status panel from Analyze views while preserving it
  on Index Engines.
- Moves the Droid Trails PDF action and tab bar up under the section header.
- Makes Coindroids story text selectable and makes the main Pop out action
  follow the selected Droid Trails tab.
- Treats Olo as the eighth named DC25 lead.
- Adds table-scoped Chart Relationships actions for Coindroids address tables.
- Rebuilds relationship graph sizing from indexed contact balances/received
  value, with draggable nodes and flow-scaled edges.

## 26.6.3f Core Memories

Defcoin Core Nu `26.6.3f` is a Nu Explore Coindroids DC25 forensics update over
`26.6.3b`.

- Adds bundled DC25 attack-address, QR seed, source/ammo, and Olo candidate
  forensics derived from the 2026-06-03 Coindroids CSV reports.
- Adds a DC25 Attack Chain story tab with an interactive chart, hover details,
  explorer-linked rows, and a dedicated pop-out chart.
- Adds prebuilt Coindroids Contact Sets for QR Seeds, Attack Cohort,
  Source Ammo, Olo Tentative, and the combined DC25 Investigation set.
- Adds story buttons that load those Contact Sets and open the Relationship
  chart.
- Bundles the placeholder Coindroids forensics story PDF and opens it through
  the macOS default PDF app.

## 26.6.3b Core Memories

Defcoin Core Nu `26.6.3b` is a Nu Explore contact-set update over `26.6.3a`.

- Adds named Contact Sets to Nu Explore Contacts so different wallet-address
  cluster lists can be loaded for Relationship graphing.
- Adds create/load/save-as/rename/delete controls and a saved-set table in the
  Contacts view.
- Migrates existing single-list Explore contacts into a `Default` set and keeps
  the older settings snapshot synchronized for compatibility.
- Saves manual contact edits and Coindroids game-address imports into the
  active Contact Set before rebuilding the relationship graph.

## 26.6.3a Core Memories

Defcoin Core Nu `26.6.3a` is a LAN discovery and Fast Sync peer-discovery
compatibility pass over `26.6.2i`.

- Adds explicit Nu LAN announcement beacons on the UDP Fast Sync port so Tahoe
  and Lion-era Nu wallets can advertise a non-sensitive workstation name,
  Nu build, P2P port, and Fast Sync port.
- Queues `addnode host:1337 add` for valid private/local beacon senders after
  backend RPC is ready, improving the chance that LAN wallets become actual P2P
  peers instead of merely being reachable over UDP.
- Keeps Fast Sync negotiation separate from beacon discovery: UDP block
  requests still require connected peer state, the Fast Sync service bit, and a
  successful probe/probe-ack exchange.
- Rejects pseudo workstation names such as `broadcasthost`, raw IP literals,
  loopback, multicast, and broadcast artifacts, while falling back to the older
  Bonjour/SMB/NetBIOS/ARP/NDP/nmap metadata path when a node does not announce
  a clean name.
- Ensures ambiguous workstation-name lookup failures are display-only and do
  not disqualify a peer from normal P2P or Fast Sync probing.

## 26.6.2i Core Memories

Defcoin Core Nu `26.6.2i` is a Movement Map stability and load-time pass over
`26.6.2h`.

- Tightens Movement Network node collision spacing so large adjacent nodes do
  not cover each other's fitted amount labels.
- Uses a more conservative fitted-font calculation for large rounded DFC values
  inside graph circles.
- Gives the graph layout more room for address labels anchored below circles.
- Reduces movement analytics load time by using the indexed high-value-output
  path for the 5,000 interactive rows, then decorating only graph-relevant rows
  with source address endpoints.
- Avoids the expensive full grouped transaction scan during movement loading;
  the table and graph sort the loaded threshold sample in the UI.
- Caps Movement Network density at `Top 50` so the force graph remains readable
  and interactive.

## 26.6.2h Core Memories

Defcoin Core Nu `26.6.2h` is a Movement Map legibility and interaction pass
over `26.6.2g`.

- Anchors movement node addresses below circles instead of drawing them inside
  the node.
- Renders each node's plotted DFC amount inside the circle as a rounded whole
  number with `.-` suffix, using a per-node fitted font size.
- Increases the default node scale and adds node-scale sliders to the Movement
  Map and Movement Network popout.
- Strengthens the minimum blue edge visibility and adds directional arrowheads
  to movement links.
- Colors nodes by plotted flow role: yellow net sender, green net receiver, and
  blue mixed/relay.
- Expands hover text with plotted flow, inbound/outbound totals, connection
  count, and drag/click guidance.

## 26.6.2g Core Memories

Defcoin Core Nu `26.6.2g` is a Droid Trails chart usability pass over
`26.6.2f`.

- Reworks the Droid Trails chart popout to fit a 1920x1080 screen without
  pushing the window table off screen.
- Adds a large-number chart legend for candidate outputs, 0.1337 swarm outputs,
  and 0.01 action outputs.
- Adds hover detail text for DEF CON Coindroids windows, including block range,
  dates, DFC totals, transaction counts, address counts, and swarm outputs.
- Adds click-to-zoom drilldown for each DEF CON window, with an All windows
  reset control.
- Lets the Droid Trails window table double-click into the same chart drilldown.

## 26.6.2f Core Memories

Defcoin Core Nu `26.6.2f` is an Explore distribution and Droid Trails clarity
pass over `26.6.2e`.

- Stops creating `BUILD_STAGED_AT.txt` during macOS distribution staging.
- Flattens Defcoin Core Nu Explore distribution builds to one top-level folder
  layer and keeps build folder names in the
  `Defcoin-Core-Nu-Explore-v26.n.n[a]-YYYYMMDD` format.
- Stabilizes visible mast status labels so rapidly changing backend/index
  details do not make the top status text unreadable.
- Reorders Droid Trails to lead with the Coindroids story: candidate DFC sent,
  strongest DEF CON window, published largest payout, launch-swarm winner, and
  swarm totals.
- Clarifies that the published `ModemBot1138 - 100.0605 DFC` payout and the
  local-chain launch-swarm winner around `12.97 DFC` are different
  measurements.
- Rebuilds the Apple Silicon Qt shell against Qt `6.11.1` and installs the
  missing Vulkan headers so CMake no longer emits the `WrapVulkanHeaders`
  discovery warning during Nu configuration.

## 26.6.2e Core Memories

Defcoin Core Nu `26.6.2e` is a focused hardening pass over `26.6.2d`.

### Hardened

- Custom explorer URL templates are now saved and enabled only when they are
  valid http(s) templates with exactly one `%s` placeholder and no embedded
  credentials.
- External explorer and help links now report failed launches instead of
  silently ignoring system-open failures.
- Sensitive clipboard copy paths now enforce a size cap before copying.
- UDP Fast Sync datagrams now reject empty/invalid datagrams, invalid reply
  ports, malformed hashes/checksums, and non-hex block payloads earlier in the
  transport path before Core validation is reached.

## 26.6.2d Core Memories

Defcoin Core Nu `26.6.2d` is a packaging verification and wallet-shell
usability pass over `26.6.2c`.

- Auto-detects the local Defcoin backend binary during Qt packaging so Apple
  Silicon builds include the optimized `defcoind` backend instead of shipping a
  GUI-only bundle when the CMake option is omitted.
- Keeps the matching bundled CLI alongside the backend when available.
- Clarifies Settings > Explorer Links so local lookups are described as opening
  the separate Defcoin Core Nu Explore app, while external explorer choices open
  the system browser.

## 26.6.2c Core Memories

Defcoin Core Nu `26.6.2c` is an Explore usability and Droid Trails refinement
pass over `26.6.2b`.

- Fixes Explorer index status priority so a completed local Explorer cache shows
  green instead of being held red by stale status text.
- Bumps the Droid Trails cache schema and adds block-date ranges, rounded DFC
  display values, stronger summary metrics, and explicit DEF CON 23/24 windows.
- Reuses matching Droid Trails DB rows by schema version, instead of forcing a
  fresh Coindroids rebuild whenever the Explorer index advances by a few blocks.
- Updates DEF CON Droid Trails labels with main venues and marks DEF CON 28 as
  `DEF CON 28 Safe Mode [Virtual Event]`.
- Removes the duplicate Forensics tab strip because the left Explore rail owns
  those sections.
- Stabilizes Movement Network layout by removing per-paint force settling and
  keeping separate state for inline and pop-out canvases.

## 26.6.2b Core Memories

Defcoin Core Nu `26.6.2b` is a security hardening pass over `26.6.2a`.

- Routes QML external-link opens through a shared C++ URL validator that allows
  only valid `http://` and `https://` links without embedded credentials.
- Adds a generic clipboard guard that blocks phrase-like BIP39 recovery text
  unless the user has gone through the explicit clipboard warning dialog.
- Tightens UDP Fast Sync request handling by requiring the protocol request ID
  to match Nu's 32-character hexadecimal format.
- Renames the Explore product surface to `Defcoin Core Nu Explore` for app
  display, bundle metadata, installer naming, and distribution folders.
- Removes duplicate mid-screen Explorer section tabs now that the Explore left
  rail owns the section navigation.
- Fixes Holder Atlas pie percentages against indexed supply, renders the
  Supply Bands and Whale Lens pies as hollow-center charts, and adds maximized
  pop-out windows for Explorer visualizations.
- Makes Movement Map nodes draggable and clickable so plotted addresses can
  open through the selected internal or external Explorer target.
- Makes address and transaction-hash table cells Explorer-linkable across shared
  data tables.

## 26.6.2a Core Memories

Defcoin Core Nu `26.6.2a` is a usability polish pass over `26.6.2`.

- Adds a persistent `Advanced tools` toggle to the left navigation rail so
  everyday wallet actions stay visible by default while Mining, Diagnostics,
  and Settings can be shown when needed.
- Keeps top-menu access to advanced pages and automatically reveals the
  advanced rail when those menu items are used.
- Replaces developer shorthand such as `TBA` and `TCP/Core` in peer and Fast
  Sync status text with clearer user-facing wording.
- Adds the Explore `Droid Trails` analysis surface for Coindroids-era Defcoin
  token flows, including DEF CON window summaries, action endpoint candidates,
  the 0.13370000 DFC payout/spillage swarm, winner rows, and detection-rule
  evidence.

## 26.6.2 Core Memories

Defcoin Core Nu `26.6.2` tightens Fast Sync diagnostics and peer display after
the `26.6.1` letter builds.

- Separates public UDP Fast Sync eligibility from LAN discovery permission:
  peers must advertise `NODE_DEFCOIN_FASTSYNC` before Nu sends UDP block-data
  requests, while LAN discovery remains limited to local peer/name discovery.
- Removes the separate detailed Peers `LAN` column and shows the LAN icon inline
  before the workstation/source name instead.
- Adds LAN workstation source hover text so the detailed Peers table can show
  whether the LAN name came from Bonjour, SMB/NetBIOS, host-name resolution, or
  related local probes.
- Updates visible splash/About wording to say the backend derives from Litecoin
  Core v0.21.5.5 while keeping Defcoin-specific network and consensus
  parameters.

## 26.6.1d Core Memories

Defcoin Core Nu `26.6.1d` is a packaging correction over `26.6.1c`.

- Renamed the former Defcoin Core ExpFor app to Defcoin Core Explore across the
  app bundle, executable, bundle identifier, installer naming, and Explore
  wordmark.
- Added Explorer cache count metadata and additional SQLite indexes for richer
  holder and movement tallying without repeated full-table counts.
- Fixed Apple Silicon distribution staging so the final `.app` includes the Qt
  platform plugin and focused runtime plugin set, preventing launch crashes
  caused by a missing `libqcocoa.dylib`.
- Keeps the bundled Qt framework install-name repair and detailed Peers table
  fixes from the prior `26.6.1` letter builds.

## 26.6.1c Core Memories

Defcoin Core Nu `26.6.1c` is a packaging correction over `26.6.1b`.

- Fixed Apple Silicon distribution staging so app bundles run only against
  bundled Qt frameworks, preventing launch crashes from mixed Homebrew/bundled
  Qt loads.
- Carries the detailed Peers table alignment and workstation de-duplication
  fixes from `26.6.1b`.

## 26.6.1b Core Memories

Defcoin Core Nu `26.6.1b` is a small diagnostics polish rebuild over
`26.6.1a`.

- Fixed conditional alignment in the detailed Peers table so LAN workstation
  names in `Seed Source / LAN Workstation Name` align left, while non-LAN seed
  and DNS source values remain right-aligned.

## 26.6.1a Core Memories

Defcoin Core Nu `26.6.1a` is a Tahoe polish rebuild over `26.6.1`.

### Changed

- Improved LAN workstation-name display by preferring human-readable Macintosh
  share names, removing source-label prefixes, and de-duplicating equivalent
  Bonjour, SMB, and NetBIOS identities.
- Updated Nu combo boxes so clicking anywhere in the displayed text opens the
  pick list, matching normal desktop combo-box behavior.
- Adjusted the macOS DMG background label backplates to sit under Finder icon
  text on the dark theme background.

## 26.6.1 Core Memories

Defcoin Core Nu `26.6.1` improves Apple Silicon validation performance and
modern-machine initial sync behavior while preserving the inherited Core client
build identity.

### Added

- Added Apple Silicon SHA256 acceleration using Bitcoin Core-derived ARM SHA2
  intrinsics for SHA256 and SHA256D64.
- Added automatic Nu-managed backend `-dbcache` sizing from available RAM when
  `defcoin.conf` does not already specify a cache value.
- Added release-note coverage for the Apple Silicon benchmark and server
  compatibility verification.

### Changed

- Raised the 64-bit `-dbcache` maximum to `32768` MiB.
- Updated the dc903 server-visible subversion label to `/DefcoinCoreNu:26.6.1/`
  while preserving the existing Fast Sync and witness compatibility services.

### Verified

- On a Mac Mini M4 Pro, the SHA256D64 validation-style benchmark measured
  `1232.94 MiB/s` with the ARM SHA2 path versus `187.53 MiB/s` with the generic
  path, a `6.6x` improvement, with matching output checksum
  `118af3313ef2c383` over the same 1 GiB workload.
- The backend startup log selects `arm_shani(1way,2way)` on Apple Silicon.

## 26.5.5w Core Memories

Defcoin Core Nu `26.5.5w` adds the first Forensics view for average users who
want to explore permanent OP_RETURN blockchain oddities without using RPC.

### Added

- Added a Forensics section with an `Irregular Messages` view.
- Added a separate `Witness Repair` tab under Forensics so the post-`903168`
  short-block inspection and repair can run without loading thousands of
  irregular-message rows.
- Added a native `scanirregularmessages` RPC that scans active-chain `CBlock`
  data in bounded chunks and flags nonstandard OP_RETURN outputs.
- The Forensics table shows block height, transaction ID, burned DFC amount,
  decoded text, and a concise irregularity label.
- Added a BIP141 definition column for recognized witness-commitment headers,
  linking to the BIP141 commitment-structure reference.
- Added a resizable pop-out irregular-message table with fixed-width font
  controls, auto-fit/manual column widths, green-bar row striping, and selected
  cell/range copy support.
- Added resumable Forensics scans and a completion summary with irregular block
  counts, non-`6a` prefix percentages, and unique four-byte prefix percentages.
- Flagged cases include nonzero value burned into OP_RETURN outputs,
  OP_RETURN scripts above the standard relay size limit, active script opcodes,
  and multiple OP_RETURN outputs in one transaction.
- Added an experimental UDP fast-sync helper, enabled by default. It can request
  sub-MTU checksum-protected raw block chunks from connected Defcoin peers over
  IPv4 or IPv6 and submits each assembled block through normal Core validation,
  with ordinary TCP/Core sync left active as fallback. LAN discovery additionally
  enables local broadcast.
- Updated UDP fast sync to probe packet size adaptively. Internet/default mode
  stays at safe 1232/1472-byte datagrams, while LAN/private peers can probe 4096,
  8192, 12000, and 16000-byte datagrams and keep only receiver-confirmed clean
  gains.
- Hardened UDP fast-sync packet handling with strict datagram/header/payload
  caps, capability/version checks, bounded per-read processing, per-peer request
  throttling, duplicate-chunk rejection, and checksum validation before block
  assembly.
- Added Top 100 rich-list header help for `Txs` and `UTXOs`, explaining how
  transaction counts and spendable output counts differ.

### Changed

- Updated visible Nu release metadata to `26.5.5w`.
- Letter suffixes now identify every changed rebuild in this release line:
  `26.5.5a`, `26.5.5b`, `26.5.5w`, and so on. The inherited Core client version
  remains `0.21.5.5`.
- Added Forensics to the sidebar, View menu, app resources, and Build Notes.
- Diagnostics > Status now reports sync method details, UDP transfer rate in
  blocks/second and bytes/second, and UDP retransmit/checksum errors.
- Large Forensics result sets now render through bounded table views so thousands
  of loaded rows do not create thousands of QML delegates at once.
- Routine non-text coinbase metadata paired with a normal BIP141 witness
  commitment is no longer treated as an irregular hidden-message row.
- The Irregular Messages start-height presets now omit `903168`; that boundary
  belongs to the Witness Repair workflow.
- Diagnostics > Peers now displays Reverse DNS normally while sorting that
  column by hidden reverse-domain notation, so related domains group together.
- Reverse DNS cells are right-aligned; Known DNS cells are right-aligned except
  true LAN aliases, which display as `LAN:<name>` and are left-aligned.
- UDP fast-sync availability now distinguishes old non-Nu peers from Nu peers:
  non-Nu peers show `No`, Nu peers start as `TBA`, and they switch to `Yes` or
  `Failed` only after a UDP fast-sync exchange is attempted.
- Explorer indexing now uses batched JSON-RPC calls and batched SQLite
  transactions instead of one delayed block request/write per UI tick.
- The Explorer index control is now labeled `High intensity (uses more resources)`;
  when enabled, Nu uses larger Explorer/Top 100 batches, larger SQLite cache
  settings, fewer UI refreshes, and a best-effort process priority increase.
- The UDP/TCP fast-sync selector now compares only peers that can actually be
  tested over both paths, with UDP warmup probes before declaring a preference.
- Witness block-storage inspection now derives a bounded worker count from
  Core's `-par` setting, using independent block-body reads before aggregating
  results.
- Explorer index status now separates live indexing progress from analytics
  summary text so the two messages do not flicker or briefly overwrite each
  other while the indexer is running.
- Explorer Top 100 and movement analytics now refresh in a background worker
  instead of running large SQLite scans on the UI thread.
- Explorer analytics now load only the active heavy tab by default: Top 100 no
  longer starts the movement query unless the Movements tab or full refresh is
  requested.
- Explorer no longer auto-runs a Top 100 refresh merely because the block index
  is already current during app launch.
- Explorer opens with only lightweight index counters and recent lookups. Expensive
  Top 100 and movement analytics are deferred until Top 100 or Movements is
  opened, or until the user explicitly refreshes stats.
- Diagnostics > Log now shows both visible-row numbers and source debug-log
  line numbers, and includes `Copy shown` plus `Save launch log` actions.
- LAN workstation lookup now retries when LAN discovery is enabled and uses
  host lookup, ping, and ARP hints before leaving workstation details blank.

### Fixed

- Witness Repair now inspects stored block bodies instead of trusting
  over-broad `BLOCK_OPT_WITNESS` flags, so missing witness-form block storage
  cannot incorrectly complete in under one second without reading the chain.
- LAN peer-name discovery no longer treats public ISP reverse-DNS names as
  local workstation names.
- Explorer status content now reserves enough height for wrapped index messages,
  so status text cannot paint under the tab bar or buttons.
- Opening Explorer after a full index no longer blocks on the movement summary
  query before the view can repaint.

## 26.5.2 Core Memories

Defcoin Core Nu `26.5.2` is a focused Explorer and packaging polish release
for the current Nu line.

### Added

- Added a prominent Explorer search field that accepts block heights, block
  hashes, transaction IDs, and supported Defcoin Base58 address encodings.
- Added wallet-address Explorer links from transaction detail output, including
  current `D...` addresses, canonical `M...` P2SH, legacy `3...` P2SH, and
  compatibility `9...`/`A...` P2SH forms.
- Added a live witness block data repair setting that pauses networking,
  rewinds/redownloads incomplete post-SegWit block bodies from a chosen height,
  and resumes normal sync without an app restart. The backend also keeps
  `-repairwitnessfromheight=<n>` for headless startup repair.

### Changed

- Updated public documentation and release metadata to the `26.5.2` release
  identity.
- Confirmed Nu packages bundle the Litecoin-equivalent Defcoin command-line
  tool set: `defcoind`, `defcoin-cli`, `defcoin-tx`, and `defcoin-wallet`.

## 26.5.1 Core Memories

Defcoin Core Nu `26.5.1` adds modern SQLite descriptor wallet creation,
recovery phrase support, a local mining helper, and additional diagnostics
while keeping the existing Defcoin chain rules and peer compatibility policy.

### Added

- Added `Create Wallet with Recovery Phrase...` and `Restore Wallet from
  Recovery Phrase...` flows. Creation uses 12-word English BIP39 phrases;
  restore accepts 12, 15, 18, 21, and 24-word English BIP39 phrases.
- Added Nu/Core HD restore mode for phrases created by Nu.
- Added an advanced, preview-gated external BIP39/BIP32 scan mode for users
  recovering phrases from another wallet standard.
- Added a Coinomi/Ian Coleman Defcoin BIP44 preset and explicit Defcoin WIF
  compatibility guidance for current `T...` private keys and legacy v0.22
  `Q...` private-key references.
- Added compatibility decoding for Defcoin `dfcp`/`dfcv` extended keys and
  byte-22 `9...`/`A...` P2SH tool encodings while keeping generated P2SH
  addresses canonical as `M...`.
- Added a Mining view for selecting an external miner executable, configuring
  Defcoin pool parameters, and monitoring miner output.
- Added Diagnostics status rows for difficulty, 120-block estimated network
  hash rate, chain-tip state, sync progress, and top sent/received P2P message
  types.
- Added prior-project acknowledgements in Build Notes.
- Added Bitcoin Core v0.21-style SQLite descriptor wallet creation for new
  wallets, starting with canonical legacy P2PKH Defcoin address descriptors.
- Added Wallet table storage-format reporting, showing `BDB` for Berkeley DB
  legacy wallets and `SQL` for SQLite descriptor wallets.
- Bundled `defcoin-cli` next to `defcoind` in Nu desktop packages for advanced
  support, scripting, and local RPC diagnostics.
- Restored the historical Defcoin v1.0.x softfork boundaries for BIP34,
  BIP65, BIP66, CSV, and SegWit. CSV and SegWit activate at block `903168`,
  so Nu requests and stores post-activation blocks with witness data from
  witness-capable peers.

### Changed

- Updated public documentation and release metadata to the `26.5.1` release
  identity.
- The standard Create Wallet flow defaults to modern SQL storage, while
  existing BDB wallets remain loadable and selectable side by side.
- Kept peer magic, seed, User-Agent, and network-pollution filtering behavior
  aligned with the current Nu policy.
- Stopped advertising inherited Litecoin MWEB services merely because witness
  service is active; MWEB remains disabled on Defcoin mainnet.

## 26.3.1 Core Memories

Defcoin Core Nu `26.3.1` is a cleanup release for the current Nu line.

### Changed

- Nu packaging now copies only the runtime assets used by the Qt Quick shell
  instead of copying every file under the Nu asset tree.
- Public docs and in-app build notes describe only the current release.

### Removed

- Removed unused Nu image/icon drafts and Finder metadata that could leak stale
  or unrelated visual assets into app packages.

## 26.3.0 Core Memories

Defcoin Core Nu `26.3.0`, codename `Core Memories`, established the public Nu
release track.

### Added

- Qt Quick Nu shell organized around Home, Send, Receive, Activity,
  Diagnostics, and Settings.
- Managed backend startup for bundled `defcoind` builds, with launch
  diagnostics surfaced in the app.
- Dual Defcoin P2P magic migration support: legacy `fbc0b6db` and
  Defcoin-specific `defc014e`.
- Peer diagnostics that show actual observed peer magic, protocol version,
  services, User-Agent, traffic, and synchronization details.
- Defcoin User-Agent filtering using the `/Defcoin` prefix rule.
- Receive request history, transaction detail actions, PSBT handling, message
  signing, wallet backup, encryption, and passphrase flows.
- Public-safe technical documentation consolidated in
  `doc/defcoin-core-nu-technical-guide.md`.

### Changed

- Public release identity now uses `26.3.0` instead of the older year-style
  checkpoint labels.
- macOS bundle identifiers use the `org.defcoincore` namespace.
- Mainnet seed documentation and runtime lists include `seed.defcoin-ng.org`
  as a candidate DNS seed.
- Build and publication docs remove local workstation paths, personal handles,
  private machine details, and repeated stale instructions.

### Notes

- The inherited Litecoin-derived backend remains the consensus, wallet, and
  networking authority.
- Defcoin-only magic is a network-isolation goal, not a consensus hard fork.
- Release artifacts belong on GitHub Releases, not in source history.
