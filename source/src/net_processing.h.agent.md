# net_processing.h Agent Notes

## Purpose

Declares peer-processing APIs consumed outside `net_processing.cpp`, including Nu Fast Sync reservation entry points.

## Nu Divergence

- Exposes the small Fast Sync backend API used by `reservefastsyncblock` RPC:
  `ReserveFastSyncBlockInFlight`, `ReserveNextFastSyncBlockInFlight`,
  `ReleaseFastSyncBlockInFlight`, and `SetFastSyncPeerTransportVerified`.
- Carries Defcoin user-agent and LAN discovery filter helpers used by Nu peer display and connectivity logic.

## Do Not Break

- Keep this API narrow. Do not expose consensus or validation shortcuts to the frontend.
- Any added Fast Sync API must preserve Core ownership of block selection, in-flight tracking, and validation.
- If signatures change, update `rpc/net.cpp`, `NuRpcService.cpp`, Lion parity notes, and server build notes together.

## Verification

- `git diff --check`
- Build every target that includes `net_processing.h`, at minimum `src/defcoind`.
