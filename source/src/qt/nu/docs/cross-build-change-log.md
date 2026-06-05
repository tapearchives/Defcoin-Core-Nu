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
