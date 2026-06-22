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

### 26.6.8-alpha - 2026-06-20 - Nu Alpha Release Rollup

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
- Settings > Display includes external blockchain explorer presets and
  separate transaction/address custom URL templates.
- Peer, seed, Trippy, LAN discovery, UDP Fast Sync, Quick Clone, shutdown, and
  mining monitor UI were tightened for clearer status and cross-platform parity.
- Nu branding uses the locked DEFCOIN / CORE NU logo ratios for splash, About,
  navigation, icons, and DMG artwork.

Packaging notes:

- Build/package only `DefcoinCoreNuResources` for Nu.
- Stage Nu Apple Silicon artifacts under
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.8-alpha-20260620/apple-silicon`.
- Stage Nu Windows artifacts under
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.8-alpha-20260620/windows11-x86_64`.
- Generated update-feed files should stay in their feed subdirectory and not be
  confused with user-facing installers or portable ZIPs.

Verification targets:

- `git diff --check`
- Tahoe app bundle metadata and bundled backend tools report the same
  `26.6.8-alpha` label.
- Nu Apple Silicon app and DMG verify locally.
- Windows setup and portable ZIP contain only Nu app/runtime files and no
  source companion docs or Finder metadata.
- Lion/Catalina ports keep menu order, logo assets, Wallets table columns,
  Metrics order, hover text, RPC Console, Mining presets, and Debug Log parity
  with Tahoe where the older Qt stack permits it.

### 26.6.7p - 2026-06-17 - Nu Bundle Pruning

- Nu staging removes source-only `.agent.md` companion notes and non-wallet QML
  from the runtime bundle.
- Generated Finder/Python/Ruff cache files and stale paper-wallet placeholder
  art were removed from the active Nu source tree.
- The staged Nu bundle was verified to exclude `.agent.md` files, non-wallet
  QML, `.DS_Store`, and stale placeholder images.

### 26.6.4x - 2026-06-04 - Nu Distribution Boundary

- Nu-only fixes should build and package only `DefcoinCoreNuResources`.
- Public Nu distribution folders should contain only `Defcoin Core Nu.app`,
  Nu installers, Nu portable archives, Nu checksums, and Nu documentation.
- Older local distribution folders may contain historical mistakes; correct
  them only when preparing those folders for use or publication.
