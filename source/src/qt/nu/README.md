# Defcoin Core Nu UI

This folder contains the QML / Qt Quick implementation for Defcoin Core Nu
26.5.5f.

The files here are deliberately kept separate from the current Qt Widgets
application, so the working standard wallet behavior is unchanged while Nu is
reviewed and hardened.

## Intended Runtime Shape

```text
Defcoin Core / defcoind wallet service process
    |
    | local JSON-RPC client
    v
Defcoin Core Nu QML process
```

The Nu UI process uses `NuRpcService` to talk to a running Defcoin backend over
local JSON-RPC. For local Apple Silicon development the app can also bundle and
start `defcoind`. QML never handles private keys, transaction signing, chain
validation, peer logic, or wallet storage directly.

## Build Status

Standalone review app:

```bash
/opt/homebrew/bin/qt-cmake -S src/qt/nu/app -B build/nu-qml-arm64 \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DDEFCOIN_NU_BACKEND_BINARY="$PWD/src/defcoind"
cmake --build build/nu-qml-arm64 --config Release
```

The standalone app is not wired into `src/Makefile.qt.include` yet. It is built
as a separate review app while the process boundary and QML shell stabilize.

## Design Rules

- keep irreversible wallet actions review-first;
- never put signing, key, chain, or peer logic in QML;
- use neutral visual tokens from `qml/Theme/Tokens.qml`;
- expose node activity clearly without making status indicators look like
  destructive controls;
- defer heavy tab data until after the first visible view renders.
