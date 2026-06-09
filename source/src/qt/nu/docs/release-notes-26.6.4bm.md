# Defcoin Core Nu 26.6.4bm

## Summary

This build improves Fast Sync status accounting so UDP-vs-Core/TCP performance can be interpreted without mixing unrelated traffic paths.

## Changes

- Split UDP Fast Sync node accounting into accepted block sources, attempted block sources, fully failed block sources, and peers served by this node.
- Changed the Metrics status text to show `UDP sources N/M ok, X failed, served Y`.
- Added current UDP probe datagram/chunk size to the Fast Sync UDP row.
- Stopped counting generic chain advancement as Core/TCP block success when the debug launch switch disables Core TCP block-body sync for isolated UDP testing.
- Shortened the sync summary wording so block percentages and protocol rates are easier to scan.
- Confirmed the Lion workstation-name Bonjour lookup must use the bounded `dns-sd -B` snapshot form from Tahoe; the older live pipe can leak helper processes and distort sync performance.

## Build Notes

- Tahoe visible version: `26.6.4bm`.
- Lion parity build should port the same source-accounting sets and status text into `legacy-osx107/main.cpp`.
- Lion parity build should also keep the bounded Bonjour SMB lookup form; do not use an unbounded `dns-sd -B ... | awk ... | while` pipe.
- Backend version must be rebuilt after the client version string changes so the bundled daemon reports `v26.6.4bm`.

## Test Focus

- Launch Tahoe and Lion current builds only, close prior Nu processes first, and click the Tahoe Local Network `Allow` prompt on the first run of the new app bundle.
- Delete only the Lion public chain folders when testing from a clean sync: `blocks`, `chainstate`, and `indexes`.
- Test Fast Sync with Core TCP block copy disabled first; the status should not accumulate TCP/Core block success while that debug switch is active.
- Confirm Metrics shows accepted UDP block sources and fully failed UDP block sources separately.
