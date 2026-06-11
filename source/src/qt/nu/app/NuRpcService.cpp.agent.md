# NuRpcService.cpp Agent Notes

## Purpose

Main C++ bridge between the Nu QML frontend and the Defcoin backend. Owns RPC orchestration, wallet actions, Metrics rows, peer metadata, Fast Sync UDP transport, Quick Clone UI/scaffolding, traffic counters, paper wallet/watch-only helpers, and diagnostic logs.

## Nu Divergence

- Implements UDP Fast Sync probe/ack/request/chunk handling using capability string `defcoin-nu-udp-fast-sync-v1`.
- Calls `reservefastsyncblock` so UDP block transfer follows Core peer/block reservation and normal Core validation.
- Tracks TCP totals from Core `getnettotals`, UDP totals from Nu Fast Sync/Quick Clone sockets, and Quick Clone as a subset of UDP for diagnostics/CSV.
- Implements Quick Clone user prompt/status scaffolding as trusted LAN public-chain copy only; wallet/private/config data must never be copied.
- Provides the standalone Nu RPC Console parser, peer table enrichment, workstation discovery display, paper wallet generation, watch-only import, and selectable diagnostic output.
- Backs up the active wallet selected in Nu. The default backup filename must include the active wallet display/storage identity (`wallet_<name>.dat` for BDB, `wallet_<name>.sqlite` for SQL) rather than blindly offering `wallet.dat`.

## Do Not Break

- Do not count Quick Clone UDP outside UDP totals; Quick Clone can have subset counters, but chart/footer totals must remain TCP + UDP.
- Do not submit UDP block data without a backend reservation and checksum verification.
- Do not let service bit 29 alone mark a peer usable; the peer must probe/ack successfully.
- Do not write generated paper-wallet private keys to logs, settings, address books, or files.
- Do not copy wallets, keys, passphrases, configs, peers, bans, address books, or RPC cookies in Quick Clone code.
- When `node_unique_id` identifies two host paths as the same Nu install, Fast Sync/Quick Clone should count them as one logical in-flight source; the alternate host is fallback, not a second independent sender.
- Keep status strings concise in normal mode and put verbose diagnostics behind Details.
- During Tahoe UDP testing, macOS Local Network "Allow" is a hard external gate; failed probes before Allow are not code evidence.
- Do not make backup UI imply a different wallet than the active one. If wallet naming/storage detection changes, update `walletBackupDefaultFileName()` and smoke-test both BDB and SQL wallet names.
- Peer table grouping is display-only: the visible Node cell may append `(gN)` when multiple current rows appear to be the same running Nu node, but row metadata and peer actions must keep Core's real numeric peer id.

## Cross-Build Notes

- Lion shares the same behavior but has older Qt constraints; avoid newer Qt APIs unless a Lion fallback is documented.
- Server builds need Fast Sync transport behavior but not the full Nu UI or Quick Clone prompt.
- Windows builds need the same metrics/counter semantics so UI comparisons are meaningful.

## Verification

- `git diff --check`
- Build Nu frontend after functional changes.
- Smoke-test the touched QML/RPC path.
- For Fast Sync changes, confirm probe ack, reservation, chunk receipt, checksum, `submitblock`, and accepted-block counters in logs.
