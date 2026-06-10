# RpcConsoleView.qml Agent Notes

## Purpose

Owns the standalone RPC Console page: wallet selector, console history, command input, font-size controls, clear action, and command submission UI.

## Nu Divergence

- Replaces the split Method/Params UI with a Litecoin-style single command line while still allowing JSON arrays where the parser supports them.
- Supports multi-line pasted commands and wallet-scoped RPC execution through `NuRpcService`.

## Do Not Break

- Keep console output selectable/copyable.
- Keep warning text in the scrollable console history, not as a permanent space-wasting header.
- Do not concatenate stale input into later commands.
- Wallet selector must default safely and make node/global versus wallet-scoped commands clear.

## Verification

- `git diff --check`
- Smoke-test `getblockchaininfo`, `getnetworkinfo`, `getwalletinfo`, `getbalance`, one `addnode`, pasted multi-line `addnode`, and invalid input.
