# Cross-Build Internal Change Log

This file is the internal porting ledger for Defcoin Core Nu. Update it for
every Tahoe Nu build that changes behavior, build metadata, UI, backend
interfaces, packaging, or developer assumptions. It is not a user-facing release
note. Its audience is Codex, especially threads building the Lion Intel iMac,
Catalina UTM, Windows, and server variants.

## How To Use This File

For each new build:

1. Add a new version entry at the top of `Entries`.
2. Include the previous version it was based on.
3. Separate what must be ported from what is Tahoe-only.
4. Explain intent and hidden assumptions that a code diff will not reveal.
5. List exact files/functions when porting is likely non-obvious.
6. Include verification commands and the observed result.
7. Note whether Lion, Catalina, Windows, and server builds need equivalent work.

## Entry Template

```text
### <version> - <YYYY-MM-DD> - <short title>

Big picture:
- ...

Porting priority:
- Lion Intel:
- Catalina UTM:
- Windows:
- Server:

Changed behavior:
- ...

Changed files and important details:
- path: why it changed; what to port; what not to port.

Compatibility notes:
- ...

Build/package notes:
- ...

Verification performed:
- command/result

Risks / follow-up:
- ...
```

## Entries

### 26.6.4bk - 2026-06-09 - Prefer LAN Fast Sync sources when available

Big picture:
- The Lion isolation run proved UDP Fast Sync can accept blocks through Core
  validation, but the selector could still choose public Fast Sync peers over a
  verified wired-LAN Tahoe peer because "previously used" public peers scored
  higher than "private/local" peers. Public UDP timeouts then made LAN UDP look
  slower than it really was.
- This build keeps Fast Sync as a transport-only path through Core reservation,
  but source selection now treats eligible private/local peers as the first
  choice pool. Public UDP peers compete only when no eligible LAN/private peer
  can provide the next block.

Porting priority:
- Lion Intel: required. This exact selector change must be ported before using
  Lion throughput results to judge LAN UDP performance.
- Catalina/Windows: required if those builds expose Fast Sync.
- Server: no change needed for responder-only service, but requester-side server
  builds should take the same source-selection rule.

Changed behavior:
- Tahoe visible version becomes `26.6.4bk`.
- If at least one eligible private/local Fast Sync source is ahead of the local
  chain, UDP block requests are selected only from that private/local pool.
- Public Fast Sync peers remain available as fallback when no eligible LAN
  source exists.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.cpp`: `selectUdpFastSyncTargetHost()` now first
  detects eligible LAN/private candidates, then filters the scoring pass to that
  pool when present. The existing Core reservation and block submission path is
  unchanged.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: visible build label
  moved to `26.6.4bk`.

Verification performed:
- Tahoe backend build passed for `defcoind`, `defcoin-cli`, `defcoin-tx`,
  and `defcoin-wallet`.
- Tahoe QML app configured, built, staged, code-signed, and DMG-verified as
  `26.6.4bk`.
- Staged app reports `CFBundleShortVersionString=26.6.4bk`; bundled backend
  reports `Defcoin Core Nu version v26.6.4bk`.
- Clean Tahoe launch used the LAN-Allow clicker immediately after first run of
  the new bundle; the clicker reported a successful Accessibility click.
- `getnetworkinfo` from the bundled backend reports
  `/DefcoinCoreNu:26.6.4bk/` and service name `DEFCOIN_FASTSYNC`.
- Tahoe `getpeerinfo` saw the Lion peer at `192.168.0.189` advertising
  `/DefcoinCoreNu:26.6.4bi-Lion-alpha/` and `DEFCOIN_FASTSYNC`.
- Tahoe debug log showed a UDP Fast Sync probe acknowledgement sent to the Lion
  peer after the `26.6.4bk` launch, proving the new Tahoe responder was active
  and not blocked by macOS LAN permission for this run.

Risks / follow-up:
- If UDP remains slow after Lion parity, inspect Core reservation pacing and
  block validation throughput. Raw Ethernet should not be the limiting factor
  for the tiny early-chain blocks seen in the current Lion rebuild.

### 26.6.4bj - 2026-06-09 - Fast Sync metrics and verified LAN pacing

Big picture:
- The Lion/Tahoe clean UDP test showed UDP Fast Sync accepted real blocks, but
  Metrics made UDP look worse because it compared UDP block-body transfer
  against Core header traffic from normal P2P. This build separates Core header
  bytes from Core block-body bytes and reports UDP node success/failure by real
  accepted blocks.
- Verified LAN Fast Sync peers no longer wait behind the public-probe
  keepalive interval before refilling the UDP request window. This is intended
  to make wired LAN tests reflect request/validation limits rather than an
  accidental 5-second pacing gate.

Porting priority:
- Lion Intel: required. Port the same `NuRpcService` changes so the physical
  iMac reports the same Metrics rows and uses the same verified-LAN pacing.
- Catalina UTM: required if Catalina builds include the current Fast Sync UI.
- Windows: required if Windows builds expose the same Metrics rows.
- Server: no GUI Metrics port. Review only requester-side Fast Sync helper code
  if the server build includes it; responder behavior is unchanged here.

Changed behavior:
- Tahoe visible version becomes `26.6.4bj`.
- Sync overview now reports `Block data` using Core block-body bytes plus UDP
  block bytes. Core headers are a separate field.
- Fast Sync UDP now reports `nodes N ok/M failed`; a peer is counted as OK only
  after a UDP block from that peer is accepted through Core.
- UDP checksum, timeout, buffer, and submit failures mark the sender as failed
  until a later accepted UDP block clears it.
- Verified private/local UDP peers use the LAN request interval instead of the
  5-second public probe interval when the receiver needs more blocks.
- UDP receive window increased from 4 to 8 active blocks and ready queue from
  16 to 24 blocks. The 64 MiB buffer cap remains the hard safety limit.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.cpp`: Metrics separates `headers`,
  Core block-body messages, and UDP bytes; verified LAN retry interval is
  narrowed to actual private/local addresses; UDP peer OK/fail accounting moves
  from chunk receipt to block acceptance.
- `src/qt/nu/app/NuRpcService.h`: adds Core message counters and the UDP block
  failed peer set.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: visible build label
  moved to `26.6.4bj`.

Compatibility notes:
- This does not change consensus rules or the backend reservation RPC contract.
- It intentionally does not claim public internet UDP can refill as fast as LAN
  peers; public probing stays conservative.

Build/package notes:
- Nu-only change. Do not copy or rebuild Defcoin Core Explore as part of this
  build unless the Explore thread explicitly requests it.

Verification performed:
- Tahoe backend build passed for `defcoind`, `defcoin-cli`, `defcoin-tx`,
  and `defcoin-wallet`.
- Tahoe QML app configured, built, staged, code-signed, and DMG-verified as
  `26.6.4bj`.
- Staged app reports `CFBundleShortVersionString=26.6.4bj`; bundled backend
  reports `Defcoin Core Nu version v26.6.4bj`.
- Clean Tahoe launch used the LAN-Allow clicker immediately after first run of
  the new bundle; the clicker reported a successful Accessibility click.
- `getnetworkinfo` from the bundled backend reports
  `/DefcoinCoreNu:26.6.4bj/` and service name `DEFCOIN_FASTSYNC`.
- Tahoe `getpeerinfo` saw the Lion peer at `192.168.0.189` advertising
  `/DefcoinCoreNu:26.6.4bi-Lion-alpha/` and `DEFCOIN_FASTSYNC`.
- Tahoe debug log showed a UDP Fast Sync probe acknowledgement sent to the Lion
  peer, proving Tahoe was no longer blocked by the macOS LAN permission prompt
  for this launch.

Risks / follow-up:
- If corrected UDP block-body rate is still low, inspect reservation churn,
  one-at-a-time Core submission, and UI chunk-status churn before changing
  packet sizes again.

### 26.6.4bi - 2026-06-08 - Debug environment guard and clean UDP proof

Big picture:
- Prior Fast Sync and Quick Clone tests were contaminated by hidden macOS
  launchd environment variables. The physical Lion iMac still had
  `DEFCOIN_NU_DEBUG_DISABLE_QUICK_CLONE=1`, so launches that were intended to
  test Quick Clone silently disabled it.
- This build makes command-line debug switches the normal test path and ignores
  inherited debug disable variables unless explicitly allowed. That prevents
  stale launchd/session state from changing sync behavior without being visible
  in the launch command.
- With current Tahoe and Lion builds, a reset Lion chain, and Core TCP block
  downloads disabled on Lion, UDP Fast Sync accepted blocks through Core
  validation. After clearing the stale Quick Clone disable flag, Quick Clone
  also accepted LAN blocks through Core validation.

Porting priority:
- Lion Intel: required and already ported to the physical iMac source. Add the
  same startup guard in legacy `main.cpp`.
- Catalina UTM: required if it uses the same debug launch switches.
- Windows: required if the Windows launcher or app honors
  `DEFCOIN_NU_DEBUG_DISABLE_*` variables.
- Server: no UI port. Server-side Fast Sync code is unchanged, but test scripts
  should avoid persistent debug environment variables.

Changed behavior:
- Tahoe visible version becomes `26.6.4bi`.
- Lion visible version becomes `26.6.4bi-Lion-alpha`.
- `DEFCOIN_NU_DEBUG_DISABLE_CORE_TCP_SYNC`,
  `DEFCOIN_NU_DEBUG_DISABLE_CORE_SYNC`,
  `DEFCOIN_NU_DEBUG_DISABLE_FAST_SYNC`,
  `DEFCOIN_NU_DEBUG_DISABLE_QUICK_CLONE`, and
  `DEFCOIN_NU_QUICK_CLONE_NOW` are cleared at GUI startup unless
  `--debug-use-env` or `DEFCOIN_NU_ALLOW_DEBUG_ENV=1` is present.
- Explicit command-line switches still work and are used for repeatable tests:
  `--debug-disable-core-tcp-sync`, `--debug-disable-core-sync`,
  `--debug-disable-fast-sync`, `--debug-disable-quick-clone`, and
  `--quick-clone-now`.

Changed files and important details:
- `source/src/qt/nu/app/main.cpp`: Tahoe startup now sanitizes inherited debug
  environment before translating command-line switches into process-local debug
  environment values for `NuRpcService`.
- `source/src/qt/nu/legacy-osx107/main.cpp`: Lion legacy startup mirrors the
  same behavior.
- `source/src/clientversion.h`,
  `source/src/qt/nu/app/CMakeLists.txt`,
  `source/src/qt/nu/legacy-osx107/Info.plist`, and
  `source/src/qt/nu/legacy-osx107/DefcoinCoreNuLegacy.pro`: version labels
  updated.

Compatibility notes:
- This does not change the UDP wire format, service bit, Core reservation RPC,
  validation behavior, wallet files, or datadir layout.
- Quick Clone remains the validated LAN block-copy scaffolding in this build;
  the validation-bypass DCOL snapshot installer remains future work.

Verification performed:
- Tahoe `26.6.4bh` was relaunched from the exact staged app path and the LAN
  Allow clicker was run. No prompt was present; backend advertised
  `DEFCOIN_FASTSYNC`.
- Lion chain folders `blocks`, `chainstate`, and `indexes` were deleted while
  preserving `wallets/wallet.dat`.
- Lion launched with `--debug-disable-core-tcp-sync --debug-disable-quick-clone`
  accepted UDP Fast Sync blocks through Core validation.
- After clearing `DEFCOIN_NU_DEBUG_DISABLE_QUICK_CLONE` from launchd, Lion
  launched with `--debug-disable-core-tcp-sync --quick-clone-now` accepted
  Quick Clone LAN blocks through Core validation.

Risks / follow-up:
- Add a visible warning if any debug launch switch is active during normal UI
  use, so future manual tests cannot confuse a disabled path with a failed
  protocol.
- Keep Quick Clone and Fast Sync tests isolated first, then re-enable Core TCP
  competition after the isolated path is proven.

