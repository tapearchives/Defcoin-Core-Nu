<p align="center">
  <img src="source/src/qt/nu/assets/brand/defcoin-core-nu-readme-hero.png" width="720" alt="Defcoin Core Nu logo">
</p>

<h1 align="center">Defcoin Core Nu</h1>

<p align="center">
  <strong>Download a Defcoin wallet. Store DFC. Send and receive Defcoin on the Defcoin network.</strong>
</p>

<p align="center">
  <a href="https://github.com/defcoincore/Defcoin-Core-Nu/releases/tag/v26.5.1"><strong>Download Wallet</strong></a>
  ·
  <a href="#build-from-source">Build from source</a>
  ·
  <a href="source/doc/defcoin-core-nu-technical-guide.md">Technical guide</a>
  ·
  <a href="source/doc/release-notes/release-notes-26.5.1.md">Release notes</a>
</p>

Defcoin is a Scrypt proof-of-work cryptocurrency with a long-running independent
chain. Defcoin Core Nu is the current full-node desktop wallet for holding DFC,
sending and receiving payments, inspecting network peers, and participating in
the Defcoin network.

The `26.5.1` release, codename `Core Memories`, preserves Defcoin's historical
chain rules and wallet data while adding a focused Qt Quick desktop experience
for modern macOS and Windows users.

## Get The Wallet

