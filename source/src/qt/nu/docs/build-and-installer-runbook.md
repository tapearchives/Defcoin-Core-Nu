# Defcoin Core Nu Build And Installer Runbook

Last updated: 2026-06-04

This runbook is public-safe. It intentionally avoids local workstation paths,
mounted volume names, user names, and machine-specific details.

For the canonical release overview, see:

```text
doc/defcoin-core-nu-technical-guide.md
```

## Path Variables

Use local variables instead of committing machine-specific paths:

```sh
REPO="$HOME/src/Defcoin-Core-Nu"
SRC="$REPO"
OUT="$REPO/Distribution_Versions"
QT_MAC="$HOME/Qt/6.11.1/macos"
QT_CATALINA="$HOME/Qt/6.2.4/macos"
QT_WIN="$HOME/Qt/6.10.1/mingw_64"
```

Finished deliverables should be staged outside source history:

```text
$OUT/Defcoin Core Nu/Nu-26.6.2i-20260602/apple-silicon/
$OUT/Defcoin Core Nu/Nu-26.6.2i-20260602/catalina-x86_64/
$OUT/Defcoin Core Nu/Nu-26.6.2i-20260602/windows11-x86_64/
```

## macOS Qt Quick App

Apple Silicon example:

```sh
cd "$SRC"
cmake -S src/qt/nu/app -B build/nu-qml-arm64 \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_PREFIX_PATH="$QT_MAC" \
  -DQt6_DIR="$QT_MAC/lib/cmake/Qt6" \
  -DDEFCOIN_NU_BACKEND_BINARY="$SRC/src/defcoind" \
  -DDEFCOIN_NU_CLI_BINARY="$SRC/src/defcoin-cli" \
  -DDEFCOIN_NU_TX_BINARY="$SRC/src/defcoin-tx" \
  -DDEFCOIN_NU_WALLET_BINARY="$SRC/src/defcoin-wallet" \
  -DDEFCOIN_NU_RELEASE_NAME="26.6.2i" \
  -DDEFCOIN_NU_ENABLE_HELP=OFF

cmake --build build/nu-qml-arm64 --target DefcoinCoreNuResources -- -j1
```

Use `x86_64` and a separate build directory for Intel macOS.
For Catalina compatibility, use `QT_CATALINA`, `-DCMAKE_OSX_ARCHITECTURES=x86_64`,
and `-DCMAKE_OSX_DEPLOYMENT_TARGET=10.15`.

The macOS build runs `macdeployqt`, then `repair_macos_qt_bundle.py`. The
repair pass is intentional: Homebrew's modular Qt layout can leave Qt Quick
frameworks unresolved even when `macdeployqt` exits successfully. The repair
pass copies any missing Qt frameworks into `Contents/Frameworks`, normalizes Qt
install names to the app bundle, prunes non-runtime framework headers/`.prl`
metadata, and fails the build if a Qt framework would still be missing.

Stage macOS bundles with the local staging helper:

```sh
src/qt/nu/app/stage_macos_distribution.sh \
  "$SRC/build/nu-qml-arm64/DefcoinCoreNu.app" \
  "$OUT/Defcoin Core Nu/Nu-26.6.2i-20260602/apple-silicon" \
  "26.6.2i" \
  "macOS-AppleSilicon"
```

## Explore App Boundary

Defcoin Core Explore is a separate application with its own distribution cycle
and its own build thread. It currently inherits Nu's visible build number, but a
Nu-only fix must not automatically copy Explore into a Nu distribution folder.

The CMake project still defines the Explore targets for the Explore build
thread, but they are excluded from the default Nu build. Build Explore only when
the Explore thread explicitly requests it:

```sh
cmake --build build/nu-qml-arm64 --target DefcoinCoreExploreResources -- -j1

src/qt/nu/app/stage_macos_distribution.sh \
  "$SRC/build/nu-qml-arm64/DefcoinCoreExplore.app" \
  "$OUT/Defcoin Core Explore/Explore-26.6.2i-20260602/apple-silicon" \
  "26.6.2i" \
  "macOS-AppleSilicon"
```

Mounted DMG smoke check:

```sh
MOUNT_DIR="$(mktemp -d /tmp/defcoin-explore-install-qa.XXXXXX)"
hdiutil attach -nobrowse -readonly -mountpoint "$MOUNT_DIR" \
  "$OUT/Defcoin Core Explore/Explore-26.6.2i-20260602/apple-silicon/Defcoin-Core-Nu-Explore-v26.6.2i-macOS-AppleSilicon.dmg"

"$MOUNT_DIR/Defcoin Core Nu Explore.app/Contents/MacOS/DefcoinCoreExplore" \
  --smoke-test \
  --route holders \
  --grab-screenshot /tmp/defcoin-explore-dmg-holders-smoke.png \
  --grab-delay-ms 3600

for tool in defcoind defcoin-cli defcoin-tx defcoin-wallet; do
  tool_path="$MOUNT_DIR/Defcoin Core Nu Explore.app/Contents/Resources/nu/bin/$tool"
  otool -L "$tool_path" | awk '/@executable_path\/..\/Frameworks/ {bad=1; print} END {exit bad ? 1 : 0}'
  "$tool_path" -version >/dev/null
done

hdiutil detach "$MOUNT_DIR"
```