### 26.6.4be - 2026-06-08 - Lion iMac source refresh and peer Methods parity

Big picture:
- The latest UTM Lion working tree was copied to the physical Lion iMac so the
  iMac build no longer lags the UTM test source. Tahoe and Lion were then
  checked for Fast Sync/Quick Clone invariant parity. The low-level backend
  transport logic remains aligned: UDP is only a transport for Core-selected
  block reservations, and blocks still submit through Core validation.
- Lion's peer table transport column now uses the same visible label as Tahoe:
  `Methods`. The data remains the observed transport method string, such as
  `P2P TCP`, `UDP FS`, or `P2P TCP + UDP FS`.

Porting priority:
- Lion Intel: already ported into the local Lion source and must be copied to
  the physical iMac before building.
- Catalina UTM: UI wording parity only if Catalina has the legacy peers table.
- Windows: UI wording parity only if its peers table still says Observed
  Traffic for the transport-method column.
- Server: no code change; server Fast Sync logic should already match the
  reservation RPC and service-bit behavior.

Changed behavior:
- Tahoe visible version becomes `26.6.4be`.
- Lion visible version becomes `26.6.4be-Lion-alpha`.
- Lion Metrics > Peers simple and detailed tables rename the transport column
  from `Observed Traffic` to `Methods`, matching Tahoe.

Changed files and important details:
- Tahoe `src/clientversion.h`: `DEFCOIN_RELEASE_VERSION_STR` to `26.6.4be`.
- Tahoe `src/qt/nu/app/CMakeLists.txt`: `DEFCOIN_NU_RELEASE_NAME` to
  `26.6.4be`.
- Lion `src/clientversion.h`: `DEFCOIN_RELEASE_VERSION_STR` to
  `26.6.4be-Lion-alpha`.
- Lion `src/qt/nu/legacy-osx107/DefcoinCoreNuLegacy.pro`: compile define to
  `26.6.4be-Lion-alpha`.
- Lion `src/qt/nu/legacy-osx107/main.cpp`: fallback version string and peers
  table column labels updated.

Compatibility notes:
- This build does not change the UDP wire format, service bit 29, block
  reservation RPCs, or Quick Clone request semantics.
- The physical iMac's current Bonjour-resolved address was
  `Library-Archives-Cataloging-iMac.local` / `192.168.0.189`; the old
  `192.168.2.19` address was not reachable during this port.

Verification performed:
- `rg` invariant scan confirmed Tahoe and Lion both contain the debug sync
  switches, Quick Clone, UDP Fast Sync capability string, service-bit label,
  and `reservefastsyncblock` path.
- `cmp` confirmed `src/net_processing.h`, `src/protocol.cpp`,
  `src/protocol.h`, and `src/rpc/net.cpp` match between Tahoe and Lion; the
  `src/net_processing.cpp` Fast Sync differences were line-number drift only in
  the targeted reservation-symbol diff.

Risks / follow-up:
- The Lion working tree metadata on UTM/iMac still points at the Mac Mini
  worktree gitdir and is invalid on those hosts. Build from source works, but
  git status on the remote Lion machines is not authoritative until that
  worktree metadata is repaired.
- Live UDP/Quick Clone testing still requires launching current Tahoe and Lion
  builds and ensuring Tahoe's macOS Local Network permission prompt is accepted
  for each fresh Tahoe build.

### 26.6.4bb - 2026-06-06 - Fast Sync early-header automatic scheduling

Big picture:
- Live Tahoe/Lion testing proved the 26.6.4ba low-level explicit reservation
  fallback works: `reservefastsyncblock reserve <peer> 1` returned `reserved`
  while Lion had only the first few thousand headers. The automatic
  `reserve-next` path was still too conservative because a partially synced
  `pindexBestKnownBlock` below `nMinimumChainWork` made it return
  `headers-below-minimum-chain-work`. This build allows automatic Fast Sync to
  reserve the next active-chain block from the local header chain during early
  header sync, while still submitting received data through Core validation.

Porting priority:
- Lion Intel/UTM: required. Tahoe and Lion must use identical reservation logic
  or they will disagree about when UDP can start during clean bootstrap.
- Catalina UTM: required if Fast Sync is tested there.
- Windows: required for parity before Windows UDP testing.
- Server: required after local Tahoe/Lion accepted-UDP-block tests pass.

Changed behavior:
- `reservefastsyncblock reserve-next` no longer waits for the peer's
  best-known block chain work to reach minimum chain work if UDP transport is
  verified and the local header chain already has the next needed header.
- Explicit reservation behavior from 26.6.4ba is unchanged.
- The block still goes through `MarkBlockAsInFlight` and normal block
  acceptance; this does not bypass consensus validation.

Changed files and important details:
- `src/net_processing.cpp`: in `ReserveNextFastSyncBlockInFlight()`, compute
  `next_height` before the minimum-chain-work gate and switch to the
  `FastSyncHeaderFallbackIndex()` path when the peer's known header chain is
  below minimum work. Keep this exact logic in Tahoe, Lion, server, and Windows.
- Tahoe version metadata: bumped to `26.6.4bb`.
- Lion version metadata: bumped to `26.6.4bb-Lion-alpha`.

Verification performed:
- Pre-patch UTM Lion 26.6.4ba saw Tahoe 26.6.4ba as peer 2 with
  `DEFCOIN_FASTSYNC`, but `reserve-next` returned
  `headers-below-minimum-chain-work`.
- The same session showed `reserve 2 1` returned `reserved`, proving the lower
  block reservation path can work during early header sync.
- Build/test verification pending; update after Tahoe/Lion 26.6.4bb packaging
  and isolated UDP retest.

Risks / follow-up:
- This intentionally starts UDP earlier than Core's normal block-download
  minimum-chain-work gate. The payload is still validated by Core, but watch
  logs for wasted early reservations if a peer's starting height is misleading.

### 26.6.4ba - 2026-06-06 - Fast Sync early-header reservation fallback

Big picture:
- UDP Fast Sync was reaching service-bit negotiation and UDP probe/ack, but
  Lion could not reserve even block 1 from Tahoe because Core had not populated
  that peer's `pindexBestKnownBlock` yet. This build keeps UDP as a transport
  only, but allows verified Fast Sync peers to reserve locally-known early
  headers when the peer's VERSION `startingheight` proves it should have that
  height. Blocks are still submitted through normal Core validation.

Porting priority:
- Lion Intel/UTM: required. The same `src/net_processing.cpp` fallback must be
  present or Lion will remain stuck at `peer-best-block-unknown` against Tahoe.
- Catalina UTM: required if it uses the same Fast Sync reservation RPC.
- Windows: required for parity before Windows Fast Sync testing.
- Server: required after Tahoe/Lion prove accepted UDP blocks locally; server
  should advertise bit 29 and use the same requester/responder reservation
  semantics.

Changed behavior:
- `reservefastsyncblock reserve` and `reserve-next` no longer fail solely
  because `pindexBestKnownBlock` is unset for a verified Fast Sync peer.
- Fallback is conservative: it requires UDP transport verification,
  `nStartingHeight >= requested height`, a locally known validated header at
  that height, and normal `MarkBlockAsInFlight` plus later `submitblock`
  validation. It does not trust UDP payloads or bypass consensus.

Changed files and important details:
- `src/net_processing.cpp`: added `FastSyncHeaderFallbackIndex()` and fallback
  branches in `ReserveFastSyncBlockInFlight()` and
  `ReserveNextFastSyncBlockInFlight()`. Keep this backend code identical across
  Tahoe/Lion/server where possible.
- Tahoe version metadata: bumped to `26.6.4ba`.
- Lion version metadata: bumped to `26.6.4ba-Lion-alpha`.

Compatibility notes:
- Legacy 1.0.0 peers are unaffected because they do not advertise the Defcoin
  Fast Sync service bit and cannot pass UDP transport verification.
- This remains compatible with normal TCP/Core sync; if UDP fails, Core can keep
  syncing by its normal path unless disabled for testing.

Verification performed:
- Pre-patch live test showed Lion peer id 11 for Tahoe with
  `servicesnames` including `DEFCOIN_FASTSYNC`, but `synced_headers=-1` and
  `reservefastsyncblock reserve-next 11` returned
  `peer-best-block-unknown`.
- Build/test verification pending in this entry; update after packaging and
  Tahoe/Lion UDP retest.

Risks / follow-up:
- If headers are still too slow on Lion, inspect why header chain state is not
  persisted or why header download is throttled. Do not mistake header latency
  for UDP failure.

### 26.6.4az - 2026-06-06 - Trustworthy UDP failure accounting and Tahoe LAN prompt automation

Big picture:
- This build fixes two problems that were poisoning Fast Sync test results:
  Tahoe's Local Network Allow helper could accidentally match Codex chat text
  through whole-screen OCR, and UDP Metrics collapsed probe misses, request
  timeouts, checksum failures, buffer failures, and submit failures into one
  vague failure count. Future Fast Sync tests should treat any run before a
  confirmed Tahoe Allow click as invalid.

Porting priority:
- Lion Intel/UTM: required. Port the separated UDP status counters and wording
  so Lion reports the same evidence as Tahoe during Tahoe-to-Lion testing.
- Catalina UTM: required if it shows Fast Sync Metrics or runs the same
  requester-side transport logic.
- Windows: port the Metrics wording/counter split if Windows exposes the same
  Fast Sync rows.
- Server: after Tahoe/Lion prove UDP block transfer works, update server code to
  the same Fast Sync requester/responder behavior. Server does not need the
  macOS Allow helper.

Changed behavior:
- Metrics now separates UDP probe misses from real block payload failures.
- Fast Sync UDP details split payload failures into timeout/checksum/buffer/
  submit categories, plus request/probe send failures.
- The macOS Local Network Allow helper is Accessibility-first by default. It no
  longer uses whole-screen OCR unless `--ocr-fallback` is explicitly supplied.
  This prevents false positives caused by the prompt wording appearing in Codex
  or another visible document.

Changed files and important details:
- `src/qt/nu/app/NuRpcService.h/.cpp`: added reason buckets for UDP failure
  accounting; updated status text to show probe misses and block failure kinds.
- `src/qt/nu/tools/macos_click_lan_allow.swift`: defaults to native
  Accessibility prompt search; OCR fallback must now be explicitly requested.
