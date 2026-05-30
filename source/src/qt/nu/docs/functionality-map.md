# Defcoin Core Nu 26.5.5b Functionality Map

This map is the release checklist for preserving useful Litecoin Core wallet
capabilities while reorganizing them into the Nu interface. Nu does not copy
the old tab order. It groups functions by user intent: hold, send, receive,
review history, manage wallets, inspect the node, and configure the app.

## Primary Nu Surfaces

| Nu surface | Purpose | UI rationale |
| --- | --- | --- |
| Status strip | Network state, peer count, block height, sync state, wallet lock state | One persistent health strip avoids repeating the same node state in several places. |
| Home | Balances, recent activity, quick receive/send access, privacy mask | Immediate wallet state should be visible without diagnostic clutter. |
| Send | Address book, recipient, label, amount, fee intent, custom fee, subtract-fee option, optional custom change address, PSBT tools, review, broadcast | Irreversible money movement gets its own focused flow and final review. |
| Receive | Payment request form, real receiving address, QR URI, request history | Incoming payments stay separate from send risk. |
| Activity | Transaction history, date/type/search filters, CSV export | History is a retrieval task, not part of payment composition. |
| Wallet | Wallet files, backup, BIP39 recovery, compatibility encoding tools, passphrase protection, message signing, and address book | Key and wallet maintenance are now first-class wallet tasks instead of being buried under Settings. |
| Mining | External miner executable setup, pool presets, CPU thread/nice settings, and miner output | Mining helpers stay separate from wallet spending and node diagnostics. |
| Explorer | Local block, transaction, address, rich-list, and movement lookups | Chain-wide public data stays separate from wallet-owned funds and keys. |
| Forensics | Irregular OP_RETURN message discovery | Blockchain oddities are readable without exposing raw RPC or requiring manual block scans. |
| Diagnostics | Status, peers, traffic, debug log, local RPC console | Node transparency is preserved while keeping it out of the main wallet path. |
| Settings | Network controls, display behavior, update checks, and background-close behavior | App preferences stay together; wallet operations live in Wallet. Node diagnostics stay in Diagnostics. |

## Litecoin Core Feature Mapping

