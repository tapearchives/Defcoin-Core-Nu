# Defcoin Core Nu 26.6.4ap Internal Notes

This build tightens the UDP-only Fast Sync test path used while comparing Tahoe
and Lion behavior.

## Changes

- Keeps `--debug-disable-core-tcp-sync` / `DEFCOIN_NU_DEBUG_DISABLE_CORE_TCP_SYNC=1`
  as the launch switch for disabling Core TCP block-body fetches while leaving
  peer negotiation, header sync, and service-bit discovery active.
- In that test mode, the Fast Sync selector now forces UDP quota when eligible
  Fast Sync peers are visible instead of reusing stale TCP/UDP allocation state.
- Adds throttled diagnostics when UDP target selection returns no host, including
  peer, verified, used, failed, and debug-mode counts.
- Keeps the old `--debug-disable-core-sync` alias mapped to the same
  TCP-block-only behavior. Fully disabling Core sync remains a Quick Clone/DCOL
  test case only.

## Cross-Build Notes

- Tahoe and Lion must both carry this selector rule. If Lion sees a Tahoe peer
  with service bit 29 but does not send a UDP probe, inspect the new
  `UDP target selection empty` diagnostic before changing backend scheduling.
- Do not let this mode disable Core peer/header negotiation. Fast Sync is still
  a transport choice around Core-selected peer/block state.
