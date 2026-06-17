# NuRpcService.cpp Agent Notes

## Purpose

Main C++ bridge between the Nu QML frontend and the Defcoin backend. Owns RPC orchestration, wallet actions, Metrics rows, peer metadata, Fast Sync UDP transport, Quick Clone UI/scaffolding, traffic counters, Nu paper-wallet helpers, watch-only helpers, and diagnostic logs.

## Nu Divergence

- Implements UDP Fast Sync probe/ack/request/chunk handling using capability string `defcoin-nu-udp-fast-sync-v1`.
- Calls `reservefastsyncblock` so UDP block transfer follows Core peer/block reservation and normal Core validation.
- Tracks TCP totals from Core `getnettotals`, UDP totals from Nu Fast Sync/Quick Clone sockets, and Quick Clone as a subset of UDP for diagnostics/CSV.
- Implements Quick Clone user prompt/status scaffolding as trusted LAN public-chain copy only; wallet/private/config data must never be copied.
- Provides the standalone Nu RPC Console parser, peer table enrichment, workstation discovery display, Explore paper wallet generation/printing, watch-only import, and selectable diagnostic output.
- Generates paper-wallet keys and current Defcoin P2PKH addresses locally through Core-compatible secp256k1, SHA256, RIPEMD160, and Base58Check code; optional watch-only import sends only the public address to RPC.
- Paper-wallet secret material must mix user-provided QML entropy with
  OpenSSL/platform cryptographic randomness and domain-separated SHA512 rounds.
  When OpenSSL exposes a private-key DRBG, use `RAND_priv_bytes()` rather than
  the public `RAND_bytes()` path.
  Generated BIP39 recovery phrases must use the same frontend randomness helper,
  not plain UI-state or user entropy alone.
- Keeps paper-wallet QR images and generated entries as in-memory data URLs/state
  and provides a foldable Letter print layout ported from liteaddress.org's
  artistic paper-wallet coordinate model: three 486x261-style strips per page,
  left public QR, right private-key QR, rotated address/key lanes, and fold/tear
  guides. The printout also uses security-document visual language: checker and
  diagonal patterns around QR fields plus wavy center guilloche-style lines
  behind the v26 coin. Design 1 is the standard full-sheet strip layout with
  large QR modules, tight QR quiet zones, side-panel security patterns, and a
  private-key exposure warning; Design 2 is a full-width tri-fold whose panels
  stay page-aligned while QR/text/coin elements rotate inside their own panels;
  Design 3 targets
  Avery 5011 place cards as a two-pass sheet aligned to the official six-card
  template: page 1 renders one wallet per tent card with the bottom half as the
  visible cover and the top half as the upside-down public-address/amount face;
  page 2 mirrors card slots for reinserting the sheet into the printer
  (`1->6`, `2->5`, `3->4`, etc.) and renders right-side-up private-key faces
  plus an instructions panel on the back of each matching card.
  Design 4 is the simple two-card public/private sheet. Hide Art must remove
  the decorative squiggle/security background while preserving readable QR,
  text, and borders.
  Design 5 is a two-page landscape renderer based on `sibios/defcoin-bulk`:
  it uses the original `defcoin-front-300dpi.png` and
  `defcoin-back-300dpi.png` artwork, prints wallet fronts first and matching
  backs second, fixes page capacity at two landscape wallets per page, and
  overlays only bounded Nu-generated QR/text data. Public/private text lanes
  must stay clipped inside their artwork slots, with tight white backing for
  readable forward text and dark backing for inverted print-through areas. Hide
  Art must remove the ink-heavy purple artwork and coins but keep the original
  static/noise square, replace the Portland Hackerspace graphic with the
  low-ink BrainSilo memorial text/logo treatment, and leave the page otherwise
  blank.
  Key
  generation and QR creation remain in Core-native Nu code rather than importing
  the 2014 browser cryptography stack.
  Design 1's private-key lane must split long WIF/BIP38 output across two
  rotated Atkinson Hyperlegible Mono lines, with the first line ending on a
  six-character group boundary when possible; keep panel 3's QR/checker area
  slightly narrower so the secret lane does not clip.
  Keep `DFC` visible on printed designs. Do not replace this with a generic
  multi-page print document. The printout uses the pure v26 coin mark; the GUI
  preview itself stays unbranded. Preview and print may render placeholder
  entries before entropy is complete for printer alignment testing, but those
  pages must carry an explicit unusable/test-print warning. Optional BIP38
  encryption uses OpenSSL scrypt/AES, requires a minimum 12-character
  passphrase unless the UI's explicit weak-phrase override is enabled, and
  fails closed if encryption cannot complete.
- Paper-wallet regeneration keeps generated secrets in service-owned memory so
  changing preview/customization settings does not replace already shown public
  addresses. Increasing the wallet count appends new secrets; toggling BIP38
  re-encodes existing secrets while preserving their public addresses. Clearing
  Paper Wallet must cleanse this secret vector.
- Printed key/address lanes use Atkinson Hyperlegible Mono with subtle
  group-guide lines and rotating theme-color dots every six characters to make
  manual transcription easier without altering the key text.
