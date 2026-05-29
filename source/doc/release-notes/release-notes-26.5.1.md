# Defcoin Core Nu 26.5.1 Release Notes

Codename: `Core Memories`

Defcoin Core Nu `26.5.1` is a wallet storage, recovery, diagnostics, and
local-mining helper release for the current Nu desktop line. It preserves
Defcoin's historical chain rules, wallet directory, dual-magic compatibility
policy, and `/Defcoin` User-Agent filtering.

## Notable Changes

- Added English BIP39 recovery phrase support. Nu-created recovery wallets use
  12 words; restore accepts 12, 15, 18, 21, and 24-word phrases.
- Added `Create Wallet with Recovery Phrase...` for Nu/Core HD wallets.
- Added `Restore Wallet from Recovery Phrase...` with checksum validation,
  per-word autocomplete, Nu/Core HD restore, and an advanced external
  derivation scan that requires address preview before import.
- Added an `Auto until 1024 empty addresses` recovery scan for unusual wallets
  that may have received many mining payouts directly into derived wallet
  addresses.
- Added a Coinomi/Ian Coleman Defcoin path preset and recovery UI guidance for
  current Defcoin `T...` WIF keys versus legacy v0.22/Ian Coleman `Q...` WIF
  references.
- Added compatibility decoding for Defcoin `dfcp`/`dfcv` extended keys and
  byte-22 `9...`/`A...` P2SH tool encodings. Nu still generates canonical
  `M...` P2SH addresses.
- Added a Mining tab for choosing an external miner executable, selecting a
  Defcoin pool preset or custom endpoint, generating miner arguments/config,
  and monitoring miner output.
- Added packetloss404 / Ian S. Walmsley v1.0.2-style Diagnostics status
  values: difficulty, estimated network hash rate over 120 blocks, active
  chain and chain-tip counts, sync progress, and top P2P message types.
- Added Build Notes acknowledgements for prior Defcoin Core releases, earlier
  Defcoin P2Pool work, Android Defcoin Wallet, BeerWallet for iOS, and
  Coindroids.
- Added modern SQL descriptor wallet creation using Bitcoin Core's descriptor
  wallet model. Bitcoin Core introduced SQLite descriptor wallets in v0.21 and
  current Bitcoin Core creates descriptor wallets in SQLite by default; Defcoin
  Core Nu `26.5` and later follow that default for new Nu wallets while existing
  legacy BDB wallets remain supported.
- Added Wallet table storage-format reporting, showing `BDB` for Berkeley DB
  legacy wallets and `SQL` for SQLite descriptor wallets.
- Bundled the Litecoin-equivalent Defcoin command-line tool set in Nu desktop
  packages: `defcoind`, `defcoin-cli`, `defcoin-tx`, and `defcoin-wallet`.

## Wallet Storage Scope

Bitcoin Core first introduced SQLite descriptor wallets in the v0.21.0 release
line, and current Bitcoin Core creates descriptor wallets in SQLite by default.
Nu follows that model for `26.5` and later wallets: descriptor wallets are
stored as SQLite databases, while legacy Berkeley DB wallets continue to load
normally.

For this first 26.5.1 pass, Nu-created SQL descriptor wallets generate
canonical Defcoin P2PKH receive/change addresses. The inherited Litecoin MWEB
descriptor branch is not enabled for SQL wallet creation until it has a
separate Defcoin-specific port and test pass.

## Historical Softfork Alignment

Nu now follows the historical Defcoin v1.0.x softfork boundaries for BIP34,
BIP65, BIP66, CSV, and SegWit. CSV and SegWit activate at block `903168`.
That means post-activation block bodies are requested from peers advertising
`NODE_WITNESS`, stored with witness data, and validated with the normal
inherited SegWit commitment checks. Existing Nu block indexes that contain
stripped post-activation blocks are rewound and redownloaded through Core's
inherited repair path.

MWEB remains disabled on Defcoin mainnet and is no longer advertised merely
because witness service is active.

## Recovery Phrase Scope

Mnemonic creation uses 12-word English BIP39 phrases. Restore accepts the
standard English BIP39 lengths of 12, 15, 18, 21, and 24 words. Phrases created
by Nu should be restored with `Nu/Core HD`. Phrases from other wallets, such as
Coinomi, should use the advanced external scan only after the user recognizes
the previewed addresses.

For mined-to-wallet or otherwise high-address-count histories, the
`Auto until 1024 empty addresses` scan imports and rescans in batches, then
stops each selected method only after 1024 consecutive derived addresses have no
received coins. That mode can take much longer than fixed scans, but is designed
to avoid missing funds beyond a normal BIP44-style gap.

Defcoin v0.22 and the current Ian Coleman Defcoin entry use WIF prefix `0x9e`,
which renders private keys beginning with `Q`. Defcoin v1.0.0 and newer use WIF
prefix `0xb0`, which renders private keys beginning with `T`. Nu labels that
compatibility boundary in the recovery flow so modern-wallet imports use the
current Defcoin key format while older recovery references remain recognizable.

The wallet does not store or log the phrase after the dialog closes.

## Mining Helper Scope

Nu does not bundle a cryptocurrency miner executable. The Mining tab helps the
user select an external miner and configure it for Defcoin. This keeps mining
software outside the wallet package while still making local mining setup more
approachable.

## Optional Bootstrap Pack

The optional bootstrap pack contains `bootstrap.dat`, macOS and Windows import
scripts, instructions, and checksums. Defcoin Core Nu still verifies imported
blocks and then syncs newer blocks from the network normally.

Technical details are maintained in
`doc/defcoin-core-nu-technical-guide.md`.
