# Defcoin Core Nu 26.6.4bc

## Summary
- Adds a bounded multi-source UDP Fast Sync requester cache.
- Keeps UDP as transport only: Core still reserves the block, validates it, and accepts it through the normal `submitblock` path.
- Updates Tahoe build label from `26.6.4bb` to `26.6.4bc`.

## Fast Sync Changes
- The requester can now keep up to four UDP block transfers active and up to sixteen completed blocks staged.
- Completed UDP blocks are submitted to Core only in chain order (`current height + 1`).
- Timeouts, checksum failures, and send failures release only the affected Core reservation instead of clearing all active UDP work.
- Peer selection strongly favors different Fast Sync sources while a host already has a local UDP request in flight.
- The responder remains stateless per request and should be able to serve multiple receivers at once.

## Cross-Build Notes
- Port the same `NuRpcService` Fast Sync requester state structs and helper methods to Lion/Catalina.
- Do not fork the protocol version for this change; packet format remains `defcoin-nu-udp-fast-sync-v1`.
- Keep the source-side `request-block` / `block-chunk` protocol unchanged so existing Tahoe, Lion, server, and Windows responders stay compatible.
