# Defcoin Core Nu 26.6.4bt Release Notes

## LAN UDP Fast Sync Benchmark Evidence

- Added explicit `debug.log` markers for UDP Fast Sync block transport:
  - `NU_UDP_FASTSYNC_REQUEST`
  - `NU_UDP_FASTSYNC_SERVE`
  - `NU_UDP_FASTSYNC_STAGED`
  - `NU_UDP_FASTSYNC_ACCEPTED`
  - `NU_UDP_FASTSYNC_SUBMITTED`
  - `NU_UDP_FASTSYNC_DUPLICATE`
- These markers are intended for isolated benchmark runs launched with:
  `--debug-disable-core-tcp-sync --debug-disable-quick-clone --debug-fast-sync-lan-only`.
- The markers make it possible to prove whether accepted blocks came through
  UDP Fast Sync instead of inferring that from header/block progress alone.

## Compatibility

- No packet format changes.
- No consensus or validation changes.
- Normal non-debug launches are unchanged except for the additional debug-log
  lines if UDP Fast Sync is actively used.
