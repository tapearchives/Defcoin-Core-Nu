# Defcoin Core Nu 26.6.4ba Release Notes

## Fast Sync

- Fixed a Fast Sync reservation blocker where UDP probing succeeded but Core
  refused to reserve early blocks from a peer whose best-known-block pointer had
  not populated yet.
- Verified Fast Sync peers can now reserve locally known early headers using
  the peer's advertised starting height as a conservative fallback.
- UDP still remains transport only. Received blocks are submitted through normal
  Core validation and consensus checks.

## Cross-Build

- Tahoe build label: `26.6.4ba`.
- Lion compatibility build label: `26.6.4ba-Lion-alpha`.
- Lion, Catalina, Windows, and server builds should carry the same
  `src/net_processing.cpp` reservation fallback before Fast Sync testing.
