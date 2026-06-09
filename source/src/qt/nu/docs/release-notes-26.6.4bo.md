# Defcoin Core Nu 26.6.4bo Release Notes

## Metrics And Peers UI Polish

- Replaced the Peers `Simple | Detailed` segmented control with a compact
  `Details` switch.
- Added the same `Details` switch to `Metrics > Status`.
- The default Status view now shows the highest-value operational rows:
  sync progress, sync overview, Core Sync TCP, Fast Sync UDP, Quick Clone,
  traffic, network state, connections, blocks, headers, and verification.
- The detailed Status view adds lower-frequency rows: Fast Sync selector and
  probe internals, Quick Clone validation/sources, backend version, difficulty,
  hashrate, block time, chain tips, P2P message breakdowns, backend path,
  data directory, debug log, RPC endpoint, and launch defaults.
- Status `Syncing` no longer repeats the full TCP/UDP transport summary; that
  information now stays in the dedicated sync rows where it is easier to scan.

## Lion Metrics Performance

- The Lion Qt 5.5 Metrics page now refreshes only the currently visible tab.
  Opening Metrics no longer preloads the Status table, launch log, Peers table,
  banned peer table, and row/column auto-fit work all at once.
- Lion Status table updates now use a content signature and skip rebuilding
  when the visible rows have not changed.
- Lion Status and Peers use the same compact `Details` control and row grouping
  as Tahoe.

## Cross-Build Notes

- Tahoe QML rows use a `meta.detail` flag for filtering.
- Lion uses an equivalent in-function `StatusRow` detail flag and filters
  before writing the `QTableWidget`.
- Keep the default Status view non-detailed on all platforms; the detailed rows
  are still available without making the main status page noisy.
