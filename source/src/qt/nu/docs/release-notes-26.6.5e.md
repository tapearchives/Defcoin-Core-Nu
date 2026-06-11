# Defcoin Core Nu 26.6.5e Release Notes

26.6.5e is a Metrics Traffic chart clarity and Qt 6.11 compatibility pass after
26.6.5d.

## Changes

- Metrics Traffic simple mode remains focused on total received and total sent
  rates.
- Metrics Traffic Details mode now renders stacked traffic components for:
  `TCP`, `FS UDP` (Fast Sync UDP), and `QC UDP` (Quick Clone UDP).
- The chart hover text now shows component rates for TCP, Fast Sync UDP, and
  Quick Clone UDP.
- The Traffic footer now breaks out total received/sent volume by `TCP`,
  `FS UDP`, `QC UDP`, and total traffic.
- Quick Clone UDP remains counted as UDP traffic. The separate chart stack is a
  diagnostic breakout, not a new transport.
- The Tahoe Qt environment was checked against Qt 6.11.1. `QtCanvasPainter` and
  `QtTaskTree` are present locally but are not linked in this build.
- The macOS test launch gate now watches for a fresh `DefcoinCoreNu` `SIGABRT`
  DiagnosticReports file after launch. If one appears, it clicks the visible
  crash dialog's `Ignore` button, logs the report path, and stops before any
  Local Network/UDP test can be misread.

## Qt 6.11 Review Notes

- `QtCanvasPainter` was not adopted because Qt 6.11.1 documents it as
  Technology Preview and licenses it as Commercial/GPLv3. That is not an
  acceptable default production dependency for the MIT-derived Nu wallet line
  without an explicit licensing decision.
- `QtTaskTree` was not adopted in this pass because it is also Technology
  Preview and would require a broader rewrite of backend launch, RPC, and index
  orchestration.
- No 3D traffic graph was added. The stacked 2D chart presents TX/RX and
  TCP/UDP behavior more clearly and is much easier to keep in parity on Lion and
  Windows.

## Cross-Build Notes

- Lion received the same visual model in the legacy QtWidgets drawing stack:
  simple totals, then stacked TCP / Fast Sync UDP / Quick Clone UDP in Details
  mode.
- Windows was rebuilt from this source so the Metrics footer and hover labels
  match Tahoe. The available Windows cross-runtime is still Qt 6.10.1 MinGW;
  no Windows Qt 6.11.1 tree is installed in this workspace.
- Server builds are unaffected.

## Build Outputs

- Tahoe Apple Silicon app:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.5e-20260610/apple-silicon/Defcoin Core Nu.app`
- Tahoe Apple Silicon DMG:
  `/Volumes/TB5_4TB/d/litecoincore/Distribution_Versions/Defcoin Core Nu/Nu-26.6.5e-20260610/apple-silicon/Defcoin-Core-Nu-v26.6.5e-macOS-AppleSilicon.dmg`
- Windows setup and portable artifacts:
  `/Volumes/TB5_4TB/d/litecoincore/Tools/Defcoin Core Nu/Nu-26.6.5e-Windows-11-x86_64-20260610_083037`

## Verification

- `qmllint` on the touched QML files exited 0 with only the known local
  `Defcoin.Nu` import warning outside a built bundle.
- `qmlformat --check` is not supported by the installed Qt 6.11.1 `qmlformat`,
  so no broad formatting rewrite was run.
- Tahoe app and DMG staged successfully. The staged app verifies with
  `codesign --verify --deep --strict`, the embedded backend reports
  `v26.6.5e`, and the linked Qt frameworks report `6.11.1`.
- Windows setup EXE and portable ZIP were created. The portable ZIP passed
  `unzip -t`. The Windows frontend reports `26.6.5e`; the embedded Windows
  backend binaries remain inherited from the prior Windows backend build and
  report `v26.6.5a`.
- `bash -n` passed for `nu_test_launch_gate.sh` and the new visible-button
  clicker wrapper. The visible-button helper compiled and a no-dialog smoke test
  returned `context_not_found` without clicking.