Use a delayed grab for mounted images because Explore route bodies are loaded
asynchronously and read-only DMG startup can be slower than a local build tree.
The backend tool loop verifies that packaged tools under
`Contents/Resources/nu/bin` do not use the GUI-only
`@executable_path/../Frameworks` install-name form.

## Windows Cross-Compile

Build the backend from a clean source copy and use one build thread on
constrained hosts:

```sh
WIN_SRC="$REPO/build-src/windows-backend"
rm -rf "$WIN_SRC"
rsync -a --delete \
  --exclude '.git' \
  --exclude '/build/' \
  --exclude '*.o' \
  --exclude '*.a' \
  "$SRC/" "$WIN_SRC/"

cd "$WIN_SRC"
./autogen.sh
CONFIG_SITE="$SRC/depends/x86_64-w64-mingw32/share/config.site" \
  ./configure --prefix=/ --host=x86_64-w64-mingw32 --without-gui --enable-wallet \
  --with-sqlite=yes --with-miniupnpc --disable-zmq --disable-tests --disable-bench \
  --disable-shared --with-pic
make -j1 src/defcoind.exe src/defcoin-cli.exe src/defcoin-tx.exe src/defcoin-wallet.exe
```

Build the Windows Qt Quick shell:

```sh
cd "$SRC"
cmake -S src/qt/nu/app -B build/nu-qml-win64 \
  -DCMAKE_TOOLCHAIN_FILE="$SRC/depends/cmake/mingw-w64-x86_64.cmake" \
  -DDEFCOIN_NU_BACKEND_BINARY="$WIN_SRC/src/defcoind.exe" \
  -DDEFCOIN_NU_CLI_BINARY="$WIN_SRC/src/defcoin-cli.exe" \
  -DDEFCOIN_NU_TX_BINARY="$WIN_SRC/src/defcoin-tx.exe" \
  -DDEFCOIN_NU_WALLET_BINARY="$WIN_SRC/src/defcoin-wallet.exe" \
  -DDEFCOIN_NU_RELEASE_NAME="26.6.2i" \
  -DDEFCOIN_NU_ENABLE_HELP=OFF \
  -DQt6_DIR="$QT_WIN/lib/cmake/Qt6" \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build/nu-qml-win64 --target DefcoinCoreNuResources -j1
```

Before Velopack or ZIP packaging, stage the Windows payload from the completed
Qt build output and fail the build if any runtime piece is missing. The payload
must include all top-level `*.dll` files, `DefcoinCoreNu.exe`, `qt.conf`, and
the `nu`, `plugins`, `qml`, and `translations` directories. At minimum, verify:

```sh
for required in \
  DefcoinCoreNu.exe \
  Qt6Core.dll \
  Qt6Gui.dll \
  Qt6Network.dll \
  Qt6Qml.dll \
  Qt6Quick.dll \
  Qt6QuickControls2.dll \
  Qt6Widgets.dll \
  qt.conf \
  plugins/platforms/qwindows.dll \
  qml/QtQuick/qmldir \
  nu/bin/defcoind.exe \
  nu/bin/defcoin-cli.exe \
  nu/bin/defcoin-tx.exe \
  nu/bin/defcoin-wallet.exe; do
  test -e "$PAYLOAD/$required" || {
    echo "missing Windows payload file: $required" >&2
    exit 1
  }
done
```

When copying the Velopack output into the public distribution folder, keep only
the renamed user-facing setup and portable ZIP there. Leave generated
`org.defcoincore...` feed artifacts under `_velopack-update-feeds` so the
Windows share does not show duplicate installers.

Package installers with the NSIS script or platform release helper used by the
local build environment. Installers should launch `DefcoinCoreNu.exe --raise`
directly from the finish page.

## Release Hygiene

- Do not commit app bundles, installers, DMGs, ZIPs, or generated build trees.
- Do not commit private credentials, wallet files, RPC cookies, `.env` files,
  or workstation-specific paths.
- Keep the visible release version as `26.6.2i`.
- If a rebuild contains any source, UI, packaging, documentation, or behavior
  change, advance the visible release label with a letter suffix before staging
  it: `26.6.2j`, `26.6.2k`, and so on.
- Do not change the inherited `0.21.5.5` Core client version for suffix-only Nu
  rebuilds; that number tracks the Litecoin/Core base.
- Build IDs may include UTC timestamp, commit, and dirty/clean state, but
  should not expose local path or machine details.
