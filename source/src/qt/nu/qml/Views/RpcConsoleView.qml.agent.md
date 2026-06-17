# RpcConsoleView.qml Agent Notes

## Purpose

Owns the RPC Console section: wallet selector, console history, command input,
font-size controls, clear action, command submission UI, and the restored Debug
Log tab.

## Nu Divergence

- Replaces the split Method/Params UI with a Litecoin-style single command line while still allowing JSON arrays where the parser supports them.
- Supports multi-line pasted commands and wallet-scoped RPC execution through `NuRpcService`.
- Hosts `NuDebugLogPanel` as the Debug Log tab. Keep the console and log tools
  in this Advanced section unless product direction moves logs elsewhere.

## Do Not Break

- Keep console output selectable/copyable.
- Keep warning text in the scrollable console history, not as a permanent space-wasting header.
- Do not concatenate stale input into later commands.
- Wallet selector must default safely and make node/global versus wallet-scoped commands clear.
- Debug Log must keep selectable/copyable output and line-number controls.

## Verification

- `git diff --check`
- Smoke-test `getblockchaininfo`, `getnetworkinfo`, `getwalletinfo`, `getbalance`, one `addnode`, pasted multi-line `addnode`, and invalid input.
- Open the Debug Log tab after RPC Console layout changes.
