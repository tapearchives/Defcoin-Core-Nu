# Defcoin Core Nu 26.6.1a Release Notes

Defcoin Core Nu `26.6.1a` is a small Tahoe UI and LAN-identification polish
build over `26.6.1`. The inherited Core client build number is unchanged.

## Changes

- LAN peer workstation names now prefer readable Macintosh share names and avoid
  redundant Bonjour/SMB/NetBIOS duplicates.
- Combo boxes now open from clicks anywhere in the visible text field, including
  the Home wallet selector, Send address book selector, and Mining pool selector.
- The macOS DMG background label backplates were adjusted to align under Finder
  icon labels on the dark purple installer background.

## Notes

- `-dbcache` remains a Core backend cache for block validation and chainstate
  work. It can improve initial sync and validation-heavy work, but Explorer and
  Explore SQLite indexing use their own SQLite caches and batching.
