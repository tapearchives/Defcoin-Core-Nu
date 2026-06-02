# Defcoin Core Nu 26.6.1e Release Notes

Defcoin Core Nu `26.6.1e` tightens Fast Sync capability reporting and improves
Diagnostics peer-service clarity.

## Fixed

- UDP Fast Sync candidates now require the `NODE_DEFCOIN_FASTSYNC` service bit
  (`1 << 29`). Nu-looking user agents without that bit are no longer counted as
  UDP fast-sync candidates or selected for UDP block requests.
- The headless Fast Sync server allowlist now follows the same rule, so legacy
  or transitional peers are not admitted by User-Agent text alone.
- Renamed the detailed Peers table `Svcs` header to `Services`.
- Added per-cell hover text for Services entries with the full service-bit names
  and meanings, including `NODE_NETWORK`, `NODE_WITNESS`,
  `NODE_NETWORK_LIMITED`, and `NODE_DEFCOIN_FASTSYNC`.