- `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: Tahoe visible build
  label bumped to `26.6.4az`.
- Lion equivalent: `src/qt/nu/legacy-osx107/main.cpp`,
  `src/qt/nu/legacy-osx107/DefcoinCoreNuLegacy.pro`, and
  `src/clientversion.h` use `26.6.4az-Lion-alpha`.

Compatibility notes:
- Consensus and block acceptance are unchanged. This is accounting, status, and
  test automation reliability work.
- When testing Tahoe UDP, launch the current Tahoe build and run the Allow
  helper after the OS prompt appears or with a long retry window. Do not infer
  UDP failure from a blocked Local Network prompt.

Build/package notes:
- Build only Defcoin Core Nu. Defcoin Core Explore remains a separate app and
  distribution cycle.

Verification performed:
- `git diff --check -- src/qt/nu/app/NuRpcService.cpp src/qt/nu/app/NuRpcService.h src/qt/nu/tools/macos_click_lan_allow.swift` passed in Tahoe source.
- `git diff --check -- src/qt/nu/legacy-osx107/main.cpp` passed in Lion source.
- The updated Tahoe Allow helper returns `contextFound:false` and
  `No native Local Network Allow prompt was found` on a screen where only Codex
  contains prompt wording.

Risks / follow-up:
- Rebuild Tahoe and Lion, test UDP-only Fast Sync after the Tahoe Allow prompt
  is confirmed, then install matching Fast Sync behavior on the server only if
  live UDP block transfer succeeds.

### 26.6.4ay - 2026-06-05 - Header-gated UDP scheduling diagnostics

Big picture:
- Fresh Tahoe-to-UTM Lion testing was restarted with current builds and the
  macOS LAN prompt allowed. The key observation changed: Tahoe acknowledged the
  Lion UDP probe, so UDP reachability was proven, but Lion was still rebuilding
  headers from block zero and Core could not yet schedule a downloadable block.
  That is a header/scheduler gate, not a UDP packet failure.

Porting priority:
- Lion Intel/UTM: required. Port the same backend reservation reasons, status
  formatter, startup error normalization, and bounded Bonjour lookup helper.
- Catalina UTM: required if Catalina shares the same Nu service and LAN
  workstation-name helper.
- Windows: port the reservation/status wording if Windows uses this frontend.
  The Bonjour helper fix is macOS-only.
- Server: no responder change from this entry. Server requester-side Fast Sync
  should report the same scheduling reasons if it calls `reserve-next`.

Changed behavior:
- `reservefastsyncblock reserve-next` now returns specific early-gate reasons
  before falling through to the generic downloader search: `peer-best-block-unknown`,
  `peer-chain-not-ahead`, or `headers-below-minimum-chain-work`.
- Fast Sync and Quick Clone use one shared status formatter for Core scheduling
  waits. In UDP-only test mode it says Core TCP block copy is off instead of
  claiming normal TCP sync remains active.
- The startup RPC batch path normalizes transient backend transport errors to
  "Starting Defcoin backend..." instead of surfacing raw `Connection refused`.
- The macOS Bonjour/SMB LAN workstation lookup no longer pipes an infinite
  `dns-sd -B` browser through a shell. It samples for a bounded interval and
  kills the child process so peer refreshes do not leak helper processes.

Changed files and important details:
- `source/src/net_processing.cpp`: added explicit prechecks in
  `ReserveNextFastSyncBlockInFlight()` after `ProcessBlockAvailability()`.
- `source/src/qt/nu/app/NuRpcService.cpp`: added
  `coreSchedulingWaitStatus()` and wired it into both Fast Sync and Quick
  Clone reservation callbacks; expanded diagnostic detail with header/local
  block counts; bounded the Bonjour helper; normalized batch RPC transport
  startup errors.
- `source/src/qt/nu/app/NuRpcService.h`: declares the new formatter.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  build metadata bumped to `26.6.4ay`.

Compatibility notes:
- This does not change consensus or block validation.
- UDP remains a transport for a Core-selected block reservation. If headers are
  still below minimum chainwork, no UDP block request should be sent yet.
- Treat this as a correction to prior testing assumptions: an allowed UDP probe
  does not mean Core is ready to request block bodies while headers are still
  catching up from zero.

Build/package notes:
- Tahoe build target: `26.6.4ay`.
- Lion build target: `26.6.4ay-Lion-alpha`.

Verification performed:
- Live UTM screen check: Lion was at block 0 with headers advancing and no OK
  modal blocking the app.
- Live logs/RPC: Lion probe reached Tahoe and Tahoe sent UDP probe ACK;
  `reservefastsyncblock transport-verified` succeeded for the Tahoe peer.
- Live RPC: `reservefastsyncblock reserve-next` returned no schedulable block
  while headers were still building, matching the new diagnostic path.

Risks / follow-up:
- After Lion headers reach a schedulable state, retest actual accepted UDP block
  delivery with current Tahoe and Lion builds only.
- If block delivery still fails after scheduling opens, inspect request/chunk
  logs rather than revisiting LAN permission as the first assumption.

### 26.6.4ar - 2026-06-05 - ACK-proven UDP peers and honest sync percent

Big picture:
- Tahoe-to-UTM Lion testing showed two separate issues. The sync dialog could
  display `Progress 100%` while `blocks < headers` because the backend rounded
  `verificationprogress` to an integer. Separately, UDP Fast Sync target
  selection could reject peers that looked public before sending the safe UDP
  probe, even though UTM can expose a same-machine/LAN peer as a globally routed
  IPv6 endpoint.

Porting priority:
- Lion Intel: required. The selector and datagram-size changes were already
  applied to `legacy-osx107/main.cpp`.
- Catalina UTM: required if it shares the Lion legacy frontend.
- Windows: port the selector concept if Windows uses this frontend logic.
- Server: no frontend sync-dialog change. Requester-side Fast Sync code should
  not reject safe probes before ACK.

Changed behavior:
- Sync progress is capped below `100%` while blocks are still behind headers.
  The dialog should only clear through the existing not-syncing path when Core
  reports the chain is actually caught up.
- UDP selectors may choose a public-looking peer for a safe-sized probe.
- Once a peer ACKs a UDP Fast Sync probe, it is treated as a proven target for
  larger datagram sizing. The serving peer still caps based on what it sees and
  block chunks remain checksum-protected.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: sync progress integer capping;
  added `isPrivateLocalOrProvenUdpFastSyncTarget()`; selector scoring and
  datagram sizing now include ACK-proven peers.
- `source/src/qt/nu/app/NuRpcService.h`: declares the new helper.
- `source/src/qt/nu/legacy-osx107/main.cpp`: equivalent selector and
  datagram-size changes for Lion.
- Version metadata bumped to `26.6.4ar`; Lion label is
  `26.6.4ar-Lion-alpha`.

Compatibility notes:
- This does not bypass Core validation or normal peer selection.
- The safe probe remains small; larger chunks happen only after UDP ACK and the
  serving side's cap logic.

Verification performed:
- Pending rebuild and Tahoe/Lion live test.

Risks / follow-up:
- If UDP still fails after ACK, inspect request/chunk logs on the serving side
  for the normalized sender host and reply port.

### 26.6.4ao - 2026-06-05 - TCP-off launch mode forces UDP selector

Big picture:
- The `--debug-disable-core-tcp-sync` launch switch already reached the backend
  as `-defcoindisablecoretcpblocks=1`, but the frontend Fast Sync selector still
  spent quota on the normal Core/TCP path. That made isolated UDP testing noisy
  because the UI could keep waiting for a TCP block-body path that was
  intentionally disabled.

Porting priority:
- Lion Intel: required. Port the same selector behavior so UTM/iMac Lion tests
  use the same UDP-only debug mode as Tahoe.
- Catalina UTM: port if Catalina uses the same Nu Fast Sync selector.
- Windows: port if Windows exposes the same debug launch switch.
- Server: no change unless the server has a requester-side test mode that
  intentionally disables TCP block-body fetches.

Changed behavior:
- `--debug-disable-core-tcp-sync` and
  `DEFCOIN_NU_DEBUG_DISABLE_CORE_TCP_SYNC=1` still leave peers, headers, and
  service-bit negotiation active.
- In that mode only, frontend Fast Sync allocates zero Core/TCP quota and uses
  UDP probes/reservations whenever eligible peers are present and UDP is not in
  cooldown.
- The legacy `--debug-disable-core-sync` alias remains accepted but is treated
  as TCP-block-copy-only for this test path.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: `resetFastSyncProtocolWindow()` and
  `shouldAttemptUdpFastSync()` now special-case
  `m_debug_disable_core_sync`.
- `source/src/qt/nu/legacy-osx107/main.cpp`: same logic using
  `m_debugDisableCoreSync`.
- `source/src/clientversion.h` and app build metadata bumped to `26.6.4ao`;
  Lion uses `26.6.4ao-Lion-alpha`.

Compatibility notes:
- Normal launches are unchanged. This is a debug/test launch behavior only.
- Full Core network shutdown is still only appropriate for Quick Clone/DCOL
  tests, not Fast Sync transport isolation.

Verification performed:
- Pending rebuild and Tahoe/Lion live UDP test.

Risks / follow-up:
- If Lion remains in header-building state, UDP requests may still defer until
  Core's peer/header state can reserve a specific block. That is expected and
  should be logged as reservation deferral, not as UDP packet failure.

### 26.6.4ak - 2026-06-05 - Fast Sync frontend timing parity

Big picture:
- After the backend reservation parity fix in `26.6.4aj`, the Tahoe and Lion
  frontend Fast Sync constants were compared. The lower-level reservation and
  service-bit behavior matched, but Lion still used older probe/timer timings.
- Lion now uses Tahoe's 500 ms Fast Sync timer and 2500 ms UDP probe timeout so
  both builds probe, expire, and retry with the same expectations.
- Tahoe was bumped to the same suffix so package labels stay aligned even
  though the timing code change itself is Lion-side.

Porting priority:
- Lion Intel: ported in this pass.
- Catalina UTM: align any legacy frontend constants to Tahoe's 500 ms tick and
  2500 ms UDP probe timeout.
- Windows: no code change unless the Windows frontend carries divergent timing
  constants.
- Server: no change from this frontend timing entry.

Changed behavior:
- Lion no longer waits 6 seconds before declaring a UDP probe expired. It now
  uses Tahoe's 2.5 second probe timeout and 500 ms tick.

Changed files and important details:
- Tahoe `src/clientversion.h` and `src/qt/nu/app/CMakeLists.txt`: version bump
  to `26.6.4ak`.
- Lion `src/clientversion.h`, `src/qt/nu/legacy-osx107/DefcoinCoreNuLegacy.pro`,
  `src/qt/nu/legacy-osx107/Info.plist`, and
  `src/qt/nu/legacy-osx107/main.cpp`: version bump to
  `26.6.4ak-Lion-alpha`.
- Lion `src/qt/nu/legacy-osx107/main.cpp`: `LAN_FAST_SYNC_TIMER_INTERVAL_MS`
  changed from 750 to 500; `LAN_FAST_SYNC_PROBE_TIMEOUT_MS` changed from 6000
  to 2500.

Verification performed:
- Backend reservation function diff between Tahoe and Lion returned clean.
- Live UTM/Tahoe UDP probe test succeeded in the UTM-to-Tahoe direction.
- Synthetic UTM Quick Clone-style `request-block` received a Tahoe
  `block-chunk` response with height/hash/checksum metadata.

Risks / follow-up:
- UTM Lion is NATed at `10.0.2.15`; Tahoe cannot initiate UDP directly to the
  guest listener without bridged networking or forwarding. Receiver-initiated
  UTM-to-Tahoe UDP works.

### 26.6.4aj - 2026-06-05 - Fast Sync reservation parity audit

Big picture:
- Tahoe and Lion were audited for Fast Sync and Quick Clone receiver/listener
  behavior. The intended shared rule is now explicit: Core selects and reserves
  the peer/block; UDP is only the transport used to deliver that one reserved
  block; `submitblock` remains the normal Core acceptance path.
- Lion still had an older header-chain fallback inside
  `ReserveFastSyncBlockInFlight()` / `ReserveNextFastSyncBlockInFlight()`. That
  fallback could reserve a block Tahoe would refuse, making the two builds
  expect different behavior during LAN tests.
- Tahoe now treats `submitblock` result `inconclusive` the same way Lion does:
  as a delivered block sample handed to Core during IBD, not as a UDP transport
  failure.

Porting priority:
- Lion Intel: ported in this pass. Keep the backend reservation functions
  byte-for-byte aligned with Tahoe after this entry.
- Catalina UTM: remove any header-chain fallback or guessed-height reservation
  path if present; accept `inconclusive` as a non-error submit result.
- Windows: accept `inconclusive` in the QML/Qt UDP submit callback if the
  Windows UI uses `NuRpcService.cpp`.
- Server: requester-side Fast Sync must use Core-selected reservations only.
  Responder-only services are unaffected.

Changed behavior:
- Fast Sync receiver:
  - probes service-bit peers over UDP;
  - marks transport verified only after a valid probe acknowledgement;
  - calls `reservefastsyncblock reserve-next <nodeid>`;
  - requests only the returned height/hash over UDP;
  - validates chunk and block checksums;
  - submits the assembled raw block through Core.
- Fast Sync listener:
  - advertises `NODE_DEFCOIN_FASTSYNC` only when launched with
    `-defcoinfastsync=1`;
  - answers valid probes and block requests on UDP 10334;
  - serves chunks only for heights it already has locally.
- Quick Clone receiver:
  - is a trusted-LAN/manual/session request layered on the same UDP transport;
  - uses LAN candidates only;
  - still submits every received block through Core in this build;
  - does not use snapshot replacement yet.
- Quick Clone listener:
  - keeps advertising LAN availability through beacons/discovery;
  - serves the same checksum-protected UDP block chunks as Fast Sync.

Changed files and important details:
- Tahoe `source/src/qt/nu/app/NuRpcService.cpp`: `submitblock` handling now
  accepts `inconclusive` alongside empty/null and `duplicate`.
- Lion `src/net_processing.cpp`: removed `nFastSyncReserveScanHeight`, removed
  fallback helper functions, and matched Tahoe's Core-selected reservation
  functions.
- Tahoe and Lion version metadata bumped to `26.6.4aj` /
  `26.6.4aj-Lion-alpha`.

Compatibility notes:
- Older Defcoin Core 1.0.x peers are unaffected. They do not advertise bit 29
  and continue normal TCP block sync.
- If a peer has not reached usable Core peer state yet, the expected reason is
  now `peer-best-block-unknown` or another Core scheduler reason on both
  platforms, not a platform-specific fallback reservation.

Verification performed:
- `diff` of Tahoe vs Lion `ReserveFastSyncBlockInFlight()` through
  `ReleaseFastSyncBlockInFlight()` returned no differences after the patch.
- `rg` found no remaining Lion fallback symbols:
  `FastSyncFallback`, `nFastSyncReserveScanHeight`, `header-chain fallback`,
  or `local-block-data-scan`.

Risks / follow-up:
- This simplifies behavior but may wait for Core peer state instead of forcing
  a UDP request earlier. That is intentional: it keeps UDP from bypassing Core's
  scheduler.

### 26.6.4ai - 2026-06-05 - Metrics sync-method labeling cleanup

Big picture:
- Metrics > Status now names the three sync paths by what they actually do:
  `Core Sync (TCP)`, `Fast Sync (UDP)`, and `Quick Clone (LAN UDP)`.
- The old visible label `Fast Sync TCP` was misleading because that row was
  backed by Core's normal P2P/validation path, not by a TCP version of Fast
  Sync.

Porting priority:
- Lion Intel: ported in this pass; keep the same labels in the legacy
  `populateDiagnosticsStatus()` rows.
- Catalina UTM: port the same Status labels if it has the Nu metrics page.
- Windows: port the same Status labels if its QML Status table is built from
  `NuRpcService::rebuildNodeMetrics()`.
- Server: no server behavior change; this is UI/telemetry wording only.

Changed behavior:
- `Sync overview` shows combined sync throughput.
- `Core Sync (TCP)` shows Core's normal TCP P2P/validation path.
- `Fast Sync (UDP)` and its decision/probe rows are grouped together.
- `Quick Clone (LAN UDP)` rows are grouped together.
- Status rows with one visible line should no longer reserve unnecessary
  two-line height.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: renamed node metric rows and kept
  the explanatory nuance in hover text instead of adding a noisy note row.
- `source/src/qt/nu/qml/Views/NodeView.qml`: narrowed the metric column a bit
  and capped Status row wrapping to two lines so the table stays compact.
- `source/src/qt/nu/legacy-osx107/main.cpp`: applied matching Lion row labels,
  removed the separate `Fast Sync TCP note`, shortened UDP sample text, and
  tightened single-line row heights after `resizeRowsToContents()`.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible Tahoe version is `26.6.4ai`.
- Lion source version/plist files: visible Lion version is
  `26.6.4ai-Lion-alpha`.

Compatibility notes:
- This does not change Fast Sync or Quick Clone networking. It only prevents
  the UI from implying that Fast Sync has a TCP mode.

Verification performed:
- Pending build/smoke in this thread. Grep should show no remaining visible
  `Fast Sync TCP` Status labels after this entry.

Risks / follow-up:
- If long runtime status values still wrap unexpectedly, shorten the value text
  first; avoid adding more explanatory prose to Metrics rows.

### 26.6.4ae - 2026-06-04 - Quick Clone command-line test hook and Lion parity

Big picture:
- Tahoe and Lion now share the same Quick Clone/Fast Sync reservation boundary:
  UDP is only a transport for a block Core has reserved from normal peer state.
- A temporary but intentional test hook was added so Codex can launch a build
  and force Quick Clone initiation without walking through the UI. This exists
  to make Tahoe/Lion LAN testing reproducible.
- Lion's apparent "lost sync progress" after relaunch was checked before
  deleting any chain data. The persisted best block did not roll back; the UI
  appeared to lose percent progress because the header target changed after
  relaunch while the absolute block height was still persisted.

Porting priority:
- Lion Intel: already ported in the Lion workspace as `26.6.4ae-Lion-alpha`;
  keep the same command-line trigger and Core reservation behavior.
- Catalina UTM: port the command-line trigger if it needs automated Quick Clone
  testing. Keep architecture-specific build flags separate.
- Windows: port only if Windows needs automated Quick Clone launch tests.
- Server: no GUI trigger needed. Requester-side server Fast Sync should still
  use Core-selected/reserved blocks, not guessed heights.

Changed behavior:
- Launching Nu with `--quick-clone-now`, or with
  `DEFCOIN_NU_QUICK_CLONE_NOW=1`, schedules `syncUsingQuickCloneNow()` shortly
  after startup.
- Lion Quick Clone now calls `reservefastsyncblock reserve-next` with a
  `lan-fast-copy-reserve` context before sending a UDP block request.
- Duplicate Quick Clone submit results are treated as stale work and do not
  count as progress.
- Added a local test helper that watches Nu logs for UDP evidence and alerts
  with `beep`/`say` if the launch test appears blocked by macOS Local Network
  permission.

Changed files and important details:
- `source/src/qt/nu/app/main.cpp`: Tahoe command-line Quick Clone trigger.
- `source/src/clientversion.h`, `source/src/qt/nu/app/CMakeLists.txt`,
  `source/src/qt/nu/docs/README.md`,
  `source/src/qt/nu/docs/functionality-map.md`: visible release label
  `26.6.4ae`.
- `source/src/qt/nu/tools/udp_lan_permission_gate.sh`: Tahoe-side test helper
  for the first UDP LAN blocker check. This is not a product feature and does
  not change firewall/TCC state.
- Lion equivalent files:
  `src/qt/nu/legacy-osx107/main.cpp`, `src/clientversion.h`,
  `src/qt/nu/legacy-osx107/DefcoinCoreNuLegacy.pro`, and
  `src/qt/nu/legacy-osx107/Info.plist`.

Compatibility notes:
- Consensus, wallet storage, service bits, packet format, checksums, and Core
  block validation are unchanged.
- Older TCP-only peers and v1.0.x peers are unaffected.

Build/package notes:
- Build/package only Defcoin Core Nu for this entry. Explore/ExpFor remains its
  own app and release cycle.
- Before live tests, close any previous Nu app/backend instance on both Tahoe
  and Lion. The GUI/backend are not designed to run multiple versions against
  the same datadir.

Verification performed:
- Tahoe backend/tools built and report `v26.6.4ae`.
- Tahoe Qt bundle built and staged at
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.4ae-20260604/Defcoin Core Nu.app`.
- Staged Tahoe app passed deep codesign verification; bundled `defcoind`,
  `defcoin-cli`, and `Info.plist` all report `26.6.4ae`; Spotlight kind is
  `Application`.