- Refuses non-loopback RPC targets by default for Nu UI operations; remote RPC is an explicit operator override via `DEFCOIN_NU_ALLOW_REMOTE_RPC=1`.
- Limits automatic update download/apply to Velopack-managed installs. GitHub release fallback opens the release page for manual download instead of trusting package and checksum from the same release channel.
- Throttles in-app miner log UI updates so high-volume miner output does not force continuous QML text re-rendering.
- On Windows, assigns Nu-owned backend, miner, traceroute, and helper child processes to a kill-on-close job object so crash paths do not leave mining/backend processes running unattended.
- Seed/source attribution may include protocol-verified fixed address aliases for public Defcoin operators. These aliases affect peer display only and must not silently become Core bootstrap seeds.
- Backs up the active wallet selected in Nu. The default backup filename must include the active wallet display/storage identity (`wallet_<name>.dat` for BDB, `wallet_<name>.sqlite` for SQL) rather than blindly offering `wallet.dat`.
- Installs placeholder paper-wallet data for `--ui-self-test` only. This path
  is gated by `DEFCOIN_NU_UI_SELF_TEST_ACTIVE`, uses clearly fake key/address
  text, keeps QR images in memory, and exists only to exercise the preview and
  print/popout UI without deriving real keys.
- Funds Nu paper wallets through `fundPaperWallets()`, which validates generated
  public addresses and positive DFC amounts before using wallet-scoped
  `sendmany`. This path never receives or sends generated private keys.
- Imports paper-wallet private keys through `importPaperWalletPrivateKey()`.
  The bridge sends the WIF directly to wallet-scoped Core RPC `importprivkey`
  with a rescan request, refreshes wallet state, and emits user-facing guidance.
  The current sweep option is conservative: it imports/rescans first and tells
  the user to move confirmed funds after the balance is visible rather than
  constructing an automatic sweep transaction in the same call.

## Do Not Break

- Do not count Quick Clone UDP outside UDP totals; Quick Clone can have subset counters, but chart/footer totals must remain TCP + UDP.
- Do not submit UDP block data without a backend reservation and checksum verification.
- Do not let service bit 29 alone mark a peer usable; the peer must probe/ack successfully.
- Do not write generated paper-wallet private keys to logs, settings, address books, or files.
- Do not derive generated paper-wallet addresses by sending WIF/private keys through RPC descriptor commands.
- Do not make `QRandomGenerator` or user entropy the only randomness source for
  generated paper-wallet keys or recovery phrases. Keep temporary private-key,
  BIP38, seed, and mnemonic byte buffers cleansed with `secureClear()` where Nu
  owns the memory.
- Do not silently downgrade BIP38 requested output to unencrypted WIF output.
  Trivial/empty BIP38 passphrases are allowed only when the user explicitly
  enables the weak-phrase override in the Paper Wallet view.
- Keep paper-wallet private-key QR images in memory; do not route WIF QR generation through temp files or external URLs.
- Do not enable remote RPC by default or silently send RPC credentials/private wallet material to non-loopback hosts.
- Do not auto-install GitHub release fallback packages unless the update trust model is redesigned; use Velopack for managed updates.
- Do not copy wallets, keys, passphrases, configs, peers, bans, address books, or RPC cookies in Quick Clone code.
- When `node_unique_id` identifies two host paths as the same Nu install, Fast Sync/Quick Clone should count them as one logical in-flight source; the alternate host is fallback, not a second independent sender.
- Keep status strings concise in normal mode and put verbose diagnostics behind Details.
- Keep miner log updates throttled and capped; do not emit `minerChanged` for every raw miner output chunk.
- Keep Windows child-process job containment on every Nu-owned `QProcess` start path.
- During Tahoe UDP testing, macOS Local Network "Allow" is a hard external gate; failed probes before Allow are not code evidence.
- Do not make backup UI imply a different wallet than the active one. If wallet naming/storage detection changes, update `walletBackupDefaultFileName()` and smoke-test both BDB and SQL wallet names.
- Peer table grouping is display-only: the visible Node cell may append `(gN)` when multiple current rows appear to be the same running Nu node, but row metadata and peer actions must keep Core's real numeric peer id.
- Do not let paper-wallet self-test placeholders run outside
  `DEFCOIN_NU_UI_SELF_TEST_ACTIVE`.
- Keep `DEFCOIN_NU_PAPER_WALLET_PDF` test-only. It may render the print sheet
  during `--ui-self-test` with fake placeholder keys, but it must not bypass the
  normal user-confirmed print dialog during ordinary launches. When the render
  is explicitly test-only, the hide-art argument must be honored even if
  placeholder self-test data marks the wallet state ready.
- Keep `paperWalletPreviewPageSources()` on the same rendering code path as
  `printPaperWallet()`. Preview pages may use in-memory placeholder entries
  before generation, but the artwork, page geometry, QR placement, and
  double-sided page ordering must come from `renderPaperWalletPages()`.
- Keep paper-wallet funding public-address-only and wallet-scoped. Do not add a
  QML-side spending path that bypasses Core wallet transaction creation.
- Keep paper-wallet private-key import local, wallet-scoped, and transient. Do
  not log the WIF, store it in settings, or pass it through QML funding paths.

## Cross-Build Notes

- Lion shares the same behavior but has older Qt constraints; avoid newer Qt APIs unless a Lion fallback is documented.
- Server builds need Fast Sync transport behavior but not the full Nu UI or Quick Clone prompt.
- Windows builds need the same metrics/counter semantics so UI comparisons are meaningful.

## Verification

- `git diff --check`
- Build Nu frontend after functional changes.
- For paper-wallet layout changes, render the affected design through
  `DEFCOIN_NU_PAPER_WALLET_PDF` or the preview data-URL path and inspect the
  rasterized page before treating the layout as done.
- Smoke-test the touched QML/RPC path.
- For Fast Sync changes, confirm probe ack, reservation, chunk receipt, checksum, `submitblock`, and accepted-block counters in logs.
