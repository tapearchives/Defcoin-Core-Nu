# Defcoin Core Nu 26.6.4bn Release Notes

## Fast Sync
- Improves UDP Fast Sync pacing for verified LAN peers and UDP-only test runs.
- Keeps Fast Sync as a transport-only feature: Core still reserves blocks and
  validates every delivered block through `submitblock`.
- Lets UDP reserve the next not-yet-pending LAN block while earlier UDP blocks
  are being validated, instead of idling during each validation step.
- Adds clearer UDP source counts in Metrics: attempted, successful, failed, and
  served block-source hosts.

## Testing Notes
- Clean Tahoe-to-Lion testing with current builds and Tahoe Local Network access
  allowed proved that Lion can accept UDP Fast Sync blocks while Core TCP
  block-body fetching is disabled.
- If UDP still looks slow, compare the UDP byte rate with the accepted-block
  rate. On older Lion hardware, Core validation can dominate the apparent block
  transfer rate even when UDP packet delivery is working.

## Cross-Build Notes
- Port the same Fast Sync pacing change to Lion's
  `src/qt/nu/legacy-osx107/main.cpp`.
- Use `--debug-disable-core-tcp-sync --debug-disable-quick-clone` for isolated
  UDP Fast Sync tests.