- Lion pre-build persistence check showed the backend reloaded the same
  persisted absolute height (`15781`) after relaunch; no blockchain rollback was
  observed.

Risks / follow-up:
- Live Tahoe/Lion UDP testing must first confirm macOS Local Network permission
  is not blocking UDP. If UDP probes cannot pass, alert locally before trying to
  diagnose protocol behavior.
- After Lion package is complete, launch Tahoe and Lion with the new test hook
  and verify real UDP block acceptance plus Quick Clone reservation behavior.

### 26.6.4ad - 2026-06-04 - Quick Clone uses Core block reservation

Big picture:
- Lion could show that a UDP block arrived but Core already had it. That is
  possible when the GUI schedules a block from stale height state while Core's
  normal sync accepts the same height through TCP, or when late UDP chunks
  arrive after Core has already advanced.
- The root issue was that normal UDP Fast Sync already used
  `reservefastsyncblock reserve-next`, but the Quick Clone scaffolding path was
  still directly requesting `m_block_height + 1`.
- Quick Clone now uses the same Core reservation boundary as Fast Sync. UDP is
  again only a transport for a block Core selected from a connected peer.

Porting priority:
- Lion Intel: port directly to `src/qt/nu/legacy-osx107/main.cpp` after the
  current Lion build thread is clear. This is the fix for Lion's
  `already had it` UDP message.
- Catalina UTM: port if its Quick Clone/LAN copy path guesses the next height.
- Windows: port if it shares the QML/Qt Quick Clone path.
- Server: requester-side behavior should match this if the server can request
  Fast Sync blocks; responder-only behavior is unchanged.

Changed behavior:
- `lanQuickCloneTick()` now requires a Core peer id, asks Core to reserve the
  next missing block, and requests that reserved height/hash over UDP.
- Quick Clone no longer issues multiple `reservefastsyncblock` calls at once.
- Duplicate Quick Clone submit results are treated as stale/skipped work and
  are not counted as Quick Clone progress.
- Ordinary TCP sync remains active unless a future real snapshot install stage
  explicitly pauses it.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: Quick Clone scheduling now mirrors
  the lower-level Fast Sync reservation path instead of guessing a height.
- `source/src/qt/nu/docs/quick-clone-status-language.md`: added reservation and
  stale-skip status phrases.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4ad`.
- `source/src/qt/nu/docs/release-notes-26.6.4ad.md`: user-facing notes.

Compatibility notes:
- Consensus, wallet storage, service bits, packet format, checksums, and Core
  block validation are unchanged.
- Older TCP-only peers and v1.0.x peers are unaffected.

Build/package notes:
- Build/package only Defcoin Core Nu for this entry. Explore/ExpFor remains its
  own app and release cycle.

Verification performed:
- Tahoe backend build succeeded with:
  `make -C source/src defcoind defcoin-cli defcoin-tx defcoin-wallet -j8`.
- Tahoe Qt bundle build succeeded with:
  `cmake --build build/nu-qml-arm64-26.6.4ad --target DefcoinCoreNu -j 8`
  and `DefcoinCoreNuResources`.
- Staged app verifies as a macOS app at
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.4ad-20260604/Defcoin Core Nu.app`.
- Bundled `defcoind --version` and `defcoin-cli --version` both report
  `v26.6.4ad`.
- Launch smoke test succeeded after closing `26.6.4ac`: frontend/backend ran
  from the `26.6.4ad` app, RPC `getnetworkinfo` reported subversion
  `/DefcoinCoreNu:26.6.4ad/`, `DEFCOIN_FASTSYNC`, and `networkactive=true`;
  RPC `getblockchaininfo` reported main chain at matching blocks/headers.
- Lion port/test remains blocked until the separate Lion build thread is clear.

Risks / follow-up:
- After Lion is clear, port `26.6.4ac` and `26.6.4ad` together. Success
  criteria: Lion's UDP status progresses from Core reservation to accepted
  non-duplicate blocks, or gives a clear Core scheduling reason; it should not
  repeatedly request blocks it already has.

### 26.6.4ac - 2026-06-04 - Quick Clone no longer parks Core P2P while probing

Big picture:
- Live Tahoe/Lion rebuild testing found that the Quick Clone scaffolding path
  could pause Core networking before a real snapshot/install stage existed.
- On Lion this produced `networkactive=false`, zero peers, and no useful Fast
  Sync reservations after the public chain folders were removed for a clean
  rebuild test.
- Quick Clone should only isolate ordinary networking during a future final
  snapshot install/swap. While it is listening, probing, or requesting
  Core-accepted block data, Core P2P must remain active so normal peer
  selection and Fast Sync reservation can work.

Porting priority:
- Lion Intel: port directly to `src/qt/nu/legacy-osx107/main.cpp`, but do not
  touch the Lion host while another build thread is active there.
