# Defcoin Core Changelog

## 26.5.5a Core Memories

Defcoin Core Nu `26.5.5a` adds the first Forensics view for average users who
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
- Hardened UDP fast-sync packet handling with strict datagram/header/payload
  caps, capability/version checks, bounded per-read processing, per-peer request
  throttling, duplicate-chunk rejection, and checksum validation before block
  assembly.

### Changed

- Updated visible Nu release metadata to `26.5.5a`.
- Letter suffixes now identify every changed rebuild in this release line:
  `26.5.5a`, then `26.5.5b`, and so on. The inherited Core client version
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

### Fixed

- Witness Repair now inspects stored block bodies instead of trusting
  over-broad `BLOCK_OPT_WITNESS` flags, so missing witness-form block storage
  cannot incorrectly complete in under one second without reading the chain.
- LAN peer-name discovery no longer treats public ISP reverse-DNS names as
  local workstation names.

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
