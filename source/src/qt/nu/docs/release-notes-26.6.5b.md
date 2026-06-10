# Defcoin Core Nu 26.6.5b Release Notes

26.6.5b is a Windows launch and menu-stability fix after 26.6.5a.

## Changes

- Added a per-launch GUI startup log at `nu-gui-launch.log` in the Defcoin data
  directory. It records startup phases, elapsed time, and QML warnings so a slow
  or failed Windows launch has a concrete trace.
- Added startup splash phase text with elapsed seconds while Nu prepares the
  service, platform integration, and Qt Quick interface.
- Stopped the wallet app from opening the separated Explorer SQLite cache during
  Nu startup. Explorer/Forensics now remain in the separate Explore app, and Nu
  no longer touches the large `nu-explorer/explorer.sqlite` just to launch.
- Removed heavyweight `NuService.refresh()` calls from menu-open handlers so a
  File/Open Wallet menu click cannot trigger backend startup/RPC refresh work on
  the UI thread.
- Disabled the extra per-menu-item `Shortcut` helper on Windows. Menu selection
  remains active, while Windows avoids a Qt 6.10 menu/shortcut crash path seen
  in the 26.6.5a package.

## Cross-Build Notes

- Port `main.cpp`, `NuRpcService.cpp`, `Main.qml`, and `NuMenuItem.qml` to
  Windows/Catalina/Lion builds that carry the same Qt Quick wallet frontend.
- The Explore app still loads Explorer recent lookups and contact sets; only the
  main wallet app skips that startup work.
- Windows packages should include the new code using the installed Qt 6.10.1
  MinGW runtime unless the Windows Qt toolchain is explicitly upgraded.

## Verification

- `git diff --check` passed.
- `qmllint` was run against `Main.qml` and `NuMenuItem.qml`; it completed with
  only the existing context-property/import warnings.
- `clang-format --dry-run --Werror` passed for the changed C++ files after
  formatting.
- A native Apple Silicon syntax build of `DefcoinCoreNu` completed.
- Windows Qt 6.10.1 MinGW frontend build completed for `DefcoinCoreNuResources`.
- Windows payload validation found the required Qt runtime files, QML imports,
  `qwindows.dll`, `qt.conf`, and backend tools.
- Windows portable ZIP validation completed with no compressed-data errors.
- Windows installer was rebuilt with NSIS and identified as a Windows Nullsoft
  installer.
- Windows PE import audit found no missing non-system DLLs after removing unused
  optional SQL/platform plugins and adding the Qt QML helper DLLs required by
  the deployed QML modules.

## Packaging Note

The 26.6.5b Windows frontend is rebuilt from this source. The bundled backend
executables are staged from the prior Windows backend build because the current
backend depends rebuild still fails when run from the `Defcoin Core Nu` path with
spaces. Move the Windows backend build to a no-space path before the next backend
protocol change so the backend and frontend labels can be rebuilt together.