- Catalina UTM: port the same behavior if Quick Clone/LAN copy scaffolding can
  pause network activity before install.
- Windows: port if the Windows build uses the same Quick Clone tick path.
- Server: not required unless the server UI/controller has equivalent Quick
  Clone scaffolding. Fast Sync service-bit and UDP responder behavior are
  unchanged.

Changed behavior:
- Quick Clone no longer calls `setNetworkActive(false)` simply because a trusted
  LAN source exists.
- If Quick Clone detects it had previously paused Core networking, it now
  resumes Core P2P and reports that it is listening on LAN.
- The active receive status now says `Quick Clone receiving blockchain over LAN:
  requesting block <height> from <host>.`

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: `lanQuickCloneTick()` now resumes a
  stale paused-network state instead of entering it during ordinary
  listen/probe/request work.
- `source/src/qt/nu/docs/quick-clone-status-language.md`: reviewable status
  taxonomy grouped by waiting/listening, supplying, and receiving.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4ac`.
- `source/src/qt/nu/docs/release-notes-26.6.4ac.md`: user-facing notes.

Compatibility notes:
- Consensus, wallet storage, service bits, packet format, checksums, and Core
  block validation are unchanged.
- Older TCP-only peers and v1.0.x peers are unaffected.

Build/package notes:
- Build/package only Defcoin Core Nu for this entry. Explore/ExpFor remains its
  own app and release cycle.

Verification performed:
- Tahoe backend built with `make -C source/src defcoind defcoin-cli defcoin-tx
  defcoin-wallet -j8`.
- Tahoe Qt app built with CMake/Ninja into
  `build/nu-qml-arm64-26.6.4ac`; `DefcoinCoreNuResources` bundled the backend
  tools and verified the app bundle.
- Staged app:
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.4ac-20260604/Defcoin Core Nu.app`.
- Bundle verification passed: `codesign --verify --deep --strict`.
- Bundled backend and CLI reported `v26.6.4ac`; Info.plist reported
  `CFBundleShortVersionString=26.6.4ac`; Spotlight kind reported
  `Application`.
- Old local Tahoe Nu frontend/backend were stopped before relaunching the new
  build. Relaunch smoke test showed one frontend, one bundled backend,
  `networkactive=true`, and `localservicesnames` includes `DEFCOIN_FASTSYNC`.
- Lion port/test is intentionally paused until the separate Lion build thread is
  clear.

Risks / follow-up:
- After Lion is clear, port the matching legacy fix and retest from a clean
  public-chain rebuild. Success criteria: Lion keeps Core networking active,
  sees Tahoe as a peer, and UDP accepted block counts increase instead of
  staying at advertised/checking.

### 26.6.4ab - 2026-06-04 - UDP receiver already-has-block cleanup

Big picture:
- Live Tahoe/Lion testing moved past the earlier non-peer gate: Tahoe accepted
  Lion's LAN UDP Fast Sync probe and served chunks.
- The next failure was on the receiver side. Lion could log an accepted or
  already-known LAN block, then keep the same UDP transfer marked in-flight and
  later time out. In the Lion legacy code this happened when Core already had
  the requested height while late UDP chunks were still being processed.
- This build makes that state explicit: if Core already has the requested
  height while chunks arrive, the UDP attempt is completed without counting it
  as a packet failure, the reservation is released, and the next tick can choose
  the next missing block/source.

Porting priority:
- Lion Intel: port directly to `src/qt/nu/legacy-osx107/main.cpp`. This is the
  receiver-side fix needed after the `26.6.4aa` mapped-LAN sender fix.
- Catalina UTM: port the same guard in its receiver chunk handler if present.
- Windows: port if the Windows build uses this Qt UDP helper path.

Changed behavior:
- UDP Fast Sync no longer leaves a request in-flight after Core has already
  advanced to the chunk's block height.
- Quick Clone no longer treats that already-have state as an offline source or
  missing-chunk timeout.
- No consensus, wallet, service-bit, packet-format, checksum, or block
  validation behavior changes.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: `handleLanFastSyncChunk()` now
  resets the transfer when `height <= m_block_height` after the request id and
  expected height match.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4ab`.
- `source/src/qt/nu/docs/release-notes-26.6.4ab.md`: user-facing notes.

Verification performed:
- Pending Tahoe build/test in this entry.
- Port and live-test on Lion before calling Fast Sync fixed.

Risks / follow-up:
- Retest with Lion after the equivalent legacy patch. Success criteria: Lion
  shows accepted UDP block count increasing without immediately timing out or
  demoting Tahoe as an offline source.

### 26.6.4aa - 2026-06-04 - IPv4-mapped UDP LAN sender fix

Big picture:
- Live Tahoe `26.6.4z` testing proved UDP packets from Lion reached Tahoe, but
  Tahoe still logged `dropped UDP Fast Sync block request from non-peer` for
  `192.168.0.189:10334`.
- The reason was not firewall or service-bit negotiation. Tahoe's UDP socket is
  IPv6-capable, and Qt can surface an IPv4 UDP sender as an IPv4-mapped address.
  `normalizedFastSyncHost()` already handled this, but the private/LAN helper
  only checked `address.protocol()` and therefore missed `192.168.0.189` when it
  arrived through that mapped form.

Porting priority:
- Lion Intel: port directly. This is required for Lion and Tahoe to recognize
  each other as private/LAN UDP senders across mixed IPv4/IPv6 socket paths.
- Catalina UTM and Windows: port directly if their UDP socket can receive mapped
  IPv4 addresses.
- Server: port only if its Fast Sync UDP listener uses the same Qt helper path.

Changed behavior:
- `isInvalidLanDiscoveryAddress()` now checks `toIPv4Address(&ok)` before
  relying on `address.protocol()`, so IPv4-mapped addresses are filtered with
  the same invalid/broadcast/multicast rules as normal IPv4.
- `isPrivateOrLocalFastSyncAddress()` now checks `toIPv4Address(&ok)` before
  relying on `address.protocol()`, so private IPv4 ranges are accepted even when
  the UDP socket reports the sender through an IPv6 wrapper.
- Public internet behavior is unchanged.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: helper-only fix. Packet format,
  service bits, request ids, chunk checksums, and Core block validation are
  unchanged.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4aa`.
- `source/src/qt/nu/docs/release-notes-26.6.4aa.md`: user-facing notes.

Compatibility notes:
- Older TCP-only peers are unaffected.
- The fix only changes whether a private/LAN UDP sender is recognized as LAN;
  it does not admit public UDP block requests.

Build/package notes:
- Build/package only `DefcoinCoreNuResources` for Nu. Explore remains separate.

Verification performed:
- Pending Tahoe build/test in this entry.

Risks / follow-up:
- Retest Lion after restarting or after the UDP quiet period expires. Success
  criteria: Tahoe no longer logs `non-peer` drops for `192.168.0.189` and Lion
  receives accepted UDP chunks or logs a later-stage serving/validation error.

### 26.6.4z - 2026-06-04 - LAN UDP requests without clone_mode

Big picture:
- Live Tahoe `26.6.4y` testing showed one remaining failure after the old app
  was replaced: Lion retried UDP after its quiet period and Tahoe still logged
  `dropped UDP Fast Sync block request from non-peer - 192.168.0.189:10334`.
- The y fix was too narrow because it only admitted trusted-LAN requests when
  the packet had `clone_mode=true`. Lion's request path can issue LAN block
  requests without that flag.

Porting priority:
- Lion Intel: port directly. The same gate must be used when Lion receives LAN
  UDP requests or chunks.
- Catalina UTM: port directly if Fast Sync is enabled.
- Windows: port directly.
- Server: port equivalent behavior if the server serves LAN/private UDP block
  requests with this transport layer.

Changed behavior:
- Private/LAN UDP `request-block` datagrams now reach the guarded serving
  handler even if the packet is not marked `clone_mode`.
- Private/LAN UDP `block-chunk` datagrams now reach the guarded chunk handler;
  the handler still validates request id, height, checksums, and expected hash
  before accepting data.
- Public internet peers still need the normal Fast Sync peer verification before
  request/chunk packets are accepted.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: expanded only the UDP dispatcher and
  handler pre-gates for private/LAN senders. Packet format is unchanged.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4z`.
- `source/src/qt/nu/docs/release-notes-26.6.4z.md`: user-facing notes.

Compatibility notes:
- Older Defcoin Core peers are unaffected because they do not use the Nu UDP
  transport. Normal TCP/Core sync remains unchanged.
- The LAN exception only serves public block data and still goes through the
  existing chunk/request validation path.

Build/package notes:
- Build/package only `DefcoinCoreNuResources` for Nu. Explore remains separate.

Verification performed:
- `git diff --check` passed.
- Tahoe arm64 app configured and built with Qt 6 and `DEFCOIN_NU_RELEASE_NAME=26.6.4z`.
- Backend tools rebuilt from the same source tree; bundled `defcoind` and
  `defcoin-cli` report `v26.6.4z`.
- Built app passed `codesign --verify --deep --strict`.

Risks / follow-up:
- Retest with Lion after its 300-second UDP quiet period or after restarting
  Lion. Success criteria: no new `non-peer` drop on Tahoe and Lion logs accepted
  UDP blocks/chunks rather than Quick Clone timeouts.

### 26.6.4y - 2026-06-04 - LAN UDP request dispatcher and provisional peer fix

Big picture:
- Live Tahoe/Lion test showed UDP was reaching Tahoe, but Tahoe logged repeated
  `dropped UDP Fast Sync block request from non-peer - 192.168.0.189:10334`.
- This was a source-side protocol gate problem, not a firewall/LAN permission
  problem. Tahoe answered Lion probes, then rejected Lion's follow-up block
  requests before the serving handler ran.
- Quick Clone had the same structural bug: the deeper handler allowed trusted
  LAN clone requests, but the outer dispatcher dropped them first.

Porting priority:
- Lion Intel: port directly. Lion needs the same dispatcher fix for receiving
  Quick Clone chunks and the same provisional-LAN peer behavior when it acts as
  a source.
- Catalina UTM: port directly if Fast Sync/Quick Clone is enabled there.
- Windows: port directly.
- Server: port the dispatcher/provisional-peer behavior if the server has this
  QML/Nu UDP transport layer or equivalent request handling.

Changed behavior:
- `request-block` dispatch now allows a packet through when it is either from a
  normal Fast Sync peer or is a `clone_mode` request from a trusted private/LAN
  Quick Clone source.
- `block-chunk` dispatch now allows trusted-LAN Quick Clone chunks through to
  the chunk handler instead of dropping them early.
- `handleLanFastSyncProbe()` now treats a valid private/LAN Fast Sync probe as a
  provisional LAN Fast Sync peer before sending the probe ack. The ack's
  `peer_confirmed` flag now matches the source's willingness to serve the next
  block request.

Changed files and important details:
- `source/src/qt/nu/app/NuRpcService.cpp`: changed only the UDP dispatcher and
  probe acknowledgement path. Packet format is unchanged.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4y`.
- `source/src/qt/nu/docs/release-notes-26.6.4y.md`: user-facing notes.

Compatibility notes:
- This remains compatible with older Defcoin Core peers because the UDP path is
  only used after Defcoin Nu Fast Sync probing. Normal TCP/Core block sync is
  untouched.
- Provisional admission is limited to private/LAN addresses and public block
  serving; it does not expose wallet data.

Build/package notes:
- Build/package only `DefcoinCoreNuResources` for Nu. Explore is separate and
  should not be copied into the Nu distribution folder.

Verification performed:
- `cmake -S source/src/qt/nu/app -B build/nu-qml-arm64-26.6.4y ...`
  completed successfully for arm64 Release.
- `cmake --build build/nu-qml-arm64-26.6.4y --target DefcoinCoreNu -j 8`
  completed successfully.
- `cmake --build build/nu-qml-arm64-26.6.4y --target DefcoinCoreNuResources -j 8`
  completed successfully and bundled only Nu resources.
