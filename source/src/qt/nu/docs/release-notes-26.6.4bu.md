# Defcoin Core Nu 26.6.4bu Release Notes

## LAN UDP Fast Sync Benchmark Fix

- Fixed the UDP Fast Sync reservation helper so clean bootstrap runs can reserve
  ahead within Core's known header window instead of waiting on only the next
  active block height.
- Increased the UDP receiver cache for benchmark runs so out-of-order blocks can
  be staged while Core validates earlier blocks in order.
- Shortened the Quick Clone/Core reservation retry status backoff so debug
  status updates no longer look stuck for 30 seconds at a time.
- This remains a transport-only Fast Sync path: Core still selects/reserves
  block work and `submitblock` still validates received blocks.

## Benchmark Markers

- Keeps the `26.6.4bt` debug markers:
  `NU_UDP_FASTSYNC_REQUEST`, `NU_UDP_FASTSYNC_SERVE`,
  `NU_UDP_FASTSYNC_STAGED`, `NU_UDP_FASTSYNC_ACCEPTED`,
  `NU_UDP_FASTSYNC_SUBMITTED`, `NU_UDP_FASTSYNC_DUPLICATE`, and
  `NU_SYNC_BENCHMARK_COMPLETE`.

## Compatibility

- No packet format changes.
- No consensus changes.
- Older peers that do not advertise Defcoin Fast Sync are not used for UDP block
  requests.