| Litecoin Core feature | Nu location | Backend/API | Nu status | Rationale |
| --- | --- | --- | --- | --- |
| Overview balances | Home | `getwalletinfo` | Direct UI | Home answers the most common wallet question first. |
| Recent transactions | Home, Activity | `listtransactions` | Direct UI | Short feed on Home, full list in Activity. |
| Transaction filters | Activity | local filtering of `listtransactions` | Direct UI | Search/filter is kept with history. |
| Export transaction CSV | Activity | local CSV export | Direct UI | Explicit user file action. |
| Send coins | Send | `sendtoaddress` | Direct UI | Dedicated payment path. |
| Review before send | Send | local review dialog before RPC | Direct UI | Safety-first confirmation for irreversible actions. |
| Address book/contact picker | Send, Wallet | `listlabels`, `getaddressesbylabel`, `listreceivedbyaddress`, `setlabel` | Direct UI | Contacts appear where they are used and remain visible in Wallet. |
| Label recipient address | Send | `setlabel` after send | Direct UI | Preserves wallet metadata. |
| Open Defcoin URI | File > Open URI, Send recipient field | URI parsing before send | Direct UI | Preserves Litecoin Core's Open URI path while keeping final review in Send. |
| Fee target | Send | `sendtoaddress` `conf_target` | Direct UI | Fee intent belongs with payment composition. |
| Estimate mode | Send | `sendtoaddress` `estimate_mode` | Direct UI | Recommended and economical modes stay simple. |
| Custom fee rate | Send | `sendtoaddress` / `send` `fee_rate` | Direct UI | Advanced but common enough to expose near fee mode. |
| Subtract fee from amount | Send | `sendtoaddress` / `send` subtract-fee options | Direct UI | User must understand who pays the fee before review. |
| Custom change address | Send advanced options | `send` `change_address` | Direct UI | Useful but separated from the primary send form. |
| Load PSBT from file | Send advanced options | `analyzepsbt`, `walletprocesspsbt`, `finalizepsbt`, `sendrawtransaction` | Direct UI | Preserves the inherited advanced signing workflow without putting it in the primary send path. |
| Load PSBT from clipboard | Send advanced options | same as file PSBT flow | Direct UI | Matches Litecoin Core's clipboard import path. |
| PSBT sign/finalize/save/copy/broadcast | Send advanced options | PSBT RPCs | Direct UI | Advanced controls are grouped and disabled until a PSBT is loaded/finalized. |
| Coin control input selection | Diagnostics > Console | `listunspent`, `lockunspent`, `send` options | Advanced RPC | Powerful and risky; preserved without crowding the primary payment UI. |
| Receive address | Receive | `getnewaddress` | Direct UI | Focused incoming-payment path. |
| Payment request label/amount/message | Receive | `getnewaddress`, local `defcoin:` URI | Direct UI | Classic request fields remain present. |
| Receive QR | Receive | local QR generation from real URI | Direct UI | QR represents the generated address/request, not placeholder art. |
| Requested payments history | Receive | current-session request rows | Direct UI | Generated requests are visible in the Receive workflow. |
| Backup wallet | File menu, Wallet | `backupwallet` | Direct UI | Standard desktop convention plus wallet maintenance location. |
| Create/restore BIP39 wallet | File menu, Wallet | `createwallet`, `sethdseed`, `importdescriptors`, `deriveaddresses` | Direct UI | Recovery phrases are visible wallet operations with checksum validation and preview-gated external import. |
| Convert extended keys / P2SH forms | Wallet | Local Base58Check conversion | Direct UI | Shows `xpub/xprv` and `dfcp/dfcv` equivalents, and canonical `M...` P2SH equivalents for old `3...` or tool `9/A...` forms. |
| Encrypt wallet | Wallet > Passphrase protection > Wallet security | `encryptwallet` | Direct UI | State-aware wallet security dialog encrypts unencrypted wallets. |
| Lock/unlock wallet | Diagnostics > Console | `walletlock`, `walletpassphrase` | Advanced RPC | Available without placing passphrase handling into QML forms. |
| Change passphrase | Wallet > Passphrase protection > Wallet security | `walletpassphrasechange` | Direct UI | The same state-aware wallet security dialog changes passphrases for encrypted wallets; unencrypted wallets get an explanatory backend message if this path is reached. |
| Remove wallet encryption | Wallet > Passphrase protection > Wallet security | Not supported by Core wallet RPC | Explanatory UI | Core wallets do not provide a safe in-place decrypt operation. The dialog explains that users must migrate to a new unencrypted wallet if they want to stop using passphrase protection. |
| Sign message | Wallet > Message signing | `signmessage` | Direct UI | Legacy proof-of-address workflow is preserved but not mixed into payment sending. |
| Verify message | Wallet > Message signing | `verifymessage` | Direct UI | Legacy proof verification is preserved near wallet maintenance tools. |
| Unit selection | Wallet note, RPC console | display/RPC support | Minimal direct UI | Nu starts with DFC for clarity; backend units remain available. |
| Third-party explorer links | Settings > Display, Activity/details dialogs | config/RPC data | Direct UI | Optional external links are shown only when explicitly enabled. |
| Network active toggle | Settings > Network | `setnetworkactive` | Direct UI | Network control belongs with network state. |
| Peer table | Diagnostics > Peers | `getpeerinfo` | Direct UI | Diagnostic transparency without the old inspector-heavy layout. Includes the actual P2P magic bytes selected from the peer packet header. |
| Peer ping | Diagnostics > Peers | `ping` | Direct UI | Operational diagnostic kept close to peers. |
| Network traffic | Diagnostics > Traffic | sampled `getnettotals` | Direct UI | At-a-glance connectivity health. |
| UDP fast sync | Settings > Network, Diagnostics > Status | Nu UDP helper + backend `submitblock` | Experimental direct UI | Enabled by default. Connected-peer sub-MTU block mirroring can accelerate wallet catch-up over IPv4/IPv6 without bypassing Core validation or disabling TCP fallback. |
| Debug log tail | Diagnostics > Log | `debug.log` tail | Direct UI | Read-only, scoped diagnostics. |
| Open full debug log | Diagnostics > Log | system open `debug.log` | Direct UI | Maintenance action stays with diagnostic log context. |
| RPC console | Diagnostics > Console | local JSON-RPC | Direct UI for advanced users | Preserves full Litecoin/Defcoin command surface while keeping ordinary users on safer flows. |
| Irregular OP_RETURN messages | Forensics > Irregular Messages | `scanirregularmessages` | Direct UI | Flags accepted-chain message outputs that bypass standard relay expectations or burn DFC. |
| Witness block storage repair | Forensics > Witness Repair | `repairwitnessblockdata` | Direct UI | Inspects and optionally rewinds/redownloads post-activation blocks whose local stored bodies are missing witness data, without loading the irregular-message table. |
| About | About menu, Settings > About | local text/assets | Direct UI | Standard desktop behavior retained. |
| Options/preferences | Settings | QML settings + RPC | Direct UI | Duplicate controls removed; Defcoin user-agent filter appears in Network only. |

## Defcoin Network Features

| Feature | Nu location | Status |
| --- | --- | --- |
| Defcoin-only peer user-agent filtering | Settings > Network, Diagnostics peer table | Implemented as `/Defcoin` prefix only |
| Network connect/isolate control | Settings > Network and status strip | Implemented |
| Dual magic migration control | Settings > Network | Implemented as startup option for accepting both legacy `fbc0b6db` and new `defc014e` peer message bytes. In dual mode, outbound handshakes prefer the new `defc014e` bytes while bounded legacy probes keep old-only Defcoin peers reachable; with dual mode off, the backend uses new Defcoin magic only. |
| UDP fast sync | Settings > Network, Diagnostics > Status | Experimental helper using sub-MTU chunked UDP block transfer from connected Defcoin peers and normal `submitblock` validation. LAN discovery adds local broadcast; TCP/Core sync stays active as fallback. |
| Network traffic graph | Diagnostics > Traffic | Implemented in neutral form |
| Debug log tab/readout | Diagnostics > Log | Implemented |
| Mask balances | Home | Implemented |
| Defcoin branding and Nu assets | App bundle, splash, About, nav | Implemented |

## Completeness Rule

Every original Litecoin Core wallet capability is either:

1. promoted into a direct Nu UI flow because it is common and benefits from a
   safer, clearer design; or
2. available through the local RPC console because it is advanced, dangerous,
   rare, or requires a dedicated security review before being given a custom
   QML form.

This keeps the Nu interface sparse without deleting backend capability.