- `codesign --verify --deep --strict build/nu-qml-arm64-26.6.4y/DefcoinCoreNu.app`
  passed.
- Copied only `Defcoin Core Nu.app` into
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.4y-20260604/`.
- Distribution bundle `codesign --verify --deep --strict` passed.
- Distribution bundle smoke test exited with status 0.

Risks / follow-up:
- Retest with Tahoe serving Lion. Success criteria: Tahoe logs chunk serving or
  no longer logs `non-peer`, and Lion logs accepted UDP blocks/chunks instead of
  Quick Clone timeouts.

### 26.6.4x packaging correction - 2026-06-04 - Explore is separate from Nu distribution

Big picture:
- Defcoin Core Explore is a separate application with its own build thread and
  distribution folder. It can inherit Nu's visible build number, but it should
  not be copied into `Distribution_Versions/Defcoin Core Nu/...` during a
  Nu-only build.
- The current `Nu-26.6.4x-20260604` distribution folder was corrected so it
  contains only `Defcoin Core Nu.app`.

Porting priority:
- Lion Intel: keep Explore out of the Lion Nu distribution folder unless the
  Explore thread explicitly requests an Explore build.
- Catalina UTM: same separation.
- Windows: same separation; Nu setup/portable folders should not contain the
  Explore app.
- Server: no effect.

Changed behavior:
- CMake no longer includes `DefcoinCoreExplore` or `DefcoinCoreExploreResources`
  in the default Nu `ALL` build. Explore remains buildable through explicit
  targets for its own thread.

Changed files and important details:
- `source/src/qt/nu/app/CMakeLists.txt`: `DefcoinCoreExplore` is marked
  `EXCLUDE_FROM_ALL`; `DefcoinCoreExploreResources` is no longer an `ALL`
  custom target.
- `source/src/qt/nu/docs/build-and-installer-runbook.md`: Nu and Explore output
  paths are now separated.

Compatibility notes:
- This is a build/distribution boundary correction only. It does not alter Nu
  runtime behavior, backend behavior, wallet storage, Fast Sync, or Quick Clone.

Build/package notes:
- For Nu-only fixes, build/package `DefcoinCoreNuResources` and copy only
  `Defcoin Core Nu.app`.
- For Explore fixes, the Explore thread should explicitly build
  `DefcoinCoreExploreResources` and stage under `Distribution_Versions/Defcoin
  Core Explore/...`.

Verification performed:
- Removed `Defcoin Core Explore.app` from
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.4x-20260604/`.
- `cmake -S source/src/qt/nu/app -B build/nu-qml-arm64-26.6.4x ...` configured
  successfully after the CMake target change.
- `ninja -C build/nu-qml-arm64-26.6.4x -t query all` now lists
  `DefcoinCoreNu.app/Contents/MacOS/DefcoinCoreNu` and
  `DefcoinCoreNuResources`, with no Explore target in the default `all`
  dependency chain.

Risks / follow-up:
- Existing older Nu distribution folders may still contain historical Explore
  copies. Correct them only when preparing those specific folders for use.

### 26.6.4x - 2026-06-04 - Peer row actions and Quick Clone offline source acknowledgement

Big picture:
- Fix a Metrics > Peers interaction bug where `Retest FastSync` could report
  "Select one peer row first" even when the user had visually selected one row.
- Make Quick Clone receiver state honest when a trusted LAN source disappears:
  a source that times out or cannot receive the UDP request is marked offline
  and removed from active verified source sets until it reappears through a
  later beacon/probe.

Porting priority:
- Lion Intel: port this directly. The user hit the row-selection failure on the
  Tahoe UI, and the same table/action pattern exists in Lion.
- Catalina UTM: port the QML row-key helper and Peer button validation if the
  same QML table is present.
- Windows: port directly so setup/portable builds keep the same peer-action
  behavior.
- Server: no UI port needed. Server Quick Clone/Fast Sync code should use the
  same offline-source demotion if/when it runs receiver-side Quick Clone logic.

Changed behavior:
- `Retest FastSync` and `Ban peer` now call the backend only with one numeric
  node id resolved from the current table rows. Stale or non-row selections no
  longer pass through as invalid ids.
- `NuDataTable.selectedDataRowKeys()` returns selected row keys from real
  current rows and falls back from a selected cell/range to its data row.
- Quick Clone stores the current source host per in-flight request. On timeout
  or send failure, the receiver removes that host from Quick Clone candidate,
  snapshot candidate, UDP available, UDP used, and current target sets, records a
  diagnostic, and reports that the source was marked offline.

Changed files and important details:
- `source/src/qt/nu/qml/Components/NuDataTable.qml`: added
  `selectedDataRowKeys()` helper. It filters row keys against the current sorted
  rows to avoid stale selection keys.
- `source/src/qt/nu/qml/Views/NodeView.qml`: Peer actions now use
  `selectedSinglePeerRowId()` instead of `selectedPeerNodeIds[0]`.
- `source/src/qt/nu/app/NuRpcService.h/.cpp`: added
  `m_lan_fast_sync_current_host` and
  `acknowledgeLanQuickCloneSourceOffline(...)`; Quick Clone timeouts and send
  failures now demote the exact source host.
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4x`.
- `source/src/qt/nu/docs/release-notes-26.6.4x.md`: user-facing release notes.

Compatibility notes:
- The Quick Clone change does not alter UDP packet format, service bits, Core
  validation, or wallet data. It is receiver-side source bookkeeping.
- A source can be admitted again when it later sends a beacon/probe response.

Build/package notes:
- Build with `-DDEFCOIN_NU_RELEASE_NAME=26.6.4x`.
- Run resource bundle targets before copying distribution apps; otherwise the
  app can launch with missing splash/QML resources.
- Nu-only fixes should copy only `Defcoin Core Nu.app` into the Nu distribution
  folder. Explore has its own distribution cycle and output folder.

Verification performed:
- `qmllint -I source/src/qt/nu/qml -I build/nu-qml-arm64-26.6.4w/DefcoinCoreNu.app/Contents/Resources/qml source/src/qt/nu/qml/Components/NuDataTable.qml source/src/qt/nu/qml/Views/NodeView.qml` exited 0; it still reports the known local `Defcoin.Nu` import warning.
- `git diff --check` passed.
- `cmake -S source/src/qt/nu/app -B build/nu-qml-arm64-26.6.4x -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 -DQt6_DIR=/opt/homebrew/lib/cmake/Qt6 -DDEFCOIN_NU_RELEASE_NAME=26.6.4x` configured successfully.
- `cmake --build build/nu-qml-arm64-26.6.4x --target DefcoinCoreNu DefcoinCoreExplore -j 8` passed before the Explore distribution boundary correction.
- `cmake --build build/nu-qml-arm64-26.6.4x --target DefcoinCoreNuResources DefcoinCoreExploreResources -j 8` passed before the Explore distribution boundary correction.
- `codesign --verify --deep --strict` passed for the Nu build and distribution app.
- Distribution `Defcoin Core Nu.app/Contents/MacOS/DefcoinCoreNu --smoke-test` exited 0.

Risks / follow-up:
- If a LAN source is temporarily overloaded rather than offline, this build
  still demotes it after the timeout. That is intentional for the current
  trusted-LAN copy flow because another source should be tried promptly.

### 26.6.4w - 2026-06-04 - Shared QML interaction polish

Big picture:
- Broad UI polish pass over shared QML controls rather than per-screen
  redesign. The goal is better perceived quality everywhere with low behavioral
  risk.
- Buttons, nav items, tabs, combo boxes, text fields, and metric rows now have
  smoother hover/focus/press feedback.
- Combo box arrow clicks and keyboard activation are more reliable, which helps
  Wallet selector, Send address book, Mining pool picker, and other drop-downs.
- Metric rows now have a subtle hover surface, improving discoverability of
  dense status/tooltips without taking more vertical space.

Porting priority:
- Lion Intel: port these shared QML component changes unless Qt 5.5/5.6 lacks a
  specific animation or handler. If so, keep the visual intent and simplify the
  animation, not the layout.
- Catalina UTM: port directly if the QML shell matches Tahoe.
- Windows: port directly; this also improves keyboard and drop-down behavior on
  Windows builds.
- Server: no server changes.

Changed behavior:
- `NuActionButton` and `NuNavButton` press with a very small scale animation and
  animate focus/hover colors.
- `NuActionButton` adds a restrained bottom activity line on hover/focus/press.
- `NuComboBox` supports Return/Enter/Space popup toggling and the indicator area
  opens the drop-down reliably.
- `NuTabButton` gets rounded tabs, animated hover/focus colors, and a selected
  bottom rule.
- `NuTextField` animates focus/hover borders.
- `NuMetricRow` is now a small hoverable rectangle with tighter internal spacing.

Changed files and important details:
- `source/src/clientversion.h`: visible release label is `26.6.4w`.
- `source/src/qt/nu/app/CMakeLists.txt`: app bundle release label is
  `26.6.4w`.
- `source/src/qt/nu/qml/Theme/Tokens.qml`: adds `motionFast` and
  `motionNormal` constants for shared animations.
- `source/src/qt/nu/qml/Components/NuActionButton.qml`: hover/focus/press
  motion and bottom affordance.
- `source/src/qt/nu/qml/Components/NuComboBox.qml`: keyboard popup toggle,
  animated chevron, and click target on the indicator.
- `source/src/qt/nu/qml/Components/NuMetricRow.qml`: hover surface and tighter
  row layout.
- `source/src/qt/nu/qml/Components/NuNavButton.qml`: press motion and animated
  hover/focus colors.
- `source/src/qt/nu/qml/Components/NuTabButton.qml`: rounded/animated tab
  treatment and selected rule.
- `source/src/qt/nu/qml/Components/NuTextField.qml`: animated focus/hover
  border.

Compatibility notes:
- No backend, RPC, wallet, or protocol behavior changed.
- If any older Qt target has trouble with grouped-property color animations,
  remove only that animation line; the static states should remain identical.

Build/package notes:
- Rebuild both `DefcoinCoreNu` and `DefcoinCoreExplore` because shared QML assets
  changed.
- On macOS, do not copy the app immediately after building only the executable
  targets. The runnable bundles are produced by `DefcoinCoreNuResources` and
  `DefcoinCoreExploreResources` or by building the default `ALL` target. Copying
  after only `DefcoinCoreNu`/`DefcoinCoreExplore` leaves a binary-only `.app`
  with no `Contents/Resources/nu` payload, which shows a logo-less splash and
  then exits when QML cannot load.

Verification performed:
- `qmllint -I source/src/qt/nu/qml -I build/nu-qml-arm64-26.6.4v/qml
  source/src/qt/nu/qml/Components/NuActionButton.qml
  source/src/qt/nu/qml/Components/NuComboBox.qml
  source/src/qt/nu/qml/Components/NuMetricRow.qml
  source/src/qt/nu/qml/Components/NuNavButton.qml
  source/src/qt/nu/qml/Components/NuTabButton.qml
  source/src/qt/nu/qml/Components/NuTextField.qml
  source/src/qt/nu/qml/Views/HomeView.qml source/src/qt/nu/qml/Main.qml`
  exited successfully. Existing context-property import/unqualified warnings
  remain, but no new syntax or shadowing error was reported for this pass.
- `git diff --check` passed.
- `cmake -S source/src/qt/nu/app -B build/nu-qml-arm64-26.6.4w -G Ninja
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
  -DQt6_DIR=/opt/homebrew/lib/cmake/Qt6
  -DDEFCOIN_NU_RELEASE_NAME=26.6.4w` completed.
- `cmake --build build/nu-qml-arm64-26.6.4w --target DefcoinCoreNu
  DefcoinCoreExplore -j 8` completed.
- `cmake --build build/nu-qml-arm64-26.6.4w --target DefcoinCoreNuResources
  DefcoinCoreExploreResources -j 8` completed and deployed QML/assets, bundled
  backend tools, Qt frameworks/plugins/QML imports, and ad-hoc signing.
- Both app bundles report `CFBundleShortVersionString` and `CFBundleVersion` as
  `26.6.4w`.
- Verified the repaired bundle contains
  `Contents/Resources/nu/assets/brand/defcoin-nu-coin-stack-hires.png`,
  `Contents/Resources/nu/qml/Main.qml`, and
  `Contents/Resources/nu/bin/defcoind`.
- `codesign --verify --deep --strict` passed for both repaired app bundles.
- The repaired distribution `Defcoin Core Nu.app` passed `--smoke-test`.
- Copied Apple Silicon apps to
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.4w-20260604/`.

