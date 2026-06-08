# Defcoin Core Nu 26.6.4aq

## Summary

This is a test-harness and Fast Sync diagnostics build. It separates the
debug launch switch that disables Core TCP block-body downloads from the
stronger switch that disables Core P2P sync entirely.

## Tahoe

- `--debug-disable-core-tcp-sync` now sets only
  `DEFCOIN_NU_DEBUG_DISABLE_CORE_TCP_SYNC=1`.
- `--debug-disable-core-sync` now sets only
  `DEFCOIN_NU_DEBUG_DISABLE_CORE_SYNC=1`.
- The frontend passes `-defcoindisablecoretcpblocks=1` when either switch is
  active, but only the stronger Core Sync switch turns backend P2P networking
  off with `-networkactive=0`.
- The UDP selector uses the TCP-disabled state to force UDP probes and block
  requests during Fast Sync tests.

## Lion / Catalina Port Notes

- Apply the same switch split. `--debug-disable-core-tcp-sync` must keep peer
  discovery, headers, service-bit negotiation, and Core reservation RPCs alive.
- Reserve `--debug-disable-core-sync` for Quick Clone isolation tests where
  normal Core P2P networking should be disabled.
- When testing UDP Fast Sync, launch with Core TCP block copy disabled and
  Quick Clone disabled, not full Core Sync disabled.

## Test Target

- Launch Tahoe and Lion with:
  `--debug-disable-core-tcp-sync --debug-disable-quick-clone`
- Confirm the backend args include `-defcoindisablecoretcpblocks=1` and
  `-networkactive=1`.
- Confirm service-bit negotiation still sees `DEFCOIN_FASTSYNC`.
- Confirm the frontend sends UDP probes, receives probe acknowledgements,
  reserves blocks through Core, and submits UDP-delivered blocks through Core
  acceptance.
