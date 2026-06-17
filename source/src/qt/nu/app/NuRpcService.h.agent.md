# NuRpcService.h Agent Notes

## Purpose

Declares the Nu frontend service API exposed to QML, including properties, invokable wallet/RPC/network actions, timers, metrics state, and Fast Sync/Quick Clone counters.

## Nu Divergence

- Exposes traffic totals split into TCP, UDP, total, and Quick Clone subset counters.
- Exposes Metrics rows, peer data, Quick Clone settings/status, Explore paper-wallet/watch-only actions, and Fast Sync diagnostic state to QML.
- Exposes Paper Wallet state as both first-entry convenience properties and a
  `paperWalletEntries` list for multi-address print sheets.
- Owns service-side in-memory paper-wallet secrets so regenerated sheets can
  preserve already displayed public addresses while changing BIP38/private-key
  presentation. This vector is private implementation state and must be cleansed
  by the clear path.
- Exposes `paperWalletPreviewPageSources()` so QML sheet previews are PNG data
  URLs rendered from the same C++ paper-wallet page renderer used by printing.
- Exposes `fundPaperWallets()` for the reviewed active-wallet funding stage; it
  accepts public address/amount rows only.
- Exposes `importPaperWalletPrivateKey()` for the Receive > Import paper-wallet
  flow. The parameter is private key material and must remain a one-way local
  import request, not frontend state.
- Exposes an internal paper-wallet placeholder installer for `--ui-self-test`;
  it is not a user-facing wallet API.
- Owns the miner-log throttle timer state used to batch high-volume miner output before notifying QML.

## Do Not Break

- QML property names are part of the frontend contract. Rename only with synchronized QML changes.
- Keep Quick Clone counters clearly subordinate to UDP totals to avoid double-counted graphs.
- Keep signal emissions paired with property changes (`trafficChanged`, `stateChanged`, `settingsChanged`) or QML will show stale data.
- Keep Paper Wallet clear/print/QR properties synchronized with `walletChanged`; stale WIF data must not remain visible after clear or derivation failure.
- Keep paper-wallet funding invokables separate from generated private-key state;
  QML must never pass WIF/private-key values into funding.
- Keep paper-wallet import invokables separate from funding and preview state;
  QML may submit the private key for import, but must not retain or echo it.
- Keep `generatePaperWallet()` as the compatibility single-entry path and route
  new paper-sheet controls through `generatePaperWallets()`.
- Keep self-test-only invokables visibly gated in the implementation before
  changing any wallet state.
- Keep preview-page invokables read-only. They may construct placeholder
  display entries in memory, but must not generate or persist private keys.
- Preserve the miner-log throttle members when changing miner properties; QML must not be signaled once per miner output chunk.

## Verification

- `git diff --check`
- Build Nu frontend after property or signal changes.
- Re-render at least one paper-wallet preview page after print/preview bridge
  changes.
- Open Metrics and any touched wallet view to confirm bindings update.
