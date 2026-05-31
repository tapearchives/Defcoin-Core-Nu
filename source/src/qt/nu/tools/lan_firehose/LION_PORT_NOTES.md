# LAN Firehose Throughput Test - Lion Port Notes

The Qt wrapper is intentionally simple so the Lion builder can port it without
touching Nu wallet code. It is a standalone Qt Widgets app that launches the
Python CLI tester from `Contents/Resources/lan_firehose/LAN_Firehose_Throughput_Test.py`.

## Frontend Surface

- Main file: `LanFirehoseQt.cpp`
- UI stack: Qt Widgets plus Qt Network for lightweight beacon discovery
  (`QMainWindow`, `QPushButton`, `QTableWidget`, `QPlainTextEdit`,
  `QUdpSocket`, custom `QWidget::paintEvent` chart).
- No QML, Qt Quick, Qt Charts, OpenGL, or wallet RPC is required.
- The app is safe to run beside Nu because it only opens its own TCP/UDP test
  sockets and writes local CSV/JSONL result files.
- The wrapper advertises an idle beacon and listens on UDP control port 10347 so
  one open tester can start the other visible testers in Catch mode. Keep this
  in Qt Network for the Lion port; the Python CLI remains the actual traffic
  generator/receiver.

## Likely Qt 5.5 / 5.6 Adjustments

- Build this wrapper as its own app target if the full Nu Qt 6 target is too
  modern for Lion. The wrapper only needs `Core`, `Gui`, and `Widgets`.
- Use a C++11 compiler setting for Lion if C++17 is not available. The wrapper
  code avoids Nu-only C++17 dependencies.
- `QHeaderView::setSectionResizeMode` exists in Qt 5, but if the exact Lion Qt
  package complains, replace it with the older resize-mode spelling used by that
  Qt build.
- Keep the manual newline split in `readProcessOutput`; do not use
  `Qt::SkipEmptyParts`, which is newer than some Qt 5.5-era enum locations.
- `QStandardPaths::AppDataLocation` is used for result files. If the Lion Qt
  build lacks it, switch to `QStandardPaths::DataLocation` or a folder beside
  the app bundle.
- Lion usually does not ship Python 3. Either bundle a compatible Python 3
  runtime, add a small preferences field for the Python executable path, or
  point the wrapper at the Python 3 used by the Lion builder environment.
- Use the matching Lion-era `macdeployqt`; do not use hardened-runtime signing
  expectations from modern macOS for the Lion app.

## Port Checklist

- Confirm the window opens and the smoke-test argument exits cleanly.
- Confirm Beacon starts without a peer.
- Confirm Hose and Sink modes can discover one another on the LAN.
- Confirm the visible labels are Auto Pair, Spray, and Catch even though the CLI
  compatibility values remain `auto`, `hose`, and `sink`.
- Confirm idle wrapper windows advertise their workstation names.
- Confirm Auto Pair from one machine starts visible idle machines in Catch mode.
- Confirm the one-to-one peer picker appears only when `Manual pick one tester`
  is enabled.
- Confirm Auto mode does not stall if only one machine sees the other's beacon;
  one side should promote from sink to hose after the quiet-sink grace period.
- Run one 120-second test and verify TCP/UDP rows appear in both the table and
  chart.
- Save a CSV, JSONL, and `.log` result file and verify the `.log` opens in a
  built-in OS text/log viewer.
