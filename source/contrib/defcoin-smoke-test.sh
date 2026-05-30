#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

DEFCOIND="$ROOT_DIR/src/defcoind"
DEFCOIN_CLI="$ROOT_DIR/src/defcoin-cli"
DEFCOIN_TX="$ROOT_DIR/src/defcoin-tx"
DEFCOIN_WALLET="$ROOT_DIR/src/defcoin-wallet"
DEFCOIN_QT="$ROOT_DIR/src/qt/defcoin-qt"
APP_BIN="$ROOT_DIR/Defcoin-Qt.app/Contents/MacOS/Defcoin-Qt"

require_file() {
    local path="$1"
    if [[ ! -x "$path" ]]; then
        echo "missing executable: $path" >&2
        exit 1
    fi
}

EXPECT_ARCH="${DEFCOIN_EXPECT_ARCH:-arm64}"

require_arch() {
    local path="$1"
    if ! file "$path" | grep -q "$EXPECT_ARCH"; then
        echo "not a $EXPECT_ARCH executable: $path" >&2
        file "$path" >&2
        exit 1
    fi
}

require_help_and_version() {
    local path="$1"
    "$path" --version >/dev/null
    "$path" --help >/dev/null
}

for bin in "$DEFCOIND" "$DEFCOIN_CLI" "$DEFCOIN_TX" "$DEFCOIN_WALLET"; do
    require_file "$bin"
    require_arch "$bin"
    require_help_and_version "$bin"
done

if [[ -x "$DEFCOIN_QT" ]]; then
    require_arch "$DEFCOIN_QT"
    require_help_and_version "$DEFCOIN_QT"
else
    echo "skipping legacy Qt smoke executable: $DEFCOIN_QT"
fi

if [[ -x "$APP_BIN" ]]; then
    require_arch "$APP_BIN"
fi

TMPDIR_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/defcoin-smoke.XXXXXX")"
RPCPORT="$((30000 + RANDOM % 20000))"
PID=""

cleanup() {
    set +e
    if [[ -n "$PID" ]]; then
        "$DEFCOIN_CLI" -regtest -datadir="$TMPDIR_ROOT" -rpcport="$RPCPORT" stop >/dev/null 2>&1
        wait "$PID" >/dev/null 2>&1
    fi
    rm -rf "$TMPDIR_ROOT"
}
trap cleanup EXIT

"$DEFCOIND" -regtest -datadir="$TMPDIR_ROOT" -rpcport="$RPCPORT" -listen=0 -daemon=0 -server=1 -debug=0 &
PID="$!"

for _ in {1..60}; do
    if "$DEFCOIN_CLI" -regtest -datadir="$TMPDIR_ROOT" -rpcport="$RPCPORT" getblockchaininfo >/dev/null 2>&1; then
        break
    fi
    if ! kill -0 "$PID" >/dev/null 2>&1; then
        echo "defcoind exited before RPC became available" >&2
        exit 1
    fi
    sleep 1
done

"$DEFCOIN_CLI" -regtest -datadir="$TMPDIR_ROOT" -rpcport="$RPCPORT" getblockchaininfo >/dev/null
NETWORK_INFO="$("$DEFCOIN_CLI" -regtest -datadir="$TMPDIR_ROOT" -rpcport="$RPCPORT" getnetworkinfo)"
if ! grep -q '"/DefcoinCoreNu:26.5.5/"' <<<"$NETWORK_INFO"; then
    echo "getnetworkinfo does not report the expected DefcoinCoreNu 26.5.5 user agent" >&2
    echo "$NETWORK_INFO" >&2
    exit 1
fi

if grep -R "Application Support/Litecoin" "$TMPDIR_ROOT" >/dev/null 2>&1; then
    echo "temporary datadir unexpectedly references Litecoin application data" >&2
    exit 1
fi

SQL_WALLET="sql-smoke"
"$DEFCOIN_CLI" -regtest -datadir="$TMPDIR_ROOT" -rpcport="$RPCPORT" -named createwallet wallet_name="$SQL_WALLET" load_on_startup=false >/tmp/defcoin-sql-smoke-create.json
SQL_WALLET_INFO="$("$DEFCOIN_CLI" -regtest -datadir="$TMPDIR_ROOT" -rpcport="$RPCPORT" -rpcwallet="$SQL_WALLET" getwalletinfo)"
if ! grep -q '"format": "sqlite"' <<<"$SQL_WALLET_INFO"; then
    echo "createwallet default did not create a SQLite wallet" >&2
    echo "$SQL_WALLET_INFO" >&2
    exit 1
fi
if ! grep -q '"descriptors": true' <<<"$SQL_WALLET_INFO"; then
    echo "createwallet default did not create a descriptor wallet" >&2
    echo "$SQL_WALLET_INFO" >&2
    exit 1
fi
"$DEFCOIN_CLI" -regtest -datadir="$TMPDIR_ROOT" -rpcport="$RPCPORT" -rpcwallet="$SQL_WALLET" getnewaddress >/dev/null
if ! xxd -l 16 "$TMPDIR_ROOT/regtest/wallets/$SQL_WALLET/wallet.dat" | grep -q "SQLite format 3"; then
    echo "created wallet.dat does not have a SQLite header" >&2
    exit 1
fi

"$DEFCOIN_CLI" -regtest -datadir="$TMPDIR_ROOT" -rpcport="$RPCPORT" stop >/dev/null
wait "$PID"
PID=""

echo "Defcoin smoke test passed"
