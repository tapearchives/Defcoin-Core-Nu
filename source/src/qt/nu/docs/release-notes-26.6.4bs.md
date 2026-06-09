# Defcoin Core Nu 26.6.4bs

## Fast Sync Benchmarking

- Added `--debug-fast-sync-lan-only` for controlled LAN UDP Fast Sync tests.
- Intended UDP-only LAN benchmark launch:
  `--debug-disable-core-tcp-sync --debug-disable-quick-clone --debug-fast-sync-lan-only`.
- The new flag keeps normal Core peer/header negotiation available, but the
  frontend will not choose public/server Fast Sync UDP candidates while the test
  is active.

## Sync Timing

- Added a `Sync benchmark` row to Metrics > Status.
- Nu now writes unique benchmark markers to backend `debug.log`:
  `NU_SYNC_BENCHMARK_START` and `NU_SYNC_BENCHMARK_COMPLETE`.
- The completion line includes elapsed `HH:MM:SS`, block range, UDP/Core block
  counts, byte totals, UDP failures, and UDP source counts.

## Notes

- Normal launches are unchanged.
- This is still validation-preserving Fast Sync. It does not bypass Core
  validation and is not Quick Clone/DCOL.
