# Defcoin Core Nu 26.6.5d Release Notes

26.6.5d is a sync-visibility and Quick Clone scheduler fix after 26.6.5b.

## Changes

- The mast sync text now reports the most recent active sync transport:
  `via TCP`, `via UDP FS`, `via UDP QC`, or `Up to Date`.
- Added compact mast traffic rates: `TX:` and `RX:` in bits per second.
- Quick Clone block requests now explicitly mark clone mode per request instead
  of inheriting it from the global setting. This prevents normal UDP Fast Sync
  and Quick Clone status/counters from being mixed together.
- Quick Clone now asks for the earliest missing Core-reserved block before
  filling farther-ahead staged blocks.
- Added throttled debug-log marker `NU_UDP_FASTSYNC_STAGED_GAP` with mode,
  expected height, staged range, active transfer count, and local block height.
- The Quick Clone settings now default to receiving and providing LAN clones:
  `Allow Quick Clone from LAN nodes` and `Provide Quick Clones to LAN nodes`.
- `Allow Quick Clone from LAN nodes` now means the feature is armed/allowed.
  A separate session request flag starts actual Quick Clone block scheduling
  only after the user accepts the prompt or clicks the manual Quick Clone
  action.
- Traffic rate displays now use bit-rate units such as `Kb/s` and `Mb/s`.
  Byte units remain for total transferred volume.
- Metrics Traffic details now graph TCP and UDP. Quick Clone UDP remains part of
  UDP rather than a separate graph line or footer total.
- The Traffic footer now shows TCP, UDP, and Total traffic in a tighter
  right-aligned grid.
- Peer table formatting now left-aligns Services, centers Protocol Version and
  Magic, and pads workstation/LAN-icon cells during auto-fit.

## Cross-Build Notes

- Lion, Catalina, and Windows must port the same per-request `clone_mode`
  handling and the same allowed-vs-requested Quick Clone split. Do not infer
  Quick Clone from the global Quick Clone setting when a UDP block chunk arrives
  or when a LAN source is discovered.
- Lion should preserve the new staged-gap log text so Tahoe/Lion logs can be
  compared directly.
- Windows should inherit the same inline LAN icon padding in the peer table.
- Server builds do not need Quick Clone settings or UI, but should keep Fast
  Sync as a transport-only responder and continue counting Quick Clone nowhere.

## Verification

- `git diff --check` passed.
- `qmllint -I src/qt/nu/qml` on the touched QML files exited 0 with only the
  known `Defcoin.Nu` import/context-property warnings.
- A native Apple Silicon `DefcoinCoreNu` build completed in
  `build/nu-qml-arm64-26.6.5d`.
