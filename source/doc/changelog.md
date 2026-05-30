# Defcoin Core Changelog

## 26.5.2 Core Memories

Defcoin Core Nu `26.5.2` is a focused Explorer and packaging polish release
for the current Nu line.

### Added

- Added a prominent Explorer search field that accepts block heights, block
  hashes, transaction IDs, and supported Defcoin Base58 address encodings.
- Added wallet-address Explorer links from transaction detail output, including
  current `D...` addresses, canonical `M...` P2SH, legacy `3...` P2SH, and
  compatibility `9...`/`A...` P2SH forms.

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