Choose the package for your computer from
[Defcoin Core Nu 26.5.1 "Core Memories"](https://github.com/defcoincore/Defcoin-Core-Nu/releases/tag/v26.5.1).

| Platform | Package |
| --- | --- |
| macOS Apple Silicon | [DMG](https://github.com/defcoincore/Defcoin-Core-Nu/releases/download/v26.5.1/Defcoin-Core-Nu-v26.5.1-macOS-AppleSilicon.dmg) |
| macOS Intel | [DMG](https://github.com/defcoincore/Defcoin-Core-Nu/releases/download/v26.5.1/Defcoin-Core-Nu-v26.5.1-macOS-Intel.dmg) |
| Windows 11 x86_64 | [Installer](https://github.com/defcoincore/Defcoin-Core-Nu/releases/download/v26.5.1/Defcoin-Core-Nu-v26.5.1-Windows11-x86_64-Setup.exe) |
| Windows 11 x86_64 | [Portable ZIP](https://github.com/defcoincore/Defcoin-Core-Nu/releases/download/v26.5.1/Defcoin-Core-Nu-v26.5.1-Windows11-x86_64-portable.zip) |
| Optional bootstrap pack | [Bootstrap ZIP](https://github.com/defcoincore/Defcoin-Core-Nu/releases/download/v26.5.1/Defcoin-bootstrap-mainnet-2332283.zip) · [SHA-256](https://github.com/defcoincore/Defcoin-Core-Nu/releases/download/v26.5.1/Defcoin-bootstrap-mainnet-2332283.zip.sha256) |
| Verification | [SHA256SUMS.txt](https://github.com/defcoincore/Defcoin-Core-Nu/releases/download/v26.5.1/SHA256SUMS.txt) |

The macOS Intel build is provided for compatibility but has not yet been tested
on Intel Mac hardware.

After installing, start the wallet, let it connect to peers, and allow it to
sync before relying on balances or recent transactions.

Optional bootstrap pack: users who want to speed up first sync can download the
bootstrap ZIP from the release assets. It contains `bootstrap.dat`, macOS and
Windows import scripts, install instructions, and checksums. The snapshot is at
block `2,332,283`; the node still verifies imported blocks and syncs newer
blocks normally.

## What Nu Adds

- A Qt Quick desktop shell for Home, Send, Receive, Transactions, Wallet,
  Mining, Diagnostics, and Settings.
- Managed local `defcoind` startup for packaged desktop builds.
- Bundled `defcoin-cli` in packaged desktop builds for advanced local support
  and RPC diagnostics.
- Bitcoin Core-style wallet storage detection with side-by-side `BDB` legacy
  wallets and modern `SQL` descriptor wallets. Defcoin Core Nu `26.5` and later
  create SQL descriptor wallets by default while existing Berkeley DB wallets
  remain loadable.
- Peer diagnostics with actual observed magic bytes, protocol version, services,
  User-Agent, sync, and traffic details.
- Network-health diagnostics for difficulty, estimated network hash rate,
  chain-tip state, sync progress, and top P2P message traffic.
- English BIP39 recovery phrase creation and restore workflows for Nu/Core HD
  wallets, plus 12-24 word external scan support with Defcoin `T...` and
  legacy `Q...` WIF compatibility guidance. Extended keys can be read as
  `xpub`/`xprv` or `dfcp`/`dfcv`; generated P2SH addresses remain `M...`.
- Local mining setup and monitoring helpers that let users select an external
  miner executable rather than bundling mining code inside the wallet.
- Dual-magic compatibility for the Defcoin network migration: upgraded peers use
  `defc014e`; compatibility mode can still accept legacy `fbc0b6db`.
- Defcoin User-Agent filtering using the `/Defcoin` prefix rule to reduce
  Litecoin-family peer pollution.
- Receive request history, PSBT handling, message signing, wallet backup,
  encryption, and passphrase flows.

## Screenshots

<p align="center">
  <img src="source/doc/assets/screenshots/nu-diagnostics-traffic.png" width="860" alt="Defcoin Core Nu Diagnostics network traffic chart">
</p>

<p align="center"><em>Diagnostics traffic view after an extended live network session.</em></p>

<p align="center">
  <img src="source/doc/assets/screenshots/nu-diagnostics-peers.png" width="860" alt="Defcoin Core Nu Diagnostics peers table">
</p>

<p align="center"><em>Peer diagnostics with observed magic bytes, protocol version, DNS names, and aliases.</em></p>

<p align="center">
  <img src="source/doc/assets/screenshots/nu-settings-network.png" width="860" alt="Defcoin Core Nu network settings">
</p>

<p align="center"><em>Network settings for peer filtering, dual-magic migration, and LAN discovery.</em></p>

## Network Identity

| Item | Value |
| --- | --- |
| Proof of work | Scrypt |
| Target block time | 2 minutes |
| Mainnet P2P/RPC ports | `1337` / `9332` |
| Mainnet Defcoin magic | `de fc 01 4e` (`defc014e`) |
| Mainnet legacy magic | `fb c0 b6 db` (`fbc0b6db`) |
| Config file | `defcoin.conf` |
| macOS data directory | `~/Library/Application Support/Defcoin/` |

More detailed chain, seed, wallet, and compatibility notes are in the
[Defcoin Core Nu Technical Guide](source/doc/defcoin-core-nu-technical-guide.md).

## Build From Source

Start with a fresh clone:

```text
git clone https://github.com/defcoincore/Defcoin-Core-Nu.git
cd Defcoin-Core-Nu
cd source
```

The buildable Litecoin-derived source tree is intentionally kept under
`source/` so the GitHub root can work as a clean product landing page.

Platform prerequisites are documented here:

- [macOS Build Notes](source/doc/build-osx.md)
- [Unix Build Notes](source/doc/build-unix.md)
- [Windows Build Notes](source/doc/build-windows.md)
- [Defcoin Core Nu Technical Guide](source/doc/defcoin-core-nu-technical-guide.md)

Release artifacts are attached to GitHub Releases rather than committed to
source history.

## Compatibility

Defcoin Core Nu preserves Defcoin's historical mainnet behavior first. It keeps
legacy Base58 wallet compatibility and does not treat newer Litecoin mainnet
deployments as active Defcoin mainnet consensus features unless they are
explicitly part of Defcoin.

Back up old wallets before testing them with new software.

## License And Notices

Defcoin Core Nu code is released under the MIT license inherited from Litecoin
Core and Bitcoin Core. See [COPYING](COPYING).

Trademark rights and coin artwork permissions are separate from the software
license. See
[license and attribution notices](source/doc/license-and-attribution-notices.md).

Copyright (C) 2014-2026 The Defcoin Core developers.

Defcoin Core is derived from Litecoin Core and Bitcoin Core. Portions remain
credited to The Litecoin Core developers and The Bitcoin Core developers.
