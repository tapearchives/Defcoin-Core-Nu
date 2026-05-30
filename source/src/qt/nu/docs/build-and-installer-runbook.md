# Defcoin Core Nu Build And Installer Runbook

Last updated: 2026-05-29

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
QT_MAC="$HOME/Qt/6.10.1/macos"
QT_WIN="$HOME/Qt/6.10.1/mingw_64"
```

Finished deliverables should be staged outside source history:

```text
$OUT/Nu-26.5.5b/apple-silicon/
$OUT/Nu-26.5.5b/mac-intel/
$OUT/Nu-26.5.5b/windows11-x86_64/
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
  -DDEFCOIN_NU_RELEASE_NAME="26.5.5b" \
  -DDEFCOIN_NU_ENABLE_HELP=OFF

cmake --build build/nu-qml-arm64 --target DefcoinCoreNuResources -- -j1
```

Use `x86_64` and a separate build directory for Intel macOS.

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
  "$OUT/Nu-26.5.5b/apple-silicon" \
  "26.5.5b" \
  "macOS-AppleSilicon"
```

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
  -DDEFCOIN_NU_RELEASE_NAME="26.5.5b" \
  -DDEFCOIN_NU_ENABLE_HELP=OFF \
  -DQt6_DIR="$QT_WIN/lib/cmake/Qt6" \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build/nu-qml-win64 --target DefcoinCoreNuResources -j1
```

Package installers with the NSIS script or platform release helper used by the
local build environment. Installers should launch `DefcoinCoreNu.exe --raise`
directly from the finish page.

## Release Hygiene

- Do not commit app bundles, installers, DMGs, ZIPs, or generated build trees.
- Do not commit private credentials, wallet files, RPC cookies, `.env` files,
  or workstation-specific paths.
- Keep the visible release version as `26.5.5b`.
- If a rebuild contains any source, UI, packaging, documentation, or behavior
  change, advance the visible release label with a letter suffix before staging
  it: `26.5.5a`, `26.5.5b`, `26.5.5c`, and so on.
- Do not change the inherited `0.21.5.5` Core client version for suffix-only Nu
  rebuilds; that number tracks the Litecoin/Core base.
- Build IDs may include UTC timestamp, commit, and dirty/clean state, but
  should not expose local path or machine details.
