# Defcoin Core Nu Technical Guide

Last updated: 2026-05-27

This is the canonical public technical guide for Defcoin Core Nu. It keeps the
Defcoin-specific architecture, build, release, wallet, networking, and
attribution details in one place so they are not repeated across small notes.

## Overview

Defcoin Core Nu `26.5.5`, codename `Core Memories`, is a full-node desktop
wallet for the Defcoin network. It is derived from Litecoin Core `v0.21.5.5`
and keeps the inherited Litecoin Core engine where that behavior is still
correct for Defcoin. Nu adds a Qt Quick desktop shell, bundled backend launch
management, peer and traffic diagnostics, BIP39 recovery workflows, local
mining setup helpers, and Defcoin-specific peer hygiene controls for a smaller
network.

Public source repository:

```text
https://github.com/DefcoinCore/Defcoin-Core-Nu
```

Release binaries, installers, disk images, checksums, update feeds, and
bootstrap packs belong on GitHub Releases or another release distribution
service. They should not be committed to source history.

## Release Identity

- Release: `26.5.5`
- Codename: `Core Memories`
- Backend baseline: Litecoin Core `v0.21.5.5`
- Proof of work: Scrypt
- Target block time: 120 seconds
- Default data directory: the existing Defcoin data directory
- Config file: `defcoin.conf`
- Display units: `DFC`, `Packet`, `Tock`, `Mote`
- macOS bundle namespace: `org.defcoincore`

The inherited numeric `CLIENT_VERSION` remains available where the upstream
code expects it, but the public Defcoin Core Nu release identity is `26.5.5`.
The peer User-Agent for this release should report a Defcoin prefix and the Nu
release version, for example `/DefcoinCoreNu:26.5.5/`.

## Architecture

Nu has two main process and responsibility boundaries:

- the backend owns consensus, block validation, peer networking, wallet
  storage, private keys, fee policy, transaction funding, signing,
  broadcasting, debug logging, and RPC execution;
- the Qt Quick frontend owns navigation, layout, display preferences, local
  clipboard/export actions, QR presentation, charts, diagnostics presentation,
  mining process setup, and safety-first review flows.

The packaged desktop app may start a bundled `defcoind` backend when no
compatible local RPC backend is already available. The frontend connects to
that backend through local RPC using normal cookie authentication. The app
surfaces backend startup state, readiness, debug logs, peer status, traffic,
mining helper status, and wallet state in the visible UI.

The QML layer must not hold private-key material longer than the active dialog
requires, write wallet databases directly, construct consensus-critical
transactions by hand, or duplicate validation logic. Wallet and node actions
remain behind backend RPC wrappers such as the Nu RPC service layer.

## Defcoin And Litecoin Core Differences

Defcoin Core Nu inherits the parts of Litecoin Core that are still useful for a
Defcoin full node:

- block validation, mempool, transaction relay, wallet storage, Berkeley DB
  legacy wallet compatibility, pruning, reindex, rescan, proxy, RPC, REST, and
  Scrypt proof-of-work implementation paths;
- the upstream build and dependency model, with platform-specific adjustments
  for the Nu shell and packaged releases;
- security and maintenance fixes from the Litecoin Core `v0.21.5.5` baseline
  where those fixes live in inherited code paths.

Defcoin Core Nu changes the areas that are Defcoin-specific:

- product names, executable names, app metadata, URI scheme, displayed units,
  artwork, and packaging;
- chain parameters, genesis data, checkpoints, minimum chain work, assumed
  chain size, address prefixes, default ports, and seed hosts;
- peer message-start migration support and peer User-Agent filtering;
- Qt Quick Nu desktop interface, diagnostics, local mining helper UI, and
  release packaging;
- disabled inherited Litecoin features that are not active Defcoin mainnet
  consensus features.

Defcoin Core Nu preserves compatibility with the historical Defcoin chain and
wallet directory. Existing wallet files should still be backed up before any
software upgrade.

## Historical Compatibility Boundary

