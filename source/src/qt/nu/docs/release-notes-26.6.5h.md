# Defcoin Core Nu 26.6.5h Release Notes

26.6.5h completes the peer grouping and embedded traceroute cleanup after
26.6.5g.

## Changes

- Metrics > Peers now shows same-node groups directly in the Node column as a
  compact suffix such as `5 (g1)`. The suffix appears only when at least two
  current peer rows appear to be the same running Nu node.
- Hover text explains the `(gN)` suffix. Peer actions still use Core's real
  numeric peer id internally.
- Peer inspection shows `node_unique_id` when a current Nu peer has advertised
  it through LAN discovery or UDP Fast Sync negotiation.
- Fast Sync and Quick Clone now treat multiple known paths from the same Nu
  install, such as IPv4 and IPv6 rows with the same `node_unique_id`, as one
  logical in-flight source. The alternate path remains available after a
  failure or cooldown.
- Trippy runs in embedded unprivileged stream mode, avoiding the raw-socket
  privilege error and keeping route output inside the Nu trace window.
- The CMake Trippy bundling hook is now Windows-safe and no longer invokes
  `/bin/chmod` on Windows builds.
- Windows cross-builds now resolve qrencode from the target Windows toolchain
  instead of silently linking against the macOS Homebrew host library.
- Windows cross-builds no longer auto-bundle the host `trip` binary as
  `trip.exe`; Nu falls back to Windows `tracert` unless a real Windows Trippy
  binary is provided.

## Cross-Build Notes

- Lion should match the `(gN)` display semantics and keep Core numeric ids in
  table metadata.
- Windows should bundle `trip.exe` when available and fall back to `tracert`.
- Windows builders must pass or auto-detect a target-platform qrencode prefix;
  host `/opt/homebrew` qrencode is rejected for Windows builds.
- Server Fast Sync parity should exchange `node_unique_id` during negotiation,
  not inside every block or chunk packet.

## Verification

- `git diff --check` passed on the touched Tahoe source/docs.
- `qmllint -I src/qt/nu/qml src/qt/nu/qml/Views/NodeView.qml` passed with
  the expected local `Defcoin.Nu` import warning.
- Built `build/nu-qml-arm64-26.6.5h/DefcoinCoreNu.app`.
- Staged and verified
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.5h-20260611/apple-silicon/Defcoin-Core-Nu-v26.6.5h-macOS-AppleSilicon.dmg`.
- Confirmed bundled `trip 0.13.0`, valid codesign verification, and no
  sidecar DMG background PNG in the distribution folder.
- `DefcoinCoreNu --smoke-test` exited cleanly after loading the Qt Quick
  interface.
- Built the Windows 11 x86_64 package from the same Tahoe source and fresh
  Windows backend binaries. Staged it at
  `/Volumes/TB5_4TB/d/litecoincore/Tools/Defcoin Core Nu/Nu-26.6.5h-Windows-11-x86_64-20260611_031651`.
- Verified the Windows Tools folder contains one setup EXE and one portable ZIP,
  required Qt/runtime/backend files are present, and no invalid `trip.exe` is
  shipped.
- Updated the live dc903 Fast Sync sidecar. It now persists
  `/var/lib/defcoin-fast-syncd/node_unique_id` and includes that id in
  `probe-ack`; loopback verification on the server returned
  `node_unique_id=7b9e296ef7614028ac1bfc87ded46492`.
