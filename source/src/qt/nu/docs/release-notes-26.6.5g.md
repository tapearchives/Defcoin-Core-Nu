# Defcoin Core Nu 26.6.5g Release Notes

26.6.5g adds peer inspection and route-tracing usability work after 26.6.5f.

## Changes

- Metrics > Peers now supports double-clicking a peer row to open a grouped
  peer detail view. The view separates endpoint, LAN/source, Defcoin sync,
  service flags, Fast Sync state, traffic, timing, and possible same-node clues.
- The Peers action row now includes `Inspect Peer` and `Traceroute`. Inspect
  requires one selected peer; Traceroute can open one trace window per selected
  peer.
- Peer traceroute prefers Trippy's `trip` binary when installed or bundled,
  then falls back to the operating system traceroute command.
- Header TX/RX compact rates no longer use `~` for ordinary current traffic
  rates. The cap marker is now a `+` when the display limit is reached.
- Apple Silicon DMG staging no longer leaves the generated DMG background PNG
  beside the app and DMG in the distribution folder.
- Trippy is now listed in About and license/attribution notices. The Apple
  Silicon build bundles the `trip` binary and Apache-2.0 license asset; other
  platforms may bundle it through `DEFCOIN_NU_TRIPPY_BINARY` or use the system
  fallback.

## Cross-Build Notes

- Windows should use `trip.exe` when present, with `tracert` fallback.
- Lion can keep a simpler fallback if Trippy is not practical on 10.7, but the
  peer detail grouping and action affordances should match the Tahoe UI.
- If a cross-build bundles Trippy, set `DEFCOIN_NU_TRIPPY_BINARY` and include
  the Apache-2.0 license/notice materials in that package.

## Verification

- `git diff --check` passed.
- `bash -n src/qt/nu/app/stage_macos_distribution.sh` passed.
- `qmllint -I src/qt/nu/qml src/qt/nu/qml/Views/NodeView.qml` passed with
  only the expected out-of-bundle `Defcoin.Nu` import warning.
- `cmake --build build/nu-qml-arm64-26.6.5g --target DefcoinCoreNu -j 6`
  passed on Tahoe.
- `cmake --build build/nu-qml-arm64-26.6.5g --target DefcoinCoreNuResources
  -j 1` passed and the resulting app passed deep codesign verification.
- Apple Silicon staging completed and `hdiutil verify` reported a valid DMG
  checksum.
- The staged Apple Silicon distribution folder contains the app and DMG only
  besides Finder metadata; no generated DMG background PNG remains beside them.
- The staged Apple Silicon app includes `Contents/Resources/nu/bin/trip` and
  `Contents/Resources/nu/assets/licenses/trippy-Apache-2.0-LICENSE.txt`.
