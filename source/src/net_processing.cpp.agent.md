# net_processing.cpp Agent Notes

## Purpose

Owns Core peer message processing, block scheduling, in-flight block accounting, and Nu's backend Fast Sync reservation hooks.

## Nu Divergence

- Adds UDP Fast Sync state to `CNodeState`: pending block hash/height, claim window, transfer deadline, UDP transport verification, and backoff.
- Adds `ReserveFastSyncBlockInFlight`, `ReserveNextFastSyncBlockInFlight`, `ReleaseFastSyncBlockInFlight`, and `SetFastSyncPeerTransportVerified` for the Nu frontend bridge.
- Offers a Core-selected UDP transport window before falling back to normal TCP `getdata` when the peer advertises bit 29 and has proven UDP return-path capability.
- Adds debug isolation switches for disabling Core TCP block-body requests while leaving peer negotiation and headers active.

## Do Not Break

- Fast Sync is only a transport choice. Blocks delivered over UDP must still be marked in flight, submitted to Core, and accepted or rejected by normal validation.
- Do not request the same block twice from the same logical peer just because TCP and UDP are both available.
- Do not trust `NODE_DEFCOIN_FASTSYNC` alone; `fFastSyncUdpTransportVerified` must be true before reservation.
- Keep timeouts/backoff conservative enough that normal TCP sync can make progress if UDP is not claimed or delivery fails.
- Keep `mapBlocksInFlight`, `MarkBlockAsInFlight`, and `MarkBlockAsReceived` ownership semantics intact.

## Cross-Build Notes

- Tahoe and Lion must share the same reservation reasons where possible because the QML status text and debug logs compare them across machines.
- Windows/server builds need the same service-bit and reservation behavior even if Quick Clone UI is absent.

## Verification

- `git diff --check`
- Build `src/defcoind` after behavior changes.
- Test at least one normal TCP sync path and one UDP reservation path with the macOS LAN permission gate satisfied before interpreting UDP results.
