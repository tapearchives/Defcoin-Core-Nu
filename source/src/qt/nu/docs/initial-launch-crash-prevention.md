# Initial Launch Crash Prevention

Last updated: 2026-06-02

This note tracks the recurring “build opens, splash appears, then the app exits”
failure mode. The goal is to make every new Nu or Explore package pass the same
launch gates before it is handed off.

## Confirmed Recent Causes

### Mixed Qt Frameworks

Symptom:

- The app starts, loads enough code to show a splash or menu-bar identity, then
  exits or records a Qt framework/plugin crash.
- `otool -L` shows app-bundled Qt frameworks mixed with absolute Homebrew Qt
  paths.

Cause:

- `macdeployqt` can exit successfully while leaving some Qt Quick framework
  install names pointed at the local build machine. At runtime, macOS may load a
  mix of bundled Qt and Homebrew Qt, which is not stable.

Fix:

- Always run `repair_macos_qt_bundle.py` after `macdeployqt`.
- Treat unresolved Homebrew Qt references in the final app as a release blocker.
- Confirm with:

```sh
otool -L "$APP/Contents/MacOS/DefcoinCoreNu" | grep -E "Qt|homebrew|opt"
find "$APP/Contents" -type f \( -name "*.dylib" -o -perm +111 \) -print0 \
  | xargs -0 otool -L 2>/dev/null | grep -E "/opt/homebrew|/usr/local/opt"
```

The final staged app should use bundled `@rpath` Qt frameworks, not local Qt
install paths.

### Missing Qt Platform Or Runtime Plugins

Symptom:

- The app exits immediately on launch.
- Terminal launch reports missing `libqcocoa.dylib`, image plugins, SQL plugin,
  TLS plugin, or QML imports.

Cause:

- The app bundle contains frameworks but not the focused runtime plugin set. A
  Qt Quick app can compile and link successfully while still being unable to
  create its first window at runtime.

Fix:

- The `DefcoinCoreNuResources` build target and staging helper must copy and
  validate:
  - `Contents/PlugIns/platforms/libqcocoa.dylib`
  - `Contents/PlugIns/sqldrivers/libqsqlite.dylib`
  - needed image, icon, TLS, style, and QML plugins
  - `Contents/Resources/qml/QtQuick`, `QtQml`, `QtQuick/Controls`,
    `QtQuick/Layouts`, and `QtQuick/Templates`
- Treat a missing `libqcocoa.dylib` as an automatic failed build.

### Bundle Identity Or Executable Name Drift

Symptom:

- macOS opens an old app, opens nothing, shows a saved-window restore prompt for
  the wrong product, or launches a bundle whose process name does not match the
  package name.

Cause:

- Recent Nu/Explore split work changed visible names, bundle identifiers,
  executable names, and DMG names. A partially renamed bundle can still build
  but fail at launch or relaunch the wrong binary.

Fix:

- Validate `Info.plist` before staging:

```sh
plutil -p "$APP/Contents/Info.plist" | grep -E \
  "CFBundleExecutable|CFBundleIdentifier|CFBundleName|CFBundleDisplayName|CFBundleShortVersionString"
test -x "$APP/Contents/MacOS/DefcoinCoreNu"
```

- Nu should use the Nu executable and bundle identifier.
- Explore should use the Explore executable and bundle identifier.
- Do not reuse a staged app folder across product renames; stage into a clean
  destination.

### Saved Window Restoration

Symptom:

- macOS asks whether to reopen windows after the previous app quit
  unexpectedly.

Cause:

- The app died during a prior launch and macOS attempts state restoration on the
  next launch. This is not usually the root crash, but it hides the real problem
  behind a confusing prompt.

Fix:

- Keep `set_macos_launch_plist.sh` in the build path.
- Ensure the app disables saved no-window restoration for Nu and Explore.
- Launch the app fresh after a crash test rather than trusting the restored
  state.

### Dirty Source Tree With Cross-App Split Changes

Symptom:

- A build that worked minutes earlier starts crashing after a small unrelated
  change.
- Nu contains Explore-only QML or C++ paths, or Explore lacks copied Nu
  components.

Cause:

- Nu and Explore currently share `NuRpcService`, QML components, and packaging
  scripts. During the split, a dirty tree can include unrelated staged or
  unstaged changes that affect the app being packaged.

Fix:

- Before building a release candidate, run:

```sh
git status --short
git diff --cached --stat
git diff --stat
```

- If unrelated split work is present, either build from a clean worktree or
  explicitly document that the package was built from a dirty mixed tree.
- Prefer a clean staging folder for every suffix build.

### Stale Backend Or Duplicate App Instance

Symptom:

- The new frontend launches but talks to an older backend.
- RPC shows a different subversion or different service bits than expected.
- Wallet/database locks, delayed launch, or misleading sync state appear.

Cause:

- A previous `DefcoinCoreNu.app` or bundled `defcoind` is still running.

Fix:

- Stop any previous test instance before launch smoke tests:

```sh
pgrep -fl "DefcoinCoreNu|DefcoinCoreExplore|defcoind"
defcoin-cli -rpcconnect=127.0.0.1 -rpcport=9332 stop
```

- If RPC stop succeeds but the GUI stays open, close the frontend before opening
  the new staged build.
- After launch, verify the running process path points to the staged build being
  tested.

## First-Launch Gate

Every staged `.app` should pass these checks before making a DMG:

```sh
APP="$OUT/Defcoin Core Nu.app"

test -x "$APP/Contents/MacOS/DefcoinCoreNu"
test -f "$APP/Contents/PlugIns/platforms/libqcocoa.dylib"
test -f "$APP/Contents/PlugIns/sqldrivers/libqsqlite.dylib"
test -d "$APP/Contents/Resources/qml/QtQuick"
test -d "$APP/Contents/Resources/nu/bin"

codesign --verify --deep --strict "$APP"
spctl --assess --type execute "$APP" || true

find "$APP/Contents" -type f \( -name "*.dylib" -o -perm +111 \) -print0 \
  | xargs -0 otool -L 2>/dev/null | grep -E "/opt/homebrew|/usr/local/opt" \
  && echo "FAIL: local Homebrew dependency leaked into app"
```

Then perform a real launch check:

```sh
open "$APP"
sleep 12
pgrep -fl "$APP/Contents/MacOS/DefcoinCoreNu|$APP/Contents/Resources/nu/bin/defcoind"
```

If the app supports a smoke-test mode, prefer that for automation, but still do
one normal Finder-style `open` before handoff because macOS bundle metadata and
state restoration issues only show up in normal app launch.

## Crash Triage Order

When an initial build crashes, diagnose in this order:

1. Confirm the running app path is the new staged bundle.
2. Check the newest `.crash` file in `~/Library/Logs/DiagnosticReports`.
3. Launch the binary directly from Terminal to capture Qt loader errors.
4. Check `otool -L` for local Qt/Homebrew dependency leaks.
5. Check for missing `Contents/PlugIns/platforms/libqcocoa.dylib`.
6. Check `Info.plist` executable and bundle identifiers.
7. Check whether an older `defcoind` is already running.
8. Check QML import errors and missing resource paths.

Do not treat a DMG checksum or successful code signature as sufficient proof.
They prove packaging integrity, not runtime viability.

## Current Prevention Rules

- Use a fresh build directory per suffix when the packaging scripts changed.
- Use a fresh staging destination per suffix.
- Run `DefcoinCoreNuResources`, not only the app target.
- Stage with `stage_macos_distribution.sh`; do not hand-copy `.app` bundles.
- Do not skip the Qt repair/verification pass.
- Do not hand off a build that has not been opened once from the staged app path.
- Keep Nu and Explore build outputs separate; do not stage one product into the
  other product's folder.
- Preserve the inherited Core client version unless the user explicitly asks to
  change it; use Nu suffixes for UI/package rebuilds.