This branch follows the Defcoin compatibility policy from the historical
Defcoin source line: preserve the existing chain first, and do not enable newer
Litecoin mainnet deployments unless they are explicitly valid for Defcoin.

Nu follows the historical Defcoin v1.0.x softfork boundaries. This keeps Nu
aligned with old clients that already considered CSV and SegWit active at
height `903168`, and forces post-activation block bodies to be downloaded from
witness-capable peers. Existing Nu datadirs that previously stored stripped
post-activation blocks are rewound by Core's inherited block-index repair path
and redownloaded cleanly.

Nu exposes a live block-body repair workflow in Settings > Network >
Blockchain repair. It pauses P2P networking, asks the backend to rewind the
first post-SegWit block body missing witness data from the chosen height, then
resumes normal sync so clean block bodies are redownloaded from witness-capable
peers. Headless operators can run the same startup scan once with
`-repairwitnessfromheight=<height>`. This is block data repair, not a wallet
rescan; wallet rescans remain separate RPC/wallet operations.

The following inherited Litecoin features are not treated as active Defcoin
mainnet consensus features in this release:

- Taproot
- MWEB
- Signet

Some inherited source paths and RPC fields may still exist because they are
part of the upstream Litecoin Core codebase. Their presence in the source tree
does not mean the corresponding feature is active on Defcoin mainnet.

## Network Parameters And Seeds

Mainnet:

| Parameter | Value |
| --- | --- |
| Network ID | `main` |
| Legacy message start | `fb c0 b6 db` |
| Defcoin message start | `de fc 01 4e` |
| Default P2P port | `1337` |
| Default RPC port | `9332` |
| Prune after height | `100000` |
| Historical SegWit height | `903168` |
| Target spacing | `120` seconds |
| Target timespan | `86400` seconds |
| Difficulty retarget interval | `720` blocks |
| Subsidy halving interval | `840000` blocks |
| Initial subsidy | `50 DFC` |
| BIP34 height | `828326` |
| BIP65 / CLTV height | `1828326` |
| BIP66 height | `1828326` |
| CSV height | `903168` |
| Base58 pubkey prefix | `30` |
| Base58 script prefix | `5` |
| Base58 second script prefix | `50` |
| Base58 secret key prefix | `176` |
| Bech32 HRP | `dfc` |
| MWEB HRP | `dfcmweb` |

Other local networks:

| Network | P2P port | RPC port |
| --- | ---: | ---: |
| Testnet | `31337` | `19332` |
| Regtest | `19444` | `19443` |

Mainnet DNS seeds:

- `seed.defcoin.io`
- `seed.defcoin.mikej.tech`
- `seed.defcoin.dc903.org:10332`
- `seed.defcoincore.org`
- `seed.defcoin-ng.org`

macOS bundle and helper identifiers use the `org.defcoincore` namespace, for
example:

- `org.defcoincore.DefcoinCoreNu`
- `org.defcoincore.DefcoinPayment`

## Peer Magic And User-Agent Filtering

Defcoin Core Nu supports two mainnet P2P message starts during the migration
window:

- legacy compatibility magic: `fbc0b6db`
- Defcoin-specific magic: `defc014e`

Compatibility mode accepts both values. Outbound connections should prefer
`defc014e` when the remote node supports it. After the first valid P2P header
selects a peer's magic value, replies to that peer must use the same magic
value. Peer tables and RPC diagnostics report the actual selected magic for
each peer rather than inferring it from version or User-Agent text.

This is not a blockchain hard fork. It is a transport-level network isolation
improvement that reduces wasted sockets, handshakes, address pollution, and
CPU/network load from unrelated Litecoin-family peers.

Accepted Defcoin peer User-Agents must begin with `/Defcoin`.
`/DefcoinCore:1.0.0/` is valid because it starts with `/Defcoin`. Legacy-magic
peers that do not pass the Defcoin User-Agent prefix check should be
disconnected before their `addr` or `addrv2` gossip is accepted into addrman or
rebroadcast.

