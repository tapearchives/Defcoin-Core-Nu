# NuRpcService.h Agent Notes

## Purpose

Declares the Nu frontend service API exposed to QML, including properties, invokable wallet/RPC/network actions, timers, metrics state, and Fast Sync/Quick Clone counters.

## Nu Divergence

- Exposes traffic totals split into TCP, UDP, total, and Quick Clone subset counters.
- Exposes Metrics rows, peer data, Quick Clone settings/status, paper-wallet/watch-only actions, and Fast Sync diagnostic state to QML.
- Exposes shutdown status, the August 2026 Defcoin-only magic setting, separate
  transaction/address explorer templates, and backend log metadata used by the
  restored Debug Log panel.
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
  flow. The key and optional BIP38 passphrase parameters are private material
  and must remain a one-way local import request, not frontend state.
- Exposes `restoreWalletFromRecoveryPhrase()` with optional fixed-scan
  zero-balance skip and SQL descriptor-wallet flags plus recovery progress
  fields for address scan status, elapsed time, ETA, and local address-index
  guidance. QML must pass the skip flag only for fixed legacy auto/external
  scans, never for Nu/Core HD seed creation, SQL descriptor recovery, or
  auto-until-empty recovery.
- Exposes `createWalletWithRecoveryPhrase()` as a Create Wallet workflow, not a
  Restore Wallet workflow; it must emit `walletWorkflowFinished()` so the
  combined create dialog can preserve fields on backend failures.
- Exposes `walletWorkflowFinished()` so QML wallet dialogs can distinguish
  backend async create success from create failure without parsing generic
  user-message text.
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
- Keep workflow completion signals narrow and typed; QML must not infer wallet
  creation state by matching translated message titles.
- Keep `generatePaperWallet()` as the compatibility single-entry path and route
  new paper-sheet controls through `generatePaperWallets()`.
- Keep self-test-only invokables visibly gated in the implementation before
  changing any wallet state.
- Keep preview-page invokables read-only. They may construct placeholder
  display entries in memory, but must not generate or persist private keys.
- Preserve the miner-log throttle members when changing miner properties; QML must not be signaled once per miner output chunk.
- Keep transaction and address explorer template properties distinct.
- Keep recovery-scan flags explicit in the invokable signature; do not overload
  negative range values with additional meanings beyond auto-until-empty. SQL
  descriptor recovery must remain an explicit boolean.
- Keep local address-index recovery lookup guidance separate from the restore flag. The
  service decides whether the local index is current enough and must fall back
  to Core scanning when it is not.
- Keep `prepareForApplicationQuit()` available to QML so the shutdown overlay
  can start backend/process cleanup before the app disappears.

## Verification

- `git diff --check`
- Build Nu frontend after property or signal changes.
- Re-render at least one paper-wallet preview page after print/preview bridge
  changes.
- Open Metrics and any touched wallet view to confirm bindings update.
- Open RPC Console > Debug Log after property additions that affect log or
  explorer settings.