Risks / follow-up:
- Visual smoke test should click the Wallet selector, Mining pool picker, Send
  address book selector, tabs, and Advanced tools toggle.

### 26.6.4v - 2026-06-04 - Quick Clone warning and streaming scheduler contract

Big picture:
- Quick Clone now has a warning before the manual `Sync using Quick Clone now`
  action arms the feature. The automatic missing-chain prompt already warned
  users; the manual path now carries the same trust/partial-copy warning.
- The authoritative Fast Sync/DCOL spec now defines the Quick Clone receiver
  scheduler: receiver-controlled, two ranges in flight per source at startup,
  replenish only after streaming checksum success, retry timed-out ranges from
  another compatible source, and send best-effort cancel messages for stale
  requests.
- The checksum direction is intentionally speed-first: no paranoid UI mode.
  Quick Clone should use one deterministic streaming checksum family and update
  it while bytes are already being read/written.
- This build still does not install copied chainstate. It defines the contract
  and UI warning while preserving the manifest gate added in 26.6.4u.

Porting priority:
- Lion Intel: port the manual Quick Clone warning dialog and the documentation
  contract. Do not add a second competing clone implementation.
- Catalina UTM: port the warning dialog if the QML Settings surface exists.
- Windows: port the warning dialog; Windows wording can mention firewall if a
  later build adds a platform-specific prompt.
- Server: update docs only. The server should not advertise Quick Clone snapshot
  availability until it can create immutable manifests.

Changed behavior:
- Clicking `Sync using Quick Clone now` opens a selectable warning first.
- The warning states that Quick Clone is trusted-LAN only, copies public
  blockchain data only, partial copies are not usable chain state, and final
  install requires staged-copy verification and a backend restart/swap.
- Automatic Quick Clone prompt text also says partial clones are not usable and
  snapshot replacement is gated by manifest plus streaming-checksum checks.

Changed files and important details:
- `source/src/clientversion.h`: visible release label is `26.6.4v`.
- `source/src/qt/nu/app/CMakeLists.txt`: app bundle release label is
  `26.6.4v`.
- `source/src/qt/nu/qml/Views/SettingsView.qml`: manual Quick Clone button now
  opens `quickCloneStartDialog`; accept calls `NuService.syncUsingQuickCloneNow`.
- `source/src/qt/nu/app/NuRpcService.cpp`: automatic prompt and user message
  include partial-copy and streaming-checksum warnings.
- `source/src/qt/nu/docs/fast-sync-protocol.md`: adds the receiver scheduler
  and streaming checksum contract.

Compatibility notes:
- Existing Fast Sync packet transport remains unchanged in this pass.
- The active snapshot mover remains blocked until immutable source manifests and
  receiver staging/install code exist.

Build/package notes:
- Rebuild both `DefcoinCoreNu` and `DefcoinCoreExplore` because the shared
  service and QML Settings surface changed.

Verification performed:
- `git diff --check` passed.
- `qmllint -I source/src/qt/nu/qml -I build/nu-qml-arm64-26.6.4v/qml
  source/src/qt/nu/qml/Views/SettingsView.qml source/src/qt/nu/qml/Main.qml`
  completed with the existing context-property warnings and no syntax errors.
- `cmake -S source/src/qt/nu/app -B build/nu-qml-arm64-26.6.4v -G Ninja
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64
  -DQt6_DIR=/opt/homebrew/lib/cmake/Qt6 -DDEFCOIN_NU_RELEASE_NAME=26.6.4v`
  configured successfully.
- `cmake --build build/nu-qml-arm64-26.6.4v --target DefcoinCoreNu
  DefcoinCoreExplore -j 8` passed.
- `plutil -p build/nu-qml-arm64-26.6.4v/DefcoinCoreNu.app/Contents/Info.plist`
  and the matching Explore bundle both reported `CFBundleShortVersionString`
  and `CFBundleVersion` as `26.6.4v`.
- Copied both apps to
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.4v-20260604/`.

Risks / follow-up:
- Implement the actual staged snapshot transfer only after source manifests,
  range checksums, cancel messages, and atomic receiver swap are present.

### 26.6.4u - 2026-06-04 - Quick Clone menu surface and validation guardrails

Big picture:
- The visible trusted-LAN copy concept is now **Quick Clone**. DCOL / Direct
  Copy Over LAN remains the technical name in help text and developer docs.
- The previous visible `LAN Fast Copy` wording has been removed from the app
  surface. Existing internal member names such as `lanQuickCloneEnabled` remain
  implementation scaffolding for now to keep the Tahoe/Lion diff smaller.
- Quick Clone is treated as a trusted-LAN public-chain workflow. It must never
  copy wallets, private keys, passphrases, config files, peers, bans, address
  books, or RPC cookies.
- The destructive snapshot install step is intentionally gated by future
  manifest/export proof. This build adds the menu surface, prompt cycle,
  manual arming action, and Core `verifychain` validation action without
  allowing a live `chainstate` folder to be copied unsafely.

Porting priority:
- Lion Intel: port the same Settings > Connectivity card, signal/property
  surface, prompt-cycle logic, and `verifychain` button. Keep any Lion-specific
  UDP transport fixes intact.
- Catalina UTM: same UI/API port if the QML Nu shell is present.
- Windows: same user-facing naming and validation controls; platform firewall
  messaging remains Windows-specific where applicable.
- Server: no server change required for this UI pass. Server Fast Sync remains
  transport-only and should not advertise Quick Clone/DCOL snapshot availability
  until immutable manifest exports exist.

Changed behavior:
- Settings > Connectivity now has a **Quick Clone** card with:
  `Allow Quick Clone from trusted LAN nodes`, `Automatically validate blocks
  after Quick Clone`, `Sync using Quick Clone now`, and
  `Validate existing blockchain`.
- `Validate existing blockchain` runs Core RPC `verifychain 4 0` and reports
  success, failure, or unsupported backend state without touching wallet files.
- A Quick Clone prompt can be emitted once per missing-chain cycle when LAN
  discovery is enabled, the node is more than 5% behind, and a LAN Nu candidate
  has been seen. If rejected, it does not nag again until the node catches up
  below the 5% threshold and later falls behind again.
- Metrics remains read-only. It can show Quick Clone status and validation
  status, but does not expose Quick Clone controls.

Changed files and important details:
- `source/src/clientversion.h` and `source/src/qt/nu/app/CMakeLists.txt`:
  visible release label is `26.6.4u`.
- `source/src/qt/nu/app/NuRpcService.h/.cpp`: added Quick Clone auto-validate
  property, validation status/running state, prompt signal, prompt-cycle helper
  methods, `syncUsingQuickCloneNow()`, `acceptQuickClonePrompt()`,
  `declineQuickClonePrompt()`, and `validateExistingBlockchain()`.
- `source/src/qt/nu/qml/Views/SettingsView.qml`: replaced the old LAN Fast
  Copy checkbox with a Quick Clone card and manual validation controls.
- `source/src/qt/nu/qml/Main.qml`: added a selectable/copyable Quick Clone
  prompt dialog with `Use Quick Clone` and `Keep normal sync`.
- `source/src/qt/nu/docs/fast-sync-protocol.md`,
  `source/src/qt/nu/docs/defcoin-core-nu-goals.md`, and
  `source/src/qt/nu/docs/functionality-map.md`: updated the conceptual
  boundary so Quick Clone is the only visible name and DCOL is the technical
  manifest-gated snapshot workflow.

Compatibility notes:
- Existing settings key `LanQuickCloneEnabled` is preserved so current users do
  not lose their preference during the rename.
- The current UDP block-body code still submits assembled blocks through Core
  validation. A true validation-bypass Quick Clone must wait for immutable
  source exports plus manifest/hash verification before replacing any public
  chain directories.
- Quick Clone remains LAN/trusted-owner only. Public internet Fast Sync stays
  separate and validation-preserving.

Verification performed:
- `git diff --check` passed.
- `cmake -S source/src/qt/nu/app -B build/nu-qml-arm64-26.6.4u -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 -DQt6_DIR=/opt/homebrew/lib/cmake/Qt6 -DDEFCOIN_NU_RELEASE_NAME=26.6.4u` configured successfully.
- `cmake --build build/nu-qml-arm64-26.6.4u --target DefcoinCoreNu -j 8` passed.
- `cmake --build build/nu-qml-arm64-26.6.4u --target DefcoinCoreExplore -j 8` passed because the shared `NuRpcService` changed.
- `plutil -p build/nu-qml-arm64-26.6.4u/DefcoinCoreNu.app/Contents/Info.plist` reported `CFBundleShortVersionString=26.6.4u` and `CFBundleVersion=26.6.4u`.
- `qmllint` on the touched QML files completed without syntax errors. It still reports the known context-property/unqualified-access warnings for `NuService`, `NuPlatform`, and build metadata, which predate this change.

Risks / follow-up:
- Implement immutable source export advertisements:
  manifest id, source height, best block hash, complete file list, byte sizes,
  per-file hashes, and export status.
- Implement receiver staging and atomic replacement only after the receiver
  backend is stopped and the manifest verifies.
- Do not allow any `blocks`, `chainstate`, or `indexes` replacement without the
  manifest gate.

### server-fast-sync-20260604 - 2026-06-04 - dc903 responder parity with current Fast Sync probes

Big picture:
- The public dc903 Fast Sync responder was updated to match the current Nu
  requester wire behavior. Current wallets probe first; a server that only
  accepts old `request-block` packets will stay stuck at `Advertised` or
  `Probe sent`.
- This is a server-side deployment plus protocol-doc update, not a new desktop
  version bump.

Porting priority:
- Lion Intel: ensure the Lion requester expects `probe -> probe-ack` before
  block requests and continues using service bit 29, not User-Agent text, for
  capability.
- Catalina UTM: same as Lion if Fast Sync is present there.
- Windows: same requester behavior as Tahoe; do not special-case server peers.
- Server: deploy `source/src/qt/nu/tools/defcoin_fast_syncd.py` when the
  requester protocol changes; do not leave the server on an older responder.

Changed behavior:
- The server sidecar now answers `probe` packets with `probe-ack`.
- Server authorization is based on connected Core TCP peers advertising
  `NODE_DEFCOIN_FASTSYNC` in `getpeerinfo.services`; User-Agent is diagnostics
  only.
- The sidecar remains responder-only. It does not request blocks from clients,
  does not bypass validation for clients, and does not change legacy v1.0.x TCP
  behavior.

Changed files and important details:
- `source/src/qt/nu/docs/fast-sync-protocol.md`: added a server feature parity
  section and deployment checks requiring loopback probe and block request
  verification.
- `/usr/local/sbin/defcoin-fast-syncd` on dc903: replaced with the current
  Tahoe Nu script. Remote backup:
  `/usr/local/sbin/defcoin-fast-syncd.bak-20260604-122130`.
- `/Volumes/TB5_4TB/d/litecoincore/Defcoin Core Nu/local-dev-notes/SERVER_CHANGELOG.md`:
  local operational server changelog updated.
- `/Volumes/TB5_4TB/server_backups/dc903_dfc_2026-04-15/REMOTE_FINDINGS_2026-04-15.txt`:
  live server evidence trail updated.

Compatibility notes:
- Public server requests are capped to internet-safe datagram sizing unless the
  requester is private/local.
- Older Defcoin Core peers do not advertise bit 29 and are therefore never
  placed in the UDP allowlist.

Verification performed:
- `python3 -m py_compile source/src/qt/nu/tools/defcoin_fast_syncd.py` passed.
- Remote service restart passed; `defcoind`, `p2pool-defcoin`, and
  `defcoin-fast-syncd` were active.
- `ss -lunp` showed UDP listeners on `0.0.0.0:10334` and `[::]:10334`.
- Remote loopback probe returned `probe-ack`, then block 1 with matching chunk
  and whole-block SHA-256 checksums.
- Public Tahoe probe to `defcoin.dc903.org:10334` returned `probe-ack`, then
  block 1 with matching checksums.
- TCP communication checks succeeded for Core P2P `10332`, P2Pool `1337`, and
  `https://defcoin.dc903.org/pool`.

