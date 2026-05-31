# Defcoin Core Nu 26.5.5w Release Notes

Codename: `Core Memories`

Defcoin Core Nu `26.5.5w` adds the first blockchain forensics surface to the
desktop wallet while keeping the chain, wallet, recovery, mining, and explorer
behavior from the current `26.5` line.

## Notable Changes

- Added a new `Forensics` section to the desktop UI.
- Added the first Forensics view, `Irregular Messages`, for unusual text
  payloads embedded permanently in OP_RETURN outputs.
- Added a separate Forensics `Witness Repair` tab for the post-`903168`
  short-block inspection/repair path. This lets users inspect and fix missing
  witness-form block storage without running the irregular-message scanner.
- Added a clean table showing `Block Height`, `Transaction ID`, `Burned Defcoin
  Amount`, `Decoded Text Message`, and a short irregularity label.
- Added a `BIP141 Definition` column for recognized witness-commitment headers,
  with a link to the authoritative BIP141 commitment-structure reference.
- Added a resizable pop-out irregular-message table with fixed-width font size
  controls, auto-fit column widths, manual column resizing, green-bar row
  striping, and the same selected-cell copy behavior as the embedded table.
- Added pause/resume scan behavior. Paused scans resume from their last scanned
  block, and completed scans turn the action button into `Rescan`.
- Added a completion summary reporting irregular block counts, the percentage
  of scanned blocks with irregular rows, non-`6a` script-prefix counts, and
  unique four-byte prefix percentages.
- Added a bounded native backend scan using accepted block data rather than
  slow UI-side block parsing.
- Flagged OP_RETURN cases include:
  - nonzero DFC burned into an unspendable output,
  - scripts above the standard 83-byte OP_RETURN relay size,
  - active execution opcodes after OP_RETURN,
  - multiple OP_RETURN outputs in one transaction.
- Added an experimental UDP fast-sync helper, enabled by default. Nu wallets can
  request raw block bytes in sub-MTU checksum-protected UDP chunks from connected
  Defcoin peers over IPv4 or IPv6 while the receiver still submits every
  assembled block through normal Core validation. LAN discovery additionally
  enables local broadcast.
- Updated UDP fast sync to probe packet size adaptively: safe 1232/1472-byte
  internet/default probes, plus 4096, 8192, 12000, and 16000-byte LAN/private
  probes when the receiver confirms clean checksum-valid blocks.
- Hardened UDP fast sync with datagram/header/payload caps, capability/version
  checks, bounded per-read processing, per-peer request throttling,
  duplicate-chunk rejection, and checksum validation before block assembly.
- Diagnostics > Status now shows the active sync method, UDP transfer rate in
  blocks/second and bytes/second, and retransmit/checksum errors. TCP/Core sync
  remains active as the fallback path.
- Forensics tables now render large result sets through bounded views so the app
  remains responsive when thousands of irregular rows are loaded.
- Routine non-text coinbase metadata that appears beside a normal BIP141 witness
  commitment is treated as regular miner metadata rather than as a hidden
  irregular message row.
- Peer diagnostics now display Reverse DNS normally while sorting it by hidden
  reverse-domain notation, with right-aligned Reverse DNS and LAN-aware Known
  DNS alignment.
- UDP fast-sync availability now reports capability state rather than mere
  Defcoin compatibility. Old non-Nu peers show `No`; Nu peers start as `TBA`
  until this session receives a valid UDP response or records a failed attempt.
- Witness Repair now reads stored block bodies to identify missing witness data,
  rather than relying only on chain-index flags.
- Explorer status text now wraps inside its panel instead of being covered by
  tabs or action buttons.
- Explorer indexing now processes blocks in batched RPC requests and batched
  SQLite writes. This removes the previous one-block-at-a-time 120 ms throttle
  and substantially improves initial index build speed on modern SSD systems.
- Explorer indexing now has a clearer `High intensity (uses more resources)` mode.
  It uses larger Explorer and Top 100 batches, larger SQLite cache settings,
  fewer UI refreshes, and a best-effort process priority increase.
- The fast-sync TCP/UDP selector now compares only peers that can actually be
  tested over both paths. UDP-capable peers get warmup probes before Nu declares
  a preference.
- Witness block-storage inspection now uses a bounded worker count derived from
  Core's `-par` script-verification setting, then aggregates independent block
  inspection results back into one ordered report.
- Explorer Top 100 column headers now explain `Txs` and `UTXOs`, including why
  high mining-payout addresses can show very different transaction and UTXO
  ratios.
- Explorer index progress and analytics summary text are now shown as separate
  stable lines, eliminating the short-lived `Loaded Top...` repaint flicker.
- Explorer Top 100 and movement analytics now refresh in a background worker
  instead of running large SQLite scans on the UI thread. This targets the
  beachball seen when opening Explorer after a completed full index.
- Explorer analytics are deferred until the Explorer page is opened, so ordinary
  app launch on Home no longer starts the expensive Top 100/movement summary
  queries.
- Explorer analytics are also scoped by tab: opening `Top 100` loads Top 100
  data only, opening `Movements` loads movement rows only, and the explicit
  `Refresh stats` action remains the full refresh.
- Explorer no longer auto-runs the Top 100 refresh just because the block index
  is already current at launch.
- Diagnostics > Log now shows both visible-row numbers and source debug-log
  line numbers, and includes reliable `Copy shown` and `Save launch log`
  actions.
- LAN workstation lookup now retries when LAN discovery is enabled and uses host
  lookup, ping, and ARP hints before leaving workstation details blank.

## Build Suffix

`26.5.5w` is the current changed rebuild in the `26.5.5` line. Future changed
rebuilds in the same release line should use the next letter suffix
(`26.5.5d`, `26.5.5e`, and so on), while the inherited Core client version
stays `0.21.5.5`.

## Technical Notes

The new `scanirregularmessages` RPC scans the active chain in chunks and returns
only flagged rows. It uses `CBlock` transaction data, checks unspendable
OP_RETURN outputs, decodes pushed payload bytes as printable text where
possible, and leaves consensus state unchanged.

The UDP fast-sync helper is Defcoin-native Qt/C++ code rather than a direct
copy of Solana, libp2p, or go-ethereum QUIC transports. Those projects were
reviewed as design references, but their async networking stacks are not
drop-in compatible with this Litecoin-derived Core process. Nu therefore keeps
the acceleration layer narrow, optional, connected-peer scoped, and
validation-preserving.

Technical details are maintained in
`doc/defcoin-core-nu-technical-guide.md`.
