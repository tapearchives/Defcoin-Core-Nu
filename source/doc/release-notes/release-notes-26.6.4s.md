# Defcoin Core Nu 26.6.4s Release Notes

Defcoin Core Nu `26.6.4s` is a catch-up release note over the last documented
`26.6.4a` release note. It records the user-facing and backend changes now
present in the current Tahoe Nu build line.

## Fast Sync And LAN Block Copy

- Routes UDP Fast Sync through Core's normal block scheduling path so UDP is a
  transport choice for a Core-selected block, not a second independent block
  request path.
- Adds Core-side Fast Sync reservation support in `net_processing`, allowing the
  GUI service layer to request UDP transport only for blocks that Core has
  already selected from a peer.
- Adds clearer Fast Sync transport accounting in Metrics, separating Core chain
  advancement from receiver-confirmed UDP accepted blocks.
- Adds concise protocol-efficiency status text with TCP/UDP block-byte rates,
  accepted-block counts, failures, probe status, and favor ratio.
- Adds a guarded trusted-LAN block-copy path that uses LAN-discovered Nu peers,
  pauses ordinary P2P sync while active, requests sequential block heights from
  one selected LAN source over the existing UDP chunk transport, and submits
  each assembled block through Core acceptance.
- Keeps wallet data out of the LAN copy path. Wallets, private keys,
  passphrases, configs, peers, and ban files are never copied.
- Documents that the later full DCOL snapshot/chainstate clone remains a
  separate future workflow requiring backend shutdown, manifests, hashes, and a
  post-copy verification or reindex option.

## Metrics And Networking UI

- Renames the diagnostics surface to `Metrics` in the simplified advanced-tool
  layout.
- Moves network traffic graphing into the first Metrics tab.
- Tightens status rows so sync, traffic, Fast Sync TCP, Fast Sync UDP, and
  combined speed fields are more compact and less explanatory-noisy.
- Adds selectable/copyable status handling improvements in the Nu data table
  component.

## RPC Console

- Adds a standalone `RPC Console` advanced-tool view instead of keeping console
  behavior buried in Metrics.
- Reworks the console toward Litecoin Core's single-command-line style while
  preserving the Nu safe parser and wallet-aware RPC routing.
- Adds a wallet selector with node/global command support and active-wallet
  defaulting.
- Adds console font controls, clear-console action, scrollable/selectable
  history, and safer command handling for single commands, pasted multi-line
  commands, and compact repeated `addnode` input.

## Wallet And Receive UI

- Fixes generated receive-request row mapping so stored dates populate the Date
  column.
- Updates the main QR/address display when a generated request row is selected.
- Reflows the Inspect Address dialog so long addresses and explorer text do not
  clip in the popup.
- Adds advanced wallet tools for native paper-wallet generation and watch-only
  address import. Paper-wallet generation uses Core/Defcoin key handling rather
  than a vendored JavaScript generator and avoids logging or storing private
  keys.

## General Nu Interface

- Adds a compact page-header mode for table-heavy pages.
- Reduces large empty top panels and spacing on Home and list-heavy wallet
  pages so more transactions, requests, and rows are visible without scrolling.
- Keeps advanced tools hidden for new users by default while preserving the
  saved advanced-tool preference for existing users.
- Adjusts navigation ordering so advanced tools present as Mining, RPC Console,
  Metrics, then Settings.

## Developer Tooling And Documentation

- Adds Ruff configuration and pre-commit hook scaffolding for Python helpers.
- Adds an install script for local `pre-commit` setup.
- Applies Ruff cleanup to the Fast Sync sidecar and macOS bundle repair helper.
- Updates Fast Sync protocol documentation, Nu goals, and the functionality map
  to describe service-bit negotiation, Core-routed UDP transport, LAN block
  copy, and the future DCOL boundary.
