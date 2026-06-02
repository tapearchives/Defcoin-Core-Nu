# Defcoin Core Changelog

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