Risks / follow-up:
- A real wallet should still be observed accepting at least one server-sourced
  UDP block during IBD before calling public Fast Sync fully proven.
- The server backend still reports `/DefcoinCoreNu:26.6.1/`; that does not
  block the responder sidecar, but a future server-core upgrade should keep the
  Fast Sync service bit and RPC behavior aligned with Tahoe.

### 26.6.4t - 2026-06-04 - LAN Fast Copy naming, Metrics row density, macOS bundle metadata

Big picture:
- This build separates three concepts that had drifted together in the UI:
  Fast Sync, LAN Fast Copy, and Quick Clone/DCOL.
- Fast Sync remains a transport-only path. It must not skip Core validation.
- LAN Fast Copy is the current online LAN block-copy mode. It pauses ordinary
  P2P on the receiver and requests checksum-protected block bytes from trusted
  LAN Nu peers, but still submits each block through Core acceptance.
- Quick Clone is now reserved as the human-friendly name for DCOL, a future
  trusted-LAN snapshot workflow intended to bypass historical validation by
  copying verified public chain state. Quick Clone/DCOL is not implemented in
  this build.
- The Metrics Status table now sizes one-line rows compactly while still
  allowing wrapped rows to grow.
- Apple Silicon macOS app bundles now stamp explicit macOS metadata to avoid
  System Information misclassifying builds.

Porting priority:
- Lion Intel: port the user-facing naming and docs concepts where the Lion UI
  exposes this setting. Do not rename backend internals mechanically unless the
  Lion source is already being touched for nearby reasons.
- Catalina UTM: port the naming, Metrics table row-height behavior if that UI
  exists, and the macOS bundle metadata pattern. Choose a deployment target that
  honestly matches the Qt libraries used by Catalina, not Tahoe's `26.0`.
- Windows: port naming and Metrics row-density behavior. The macOS plist work is
  not relevant.
- Server: no immediate code change from this entry. Server docs should preserve
  the same distinction: Fast Sync is transport-only; Quick Clone/DCOL is future
  snapshot copy.

Changed behavior:
- Settings no longer says `Quick Clone blocks from trusted LAN peers`; it says
  `LAN Fast Copy from trusted peers`.
- Metrics no longer labels the row `Quick Clone (LAN)`; it labels it `LAN Fast
  Copy`.
- Runtime status text now says LAN Fast Copy for the current validated LAN block
  transfer path.
- Quick Clone/DCOL is documented as future validation-bypass snapshot mode,
  limited to `blocks`, `chainstate`, and optional `indexes`; it must never copy
  wallets, keys, settings, peers, ban files, or RPC cookies.
- Metrics Status rows with one line of text no longer use the old fixed wrapped
  row height.

Changed files and important details:
- `source/src/clientversion.h`: visible backend/client label is `26.6.4t`.
- `source/src/qt/nu/app/NuRpcService.cpp` and `.h`: user-visible strings were
  renamed from Quick Clone to LAN Fast Copy. Internal member names such as
  `m_lan_quick_clone_status` intentionally remain for now to avoid a noisy
  refactor.
- `source/src/qt/nu/qml/Views/SettingsView.qml`: checkbox text and hover help
  explain that LAN Fast Copy still uses Core acceptance and that Quick
  Clone/DCOL is future work.
- `source/src/qt/nu/qml/Components/NuDataTable.qml`: row height calculation now
  accepts row data and estimates wrapped text lines from column widths. This is
  why one-line Status rows shrink but long rows can still wrap.
- `source/src/qt/nu/qml/Views/NodeView.qml`: Status table sets
  `wrapBodyText: true`, `maxWrappedBodyLines: 3`, and `compact: true`.
- `source/src/qt/nu/docs/fast-sync-protocol.md`: now defines Fast Sync, LAN
  Fast Copy, and Quick Clone/DCOL as separate mechanisms.
- `source/src/qt/nu/docs/defcoin-core-nu-goals.md`: goal 8 was updated to keep
  those concepts distinct.
- `source/src/qt/nu/app/MacOSXBundleInfo.plist.in`: new explicit macOS plist
  template. It sets `CFBundleSupportedPlatforms=MacOSX`,
  `LSApplicationCategoryType=public.app-category.finance`, high-resolution
  capable flags, and `LSMinimumSystemVersion`.
- `source/src/qt/nu/app/CMakeLists.txt`: both Nu and Explore targets use the
  custom plist template. The default Tahoe deployment target is `26.0` because
  Homebrew Qt 6.11.1 on Tahoe has QtQuick frameworks stamped with `minos 26.0`.

Compatibility notes:
- The Tahoe default `CMAKE_OSX_DEPLOYMENT_TARGET=26.0` is correct for Tahoe's
  current Homebrew Qt package set, but it is not a universal recommendation.
  Lion and Catalina must use Qt libraries built for their target OS and set the
  deployment target to match those libraries.
- If a cross-build uses older Qt libraries with lower `minos`, it should pass an
  explicit `CMAKE_OSX_DEPLOYMENT_TARGET` for that platform instead of inheriting
  Tahoe's default.
- The macOS `Kind: iOS` concern should be investigated by checking plist keys
  and Mach-O load commands, not by guessing from Qt Creator alone:
  `CFBundleSupportedPlatforms`, `LSMinimumSystemVersion`, `LSRequiresIPhoneOS`,
  `UIDeviceFamily`, `DTPlatformName`, and `vtool -show-build`.

Build/package notes:
- Tahoe build directory used for verification:
  `build/nu-qml-arm64-26.6.4t`.
- Staged app:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.4t-20260604/Defcoin Core Nu.app`.
- Qt Creator was installed but no project-local `.user` kit file or saved kit
  config was found. The verified CMake cache/build metadata is the source of
  truth for this build.

Verification performed:
- Backend tools report `v26.6.4t`:
  `defcoind`, `defcoin-cli`, `defcoin-tx`, and `defcoin-wallet`.
- `git diff --check` passed before commit.
- Nu app smoke launch passed with `DEFCOIN_NU_NO_BACKEND_AUTOSTART=1` and
  `--smoke-test --route metrics`.
- Codesign verification passed:
  `codesign --verify --deep --strict --verbose=2`.
- Plist checks on the staged app showed:
  `CFBundleSupportedPlatforms=MacOSX`,
  `LSMinimumSystemVersion=26.0`,
  `CFBundlePackageType=APPL`,
  `CFBundleShortVersionString=26.6.4t`.
- Spotlight metadata showed:
  `kMDItemKind=Application`,
  `kMDItemCFBundleIdentifier=org.defcoincore.DefcoinCoreNu`,
  `kMDItemExecutableArchitectures=(arm64)`.
- `vtool -show-build` showed platform `MACOS` for app and bundled Qt binaries.
  No iOS-only plist keys were found.

Risks / follow-up:
- LAN Fast Copy still validates blocks, so it will not deliver the full speed
  gain expected from Quick Clone/DCOL. Implement DCOL later as a stopped-backend
  or coherent-snapshot copy of public chain state.
- The row-height calculation uses rough text-width estimation. If a future QML
  table uses unusual icons or custom delegates, verify row picking and scrolling.
- If future Homebrew Qt changes its deployment target again, rerun the plist and
  `vtool` checks rather than hard-coding assumptions.

## 26.6.4ak - 2026-06-05 - Fast Sync reservation parity audit

Scope:
- Tahoe and Lion now use the same lower-level Fast Sync reservation rule:
  UDP is only a transport option after Core has selected a peer/block through
  normal peer state.
- The old Lion-only header-chain/local-block fallback scheduler was removed.

Protocol behavior:
- `reservefastsyncblock transport-verified <nodeid>` only marks UDP transport
  as proven for that peer.
- `reservefastsyncblock reserve-next <nodeid>` now relies on
  `ProcessBlockAvailability()`, `pindexBestKnownBlock`, and
  `FindNextBlocksToDownload()`.
- If Core has no eligible block, the call reports a Core-derived reason such as
  `peer-best-block-unknown`, `waiting-for-block-window`, or
  `no-downloadable-block`.
- `submitblock` result `inconclusive` is treated as validation-still-running,
  not a hard UDP transfer failure.

Cross-build note:
- Port the backend reservation function as a unit. Do not re-add independent
  Fast Sync height scanning on Lion or Catalina.

## 26.6.4al - 2026-06-05 - Fast Sync self-address guard

Scope:
- Added a self-address exclusion to Fast Sync candidate collection.
- This prevents a NATed test VM from making the host see an inbound peer as the
  host's own LAN IP and then probing itself over UDP.

Protocol behavior:
- The node may still answer valid UDP probe/request packets arriving from LAN
  peers.
- The node no longer adds its own interface address to the outbound UDP Fast
  Sync / Quick Clone candidate set.

Verification:
- Tahoe and Lion backend reservation function bodies diff clean.
- Both builds advertise service bit 29 / `DEFCOIN_FASTSYNC`.
- Lion UTM successfully received a `probe-ack` and a `block-chunk` from Tahoe
  using the framed `DFCLAN1` UDP packet format.

## 26.6.4ao - 2026-06-05 - TCP-off launch mode for UDP testing

Scope:
- Added `--debug-disable-core-tcp-sync` and
  `DEFCOIN_NU_DEBUG_DISABLE_CORE_TCP_SYNC=1`.
- The switch disables Core TCP block-body fetches only. Header sync, peer
  negotiation, service-bit discovery, and Core reservation logic remain active.
- Superseded by 26.6.4aq: `--debug-disable-core-sync` is no longer treated as
  the TCP-only test alias. Use `--debug-disable-core-tcp-sync` for UDP Fast Sync
  isolation.

Cross-build note:
- Use this mode to isolate UDP Fast Sync. Total Core sync shutdown is for
  Quick Clone/DCOL tests only.

## 26.6.4ap - 2026-06-05 - UDP-only selector in TCP-off test mode

Scope:
- When Core TCP block copy is disabled by debug launch switch, Tahoe and Lion
  now force UDP quota whenever at least one Fast Sync peer is visible.
- Removed the selector-side update of the global probe timestamp before a probe
  is actually sent in this debug mode.
- Added throttled `UDP target selection empty` diagnostics with peer, verified,
  used, failed, and debug-mode counts.

Cross-build note:
- If a legacy build sees service bit 29 but sends no UDP probe, compare its
  selector and target-selection logic against this release before touching the
  backend reservation RPC.

## 26.6.4aq - 2026-06-05 - Split Core TCP-off from Core P2P-off

Scope:
- `--debug-disable-core-tcp-sync` now disables only Core TCP block-body fetching.
- `--debug-disable-core-sync` now disables Core P2P sync and is reserved for
  Quick Clone/DCOL isolation tests.
- Tahoe and Lion both pass `-defcoindisablecoretcpblocks=1` when either switch
  is active, but only the full Core Sync switch passes `-networkactive=0`.

Cross-build note:
- UDP Fast Sync tests should use
  `--debug-disable-core-tcp-sync --debug-disable-quick-clone`.
- In that mode, backend launch args must include `-networkactive=1` so peer
  negotiation, header sync, service bit 29, and Core reservation state remain
  alive while TCP block bodies are suppressed.