Address filtering is endpoint-specific, not IP-wide. If one host runs a
Litecoin service on one port and a Defcoin service on another port, the valid
Defcoin endpoint must remain eligible.

## Wallet And UI Capabilities

Nu organizes the wallet around these main views:

- Home: balances, sync state, wallet lock state, and core node health.
- Send: normal send flow, fee review, transaction details, and signing paths
  exposed through backend RPC.
- Receive: address generation, receive-request history, request details, QR
  display, and request removal.
- Transactions: transaction history, details, copy/export actions, and
  explorer links where configured by the user.
- Explorer: local SQLite-backed block, transaction, address, rich-list, and
  movement lookups.
- Forensics: irregular OP_RETURN message discovery from active-chain block data.
- Diagnostics: backend status, logs, console, traffic, and simple or detailed
  peer tables.
- Mining: external miner selection, preset pool configuration, command/config
  generation, process start/stop, and live miner log monitoring.
- Settings: wallet safety actions, network preferences, display preferences,
  update preferences, About, and build notes.

Wallet-sensitive operations such as backup, encryption, passphrase changes,
message signing, message verification, PSBT handling, transaction funding, and
broadcasting remain backend-owned. The frontend presents the workflow and
passes the request through RPC wrappers.

## Wallet Storage: BDB And SQL

Nu `26.5.5` follows Bitcoin Core's wallet-storage direction rather than
inventing a separate storage layer. Bitcoin Core v0.21 introduced SQLite-backed
descriptor wallets, and current Bitcoin Core creates descriptor wallets in
SQLite by default. Nu `26.5` and later keep that modern default while preserving
legacy BDB compatibility for existing Defcoin wallets:

- `BDB` means Berkeley DB legacy wallet storage. Existing Defcoin wallets remain
  loadable and selectable.
- `SQL` means SQLite descriptor wallet storage. The standard Create Wallet flow
  defaults to this modern storage path in `26.5` and later.

The Wallet page detects wallet database format from `getwalletinfo` when a
wallet is loaded and by file magic when a wallet is available on disk. SQL
descriptor wallet creation currently generates Defcoin's canonical legacy P2PKH
receive and change descriptors. The inherited Litecoin MWEB descriptor branch is
not enabled for SQL wallet creation until it has a separate Defcoin-specific
port and test pass.

Nu does not silently convert old `wallet.dat` files. Any BDB-to-SQL migration
must be a separate, backup-gated workflow because wallet files can contain
labels, imported keys, watch-only records, recovery imports, encryption state,
and transaction metadata.

Peer diagnostics expose transport and health details useful to Defcoin's
networking and security audience, including actual peer magic, direction,
address, port, ping, bytes sent and received, User-Agent, protocol version,
service flags, DNS names where resolved, and address-gossip counters where
available.

The Diagnostics status view also reports packetloss404 / Ian S. Walmsley
v1.0.2-style network-health information through backend RPC: current
difficulty, estimated network hash rate over 120 blocks, active chain and
chain-tip counts, sync progress, and the top sent/received P2P message types
observed from peers.

The Forensics view starts with `Irregular Messages`, a user-readable OP_RETURN
oddity table. Its backend `scanirregularmessages` RPC scans active-chain
`CBlock` data in bounded chunks and flags outputs that would normally be outside
standard relay policy: nonzero value burned into OP_RETURN, scripts larger than
the 83-byte standard OP_RETURN relay limit, active opcodes after OP_RETURN, and
multiple OP_RETURN outputs in the same transaction. The RPC only reads accepted
block data and does not change chain state.

## BIP39 Recovery Phrase Support

Nu `26.5.5` supports English BIP39 recovery phrases. Creation uses 12 words;
restore accepts the standard BIP39 word counts of 12, 15, 18, 21, and 24 words.
The implementation provides two user-facing paths:

- `Create Wallet with Recovery Phrase...` generates a 12-word phrase, requires
  confirmation, creates a blank wallet, and sets a Core HD seed from the
  phrase-derived key material.
