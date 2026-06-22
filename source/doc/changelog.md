# Defcoin Core Nu Changelog

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
