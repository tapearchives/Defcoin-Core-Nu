# Defcoin Core Nu 26.6.4ca

Internal Tahoe/Lion parity build.

## Changes
- Brought Lion Metrics and Peers UI closer to Tahoe parity:
  - `Metrics > Status` now has a compact `Details` switch.
  - `Metrics > Peers` uses the same compact `Details` switch instead of the
    older Simple/Detailed combo box.
- Cleaned the simple Status view so it shows the high-value sync rows first:
  `Syncing`, `Sync overview`, `Sync benchmark`, `Core Sync (TCP)`,
  `Fast Sync (UDP)`, `Quick Clone (LAN UDP)`, traffic, network, block, header,
  and verification state.
- Split Fast Sync UDP reporting into:
  - a concise simple row showing UDP block share, average data rate, recent
    block rate, successful/attempted/failed peer counts, bytes, and failures;
  - a details-only counter row for packet/probe/checksum/timeout diagnostics.
- Rebuilt Tahoe backend release identity to `v26.6.4ca` so the frontend and
  bundled backend no longer disagree.
- Updated the physical Lion stop helper to point at the current `26.6.4ca`
  staged app by default.
- Patched Lion workstation probing to stop leaked `dns-sd`/`awk` helpers after
  Bonjour probe completion or timeout. The prior leak could exhaust the Lion
  process table and make SSH return `fork: Resource temporarily unavailable`.

## Verification Notes
- Tahoe Apple Silicon app staged at:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.4ca-20260609/apple-silicon/Defcoin Core Nu.app`
- Tahoe DMG staged at:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.4ca-20260609/apple-silicon/Defcoin-Core-Nu-v26.6.4ca-macOS-AppleSilicon.dmg`
- Tahoe staged bundle reports frontend `26.6.4ca`, backend
  `Defcoin Core Nu version v26.6.4ca`, QML is present, code signing verifies,
  and `hdiutil verify` reports a valid DMG checksum.
- Build warnings observed during backend rebuild are existing toolchain noise
  from Boost/thread-safety annotations and `-fstack-clash-protection` on clang;
  no new source error was introduced by the status/UI changes.

## Follow-Up
- Lion backend staging used a single-recursive CLI rebuild after the initial
  two-target Automake invocation exposed a shared-object race. Future Lion
  backend work should prefer `make -C src -j2 defcoind defcoin-cli` or build
  one binary at a time.
- Lion staged app now reports frontend `26.6.4ca-Lion-alpha`, backend
  `v26.6.4ca-Lion-alpha-433385a-dirty`, and CLI
  `v26.6.4ca-Lion-alpha-433385a-dirty`. The staged app signs cleanly and the
  replaced backend binaries no longer reference `/opt/local` or `/usr/local`
  install names.
