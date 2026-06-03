# Defcoin Core Nu 26.6.2c Release Notes

Defcoin Core Nu `26.6.2c` is an Explore usability and Droid Trails refinement
update over `26.6.2b`.

## Explore Status

- Explorer index status now reports green when the local explorer cache is
  complete, even if stale status text from an earlier failure remains available.

## Droid Trails

- Droid Trails cache schema is bumped to version 2 so the Coindroids analysis is
  rebuilt with the expanded row format.
- Matching Droid Trails cache rows are reused by schema version instead of being
  discarded whenever the Explorer index advances by a few blocks.
- DEF CON 23 and DEF CON 24 now have their own conference-era windows.
- DEF CON window labels now include the main venue, with DEF CON 28 marked as
  `DEF CON 28 Safe Mode [Virtual Event]`.
- Window rows now show block-derived date ranges.
- DFC display values are rounded for readability while exact satoshi values
  remain in row metadata.
- Summary metrics now include candidate DFC sent, active DEF CON windows,
  swarm DFC, and strongest candidate window.

## Explore UI

- Forensics no longer duplicates left-rail sections as mid-screen tabs.
- Movement Network graph layout now settles in bounded passes and keeps separate
  layout state for the inline graph and pop-out graph.