- `Restore Wallet from Recovery Phrase...` validates word membership and
  checksum before enabling restore. `Nu/Core HD` restores phrases created by
  Nu. `Advanced external scan` derives preview addresses from selected
  BIP39/BIP32 paths and imports a bounded range into a new wallet after user
  review.

The advanced scan includes a Coinomi/Ian Coleman Defcoin BIP44 preset,
`m/44'/1337'/0'/0/*`, because the Ian Coleman BIP39 tool assigns Defcoin coin
type `1337`. It also labels the Defcoin WIF compatibility split:

- Defcoin v0.22 and the current Ian Coleman Defcoin entry use WIF prefix
  `0x9e`, which renders private keys beginning with `Q`.
- Defcoin v1.0.0 and newer use WIF prefix `0xb0`, which renders private keys
  beginning with `T`.

The WIF byte affects private-key serialization, not the Defcoin address derived
from the key. Nu's recovery UI exposes that distinction so a user can compare
legacy `Q...` references while importing into a current wallet-compatible
`T...` environment.

Nu also accepts the Defcoin extended-key prefixes proposed for older tooling:
`dfcp` for extended public keys and `dfcv` for extended private keys. The
current wallet still exports the inherited `xpub`/`xprv` form unless a future
release deliberately changes that policy after broader testing. The Wallet page
includes a local compatibility converter that displays the `xpub`/`xprv` and
`dfcp`/`dfcv` forms for the same extended key. For script-hash
addresses, Nu continues to generate the canonical `M...` form, keeps accepting
the older `3...` form, and decodes byte-22 `9...`/`A...` tool encodings for
compatibility with pycoin/BeerWallet-era experiments. The same converter shows
the canonical `M...` equivalent when a supported legacy/tool P2SH form is
pasted.

The phrase is held only in the active dialog state and RPC call path. It should
not be logged, stored in application settings, echoed to debug output, or
persisted after the dialog closes. Advanced external recovery is preview-gated
because historical Defcoin wallets do not have a single proven BIP39
derivation standard.

## Local Mining Helper

The Mining view helps users configure an external miner without bundling mining
code into the wallet. This avoids packaging a miner executable into stores or
platforms where cryptocurrency miners may be restricted by policy. The user
selects a miner executable, chooses a preset or custom pool endpoint, and lets
the wallet assemble the command/configuration needed to run and monitor the
external process.

The first preset targets `cpuminer-opt` with Scrypt, matching the local command
shape used for Defcoin pool testing. GPU, USB, and IP-based ASIC monitoring
can use the same UI boundary: the wallet coordinates configuration and status,
while the miner remains an external program.

## Build And Package Overview

Use a clean clone of the public repository. Public documentation should use
generic paths such as:

```sh
REPO="$HOME/src/Defcoin-Core-Nu"
SRC="$REPO/source"
```

Do not publish local workstation paths, mounted drive names, user names,
private credentials, wallet files, RPC cookies, or machine-specific details.

The backend follows the inherited Litecoin Core build model. Install the
dependencies for the target platform, configure with wallet support enabled
where legacy wallet compatibility is needed, then build the normal Defcoin
node tools:

- `src/defcoind`
- `src/defcoin-cli`
- `src/defcoin-tx`
- `src/defcoin-wallet`
- `src/qt/defcoin-qt` where the inherited Qt Widgets wallet is enabled

Nu desktop packages bundle the same user-facing command-line binaries that the
inherited Litecoin Core release model provides, renamed and parameterized for
Defcoin: `defcoind`, `defcoin-cli`, `defcoin-tx`, and `defcoin-wallet`. The GUI
uses `defcoind` as its managed backend and does not require end users to run the
CLI tools manually.

Run focused smoke tests after building:

```sh
./contrib/defcoin-smoke-test.sh
```

The Nu shell is built with CMake. A typical local macOS release build is:

