# Defcoin Core Nu UI Implementation

This directory contains the developer reference for Defcoin Core Nu 26.6.4y.
Nu is a Qt Quick interface that talks to the Defcoin Core backend through a
small JSON-RPC service layer.

## Target

- Qt Quick / QML presentation.
- GUI/client process separated from node/wallet service process where possible.
- Local app bundle may start a bundled `defcoind` when no RPC backend is
  already available.
- Neutral professional visual style.
- Wallet actions routed through the local `NuRpcService` JSON-RPC client.
- No consensus, wallet, or networking internals on the QML scene thread.

## Do Not Put Here

- consensus changes;
- private-key handling;
- wallet database access;
- transaction signing;
- direct peer-manager access;
- blocking network or filesystem work on the QML scene thread.

## Files

```text
qml/Main.qml              Nu shell entry point
qml/Components/           reusable QML controls
qml/Shell/                app frame, nav, and status strip
qml/Theme/Tokens.qml      neutral visual tokens
qml/Views/                wallet and node views
assets/icons/             Nu SVG icon system
assets/brand/             Nu app icon, splash, QR, and brand mark
resources/nu.qrc          Qt resource manifest for the Nu app
```

See `functionality-map.md` for the current Litecoin/Defcoin wallet function
coverage map.

See `defcoin-core-nu-goals.md` for the Defcoin Core Nu and Explore product,
community, explorer, and forensics goals.

See `backend-frontend-boundary.md` for the service-boundary rules that keep
wallet keys, signing, validation, and networking out of QML.

See `build-and-installer-runbook.md` for the current local build, staging,
installer, cleanup, and verification procedure.

See `cross-build-change-log.md` for the internal Tahoe-to-Lion/Catalina/Windows
change ledger. Update it for every build that changes behavior, packaging,
backend interfaces, or porting assumptions.

See `initial-launch-crash-prevention.md` for the confirmed recent launch-crash
causes, smoke gates, and triage order for new app bundles.

See `brand-logo-text.md` for the canonical Defcoin Core Nu wordmark font,
kerning, Explore third-line variant, and DMG layout rules.

See `bitcoin-core-qml-comparison.md` for the architecture comparison with
Bitcoin Core QML.

See `fast-sync-protocol.md` for the authoritative Fast Sync protocol,
packet-size, diagnostics, and server deployment reference.
