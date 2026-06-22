# Defcoin Core Nu Cross-Build Change Log

This ledger tracks Nu wallet changes that must stay aligned across Tahoe,
Lion/Catalina, and Windows builds. Keep entries Nu-only: sibling products,
screenshots, packaging artifacts, and roadmap notes do not belong in this
repository unless explicitly requested for a Nu release.

## Current Public Boundary

- The Nu repository builds and packages `DefcoinCoreNu` only.
- Nu release artifacts live under `Distribution_Versions/Defcoin Core Nu/...`.
- External block explorer URLs are settings-controlled browser links only; no
  sibling product is bundled into Nu.
- Wallet, node, mining, Metrics, RPC Console, Debug Log, Fast Sync, Quick
  Clone, and packaging changes must be ported or intentionally documented for
  each supported platform.

## Entries

### 26.6.8e-alpha - 2026-06-22 - Nu-only release boundary and Windows parity

Big picture:
- Carry the active Tahoe alpha work forward after removing stale sibling-product
  source, assets, screenshots, changelog entries, and packaging rules from the
  Nu repository.
- Produce a matching Windows 11 x86_64 build from the same Nu-only source state.

Porting notes:
- Windows must package only `DefcoinCoreNu` resources and must not carry
  non-Nu QML, data files, icons, screenshots, or release notes.
- Tahoe and Windows visible labels, About/build metadata, bundled backend tools,
  portable ZIP names, installer names, and checksum assets should all use
  `26.6.8e-alpha`.

Verification targets:
- `git diff --check`.
- Tahoe app bundle metadata and bundled backend tools report the same
  `26.6.8e-alpha` label.
- Nu Apple Silicon app and DMG verify locally.
- Windows setup and portable ZIP contain only Nu app/runtime files and no
  source companion docs or Finder metadata.

### 26.6.8d-alpha - 2026-06-22 - Mining pool benchmarking

Big picture:
- Add a Tahoe Mining > Benchmark Pools tab for comparing saved preset/custom
  mining pools with repeated timed runs.

Changed behavior:
- The benchmark reuses saved miner settings, cycles through preset pools plus a
  distinct custom pool, pings each host before mining, records hashrate, raw
  accepted shares, accepted share-difficulty work/s, ping, and restart timing,
  and autosaves latest plus timestamped JSON/PNG chart artifacts.
- Pool comparison uses accepted work/s rather than raw accepted share count
  because pools may assign different share difficulty.
- The live benchmark line shows current pool elapsed time and time left, while
  the summary uses `Time left` instead of ETA wording.

Porting notes:
- Windows builds need the same bounded miner-log parser, accepted-rate mast
  field, and benchmark chart/stat persistence.

### 26.6.8c-alpha - 2026-06-22 - LAN peer polish and scoped IPv6 discovery

Big picture:
- Keep peer-table grouping readable without corrupting Core peer ids, and keep
  LAN discovery usable on dual-stack networks where macOS advertises scoped
  IPv6 link-local addresses.

Changed behavior:
- LAN discovery beacons include usable IPv6 link-local addresses with scope ids,
  and Tahoe sends discovery to IPv6 all-nodes multicast in addition to IPv4
  broadcasts.
- Core P2P addnode attempts skip scoped IPv6 link-local endpoints that Core
  cannot route reliably, while Nu UDP can still probe and request Quick Clone
  data from those addresses.
- Quick Clone wait text identifies the receiver-local backend scheduling or
  peer-identification gate instead of saying "waiting for Core peer selection".
- Peer table grouping stays display-only: the Node column remains Core's raw
  numeric peer id and same-node groups are shown in the source/workstation
  column as `G1: Name`.

Porting notes:
- Port the Nu LAN behavior together across Tahoe, Windows, and Lion. IPv6
  link-local scope ids must be preserved for Nu UDP discovery, probes, and
  Quick Clone requests, IPv6 all-nodes multicast should be joined/sent per
  active interface, and scoped link-local endpoints must not be handed to Core
  `addnode`.

### 26.6.8a-alpha - 2026-06-21 - SQL descriptor managers and Lion parity fixes

Big picture:
- New SQL descriptor wallets should be structurally ready for every Defcoin
  descriptor type the current code can parse and store, without making future
  paths active before they are supported in the product.

Changed behavior:
- Newly created SQLite descriptor wallets store active external/internal P2PKH,
  P2SH-SegWit, and Bech32 managers plus inactive reserved MWEB receive/change
  descriptors.
- Missing inactive manager lookups return `nullptr` silently instead of writing
  scary debug-log noise for every absent output type.

Porting notes:
- Port the wallet changes together across Tahoe, Lion, and Windows backend
  trees: `wallet.cpp`, `scriptpubkeyman.cpp`, and `scriptpubkeyman.h`.

### 26.6.8-alpha - 2026-06-20 - Nu alpha release rollup

Big picture:
- Visible Nu release label advances from the local `26.6.7z` candidate line to
  `26.6.8-alpha`.
- This alpha consolidates superseded 26.6.x local candidate notes into a
  release-test line for the Nu wallet.
- Known experimental areas remain Fast Sync, Quick Clone/DCOL, and Mining Pool
  Benchmarking.

Changed behavior:
- Wallets tab adds richer wallet table stats, create/restore refinements,
  passphrase validation, BIP39 phrase creation/restore, optional SQL descriptor
  recovery, watch-only address tools, and message-signing guidance.
- Paper Wallet supports local entropy collection, BIP38 handling, preview,
  pop-out review, print controls, and Design 1 polishing.
- RPC Console includes the restored Debug Log tab with line numbers, filters,
  find, copy, save, open-log, and font-size controls.
- Settings > Display includes external blockchain explorer presets and separate
  transaction/address custom URL templates.
- Peer, seed, Trippy, LAN discovery, UDP Fast Sync, Quick Clone, shutdown, and
  mining monitor UI were tightened for clearer status and cross-platform parity.
- Nu branding uses the locked DEFCOIN / CORE NU logo ratios for splash, About,
  navigation, icons, and DMG artwork.

### 26.6.7p - 2026-06-17 - Nu bundle pruning

- Nu staging removes source-only `.agent.md` companion notes from the runtime
  bundle.
- Generated Finder/Python/Ruff cache files and stale paper-wallet placeholder
  art were removed from the active Nu source tree.
- The staged Nu bundle was verified to exclude `.agent.md` files, `.DS_Store`,
  and stale placeholder images.