```sh
cmake -S src/qt/nu/app -B build/nu-qml-macos \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DDEFCOIN_NU_BACKEND_BINARY="$SRC/src/defcoind" \
  -DDEFCOIN_NU_CLI_BINARY="$SRC/src/defcoin-cli" \
  -DDEFCOIN_NU_TX_BINARY="$SRC/src/defcoin-tx" \
  -DDEFCOIN_NU_WALLET_BINARY="$SRC/src/defcoin-wallet" \
  -DDEFCOIN_NU_RELEASE_NAME="26.5.5" \
  -DDEFCOIN_NU_ENABLE_HELP=OFF

cmake --build build/nu-qml-macos --target DefcoinCoreNuResources -- -j1
```

Use `x86_64` for Intel macOS builds. Windows releases are built with the
Windows Qt runtime and the appropriate MinGW/CMake toolchain. Use
single-threaded backend builds on constrained machines.

Stage release artifacts outside the source tree. Do not commit app bundles,
installers, disk images, ZIP files, generated update-feed packages, or signing
material.

The Apple Silicon Nu release disk image is named:

```text
Defcoin-Core-Nu-v26.5.5-macOS-AppleSilicon.dmg
```

## Release And Publication Process

Before publishing:

- `git status --short` shows only intentional release edits;
- `git diff --check` passes;
- public docs do not contain private paths, credentials, old release labels,
  local machine details, personal handles, old reverse-DNS identifiers, or
  unshipped feature promises;
- seed lists include the five mainnet seed hosts above;
- bundle metadata uses `org.defcoincore`;
- `getnetworkinfo` reports a Defcoin User-Agent beginning with
  `/DefcoinCoreNu:26.5.5/`;
- platform packages are built from clean release inputs;
- checksums and signatures are generated for release artifacts;
- release notes describe only what ships in the release being published.

The source repository should contain the source, public documentation, license
material, and small assets required to build the software. Release binaries
and installers should be attached to releases or distributed through a
dedicated release host.

## AI-Assisted Development Note

Defcoin Core Nu was developed with AI assistance for documentation cleanup, UI
iteration, build scripting, code review, and repetitive source migration work,
specifically OpenAI Codex using GPT-5.5 with extra-high reasoning settings.
Human review, local builds, runtime testing, and open-source publication remain
the controls that make the result auditable. AI assistance does not change the
inherited MIT license or the requirement that maintainers review
security-sensitive wallet and networking changes carefully.

## Security, License, Trademark, And Attribution Boundaries

Defcoin Core Nu code is released under the MIT license inherited from Litecoin
Core and Bitcoin Core unless a file explicitly states otherwise. New Nu source
and documentation should stay under the same license model.

The software license does not grant trademark or artwork rights. Defcoin coin
imagery and Def Con-related marks have separate permission and ownership
boundaries documented in `doc/license-and-attribution-notices.md`.

Defcoin Core Nu builds on prior Defcoin wallet, pool, and mobile work: the
first public Defcoin-Qt v0.8.6.2 builds, Defcoin Core v1.0.0, v1.0.1,
packetloss404 / Ian S. Walmsley's v1.0.2 work, earlier Defcoin P2Pool porting
credited to charlesrocket and later Defcoin pool operators, Justin
Culbertson's Android Defcoin Wallet, Michael Perklin's BeerWallet for iOS, and
Joshua "Josh" McDougall / Abstrct's Coindroids work.

Security-sensitive work should be reviewed with extra care, especially changes
to wallet encryption, signing, transaction construction, mnemonic recovery,
address relay, network-message parsing, peer filtering, seed handling, update
delivery, and release signing.

## Public Documentation Map

- `README.md`: product overview, downloads, screenshots, and common build
  entry points.
- `doc/README.md`: index of inherited and Defcoin-specific documentation.
- `doc/release-notes/release-notes-26.5.5.md`: current release notes.
- `doc/license-and-attribution-notices.md`: license, dependency, artwork, and
  attribution notices.
- `src/qt/nu/docs/`: Nu frontend implementation notes for developers.
