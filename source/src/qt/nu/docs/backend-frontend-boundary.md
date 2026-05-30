# Defcoin Core Nu Backend / Frontend Boundary

Defcoin Core Nu 26.5.5c is a Qt Quick wallet interface on top of the
Defcoin Core engine. The Nu UI is intentionally new; the money-critical engine
is not.

## Boundary Summary

| Layer | Owns | Must not own |
| --- | --- | --- |
| Defcoin Core backend | chain parameters, block validation, peer networking, wallet database, private keys, address book, transaction funding, fee policy, signing, broadcasting, debug log, RPC command execution | visual layout, navigation, text hierarchy, chart rendering, local UI preferences |
| Nu QML frontend | navigation, form layout, chart presentation, request QR rendering, local display state, safe review flows, CSV export of already-returned rows | private-key material, consensus rules, direct wallet database writes, direct peer-manager access, signing, validation |
| `NuRpcService` bridge | local JSON-RPC transport, cookie/config discovery, typed data projection into QML, backend launch helper, QR generation, clipboard/file dialogs | consensus decisions, fee validation, signature generation |

The QML scene graph never receives private keys or raw wallet internals. It
requests actions through `NuRpcService`; the backend accepts or rejects them
using the same wallet rules used by classic Defcoin Core.

## Backend Inheritance

Nu uses the Defcoin backend port derived from Litecoin Core. Internally, this
means the backend differs from upstream Litecoin Core in the same categories as
the standard Defcoin build:

- Defcoin chain parameters, network magic, default port, seeds, genesis and
  checkpoint assumptions.
- Defcoin address and amount naming, including DFC display strings.
- Defcoin branding and bundle identity.
- Defcoin peer policy. The Nu rule is now simple: accepted peer user agents
  must begin with `/Defcoin`, ignoring case after the leading slash is removed.
  Short ticker-style prefixes are not accepted or documented in Nu.
- Inherited Litecoin features that remain unavailable in Defcoin stay disabled:
  BIP65/CLTV, BIP66 strict DER signatures, CSV, SegWit activation, Taproot,
  MWEB, and Signet.

## Runtime Model

On Apple Silicon, the Nu app can use the existing Defcoin data directory and
can start a bundled `defcoind` backend if RPC credentials are not already
available. Discovery order is:

1. `DEFCOIN_RPC_*` environment variables and `DEFCOIN_DATADIR`, when supplied.
2. `defcoin.conf` in the Defcoin data directory.
3. `.cookie` in the Defcoin data directory.
4. Bundled `defcoind` in the app resources, started with local RPC enabled.

The macOS default data directory remains:

```text
~/Library/Application Support/Defcoin
```

This lets Nu use the same blockchain and wallet data already maintained by
other Defcoin Core builds on the same machine.

## Current RPC Coverage

Wallet state and payments:

- `getwalletinfo`
- `listtransactions`
- `listreceivedbyaddress`
- `listlabels`
- `getaddressesbylabel`
- `getnewaddress`
- `setlabel`
- `sendtoaddress`
- `send`
- `backupwallet`

Node state and diagnostics:

- `getnetworkinfo`
- `getblockchaininfo`
- `getnettotals`
- `getpeerinfo`
- `ping`
- `setnetworkactive`
- `getonlydefcoinuseragents`
- `setonlydefcoinuseragents`

Advanced coverage:

- Nu exposes a real local RPC console under `Node > Console`. This preserves
  access to classic wallet and node commands that are not promoted into the
  primary UI, such as `encryptwallet`, `walletpassphrase`, `walletlock`,
  `walletpassphrasechange`, `signmessage`, `verifymessage`, `listunspent`, and
  raw transaction/PSBT commands.

Filesystem reads and writes:

- Read-only tail of `debug.log` for `Node > Log`.
- User-selected wallet backup path via `backupwallet`.
- User-selected CSV export paths for transaction and traffic data.

## Safety Rules

- QML must never hold private-key material.
- QML must never construct or sign raw transactions directly.
- Send flow must show a review step before broadcast.
- Fee controls are exposed, but backend validation remains authoritative.
- Advanced operations that can expose secrets or alter wallet security stay in
  the RPC console until they have dedicated hardened QML flows.
- User-facing QML text must describe available behavior, not development plans.

## Design Rationale

Nu follows the Bitcoin Core App direction toward a Qt Quick interface with a
separate GUI/client boundary, prioritizes Bitcoin Design safety patterns for
fees, receiving, and contact/address handling, and uses the Nothing-inspired
visual constraint for a neutral, sparse, high-contrast presentation. When those
sources conflict, wallet safety and clear reversibility rules take precedence.
