# defcoin_fast_syncd.py Agent Notes

## Purpose

Runs a headless UDP Fast Sync responder against a local Defcoin backend RPC endpoint. It is useful for server-side Fast Sync serving and LAN protocol debugging without the QML frontend.

## Nu Divergence

- Implements the same `defcoin-nu-udp-fast-sync-v1` datagram envelope and service-bit 29 capability checks used by Nu.
- Serves raw blocks only after validating the requesting peer is allowed and advertises Fast Sync capability.
- Stays responder-only: requesting wallets choose packet sizing, reserve blocks through Core, verify checksums, and submit blocks through normal Core validation.

## Do Not Break

- Do not make this tool a consensus validator or wallet manager.
- Do not serve wallet/private/config files, RPC cookies, or non-public data.
- Do not treat service bit 29 alone as proof a peer can receive useful UDP traffic; keep allowlist and probe behavior explicit.
- Do not require QML, Qt, or desktop-only dependencies.
- Keep log lines useful for debugging but avoid dumping full block payloads or credentials.

## Verification

- `ruff check source/src/qt/nu/tools/defcoin_fast_syncd.py`
- `python3 source/src/qt/nu/tools/defcoin_fast_syncd.py --help`
- In live testing, confirm probe response, block request, chunk send, checksum, and ignored-peer logging behavior.
