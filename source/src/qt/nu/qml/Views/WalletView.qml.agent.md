# WalletView.qml Agent Notes

## Purpose

Owns wallet management, wallet lists, backups, advanced wallet tools, paper wallet UI, watch-only import, BIP39 recovery, encryption, message signing, and address tables.

## Nu Divergence

- Adds native paper wallet generation UI and optional public-address watch-only metadata import.
- Adds watch-only address import with optional rescan/start height.
- Adds BIP39 recovery/preview workflows and guarded sensitive clipboard flows.
- Provides wallet rename/delete safeguards around the legacy default `wallet.dat`.
- Large address books are rendered lazily/capped by default. Keep the first-page/expand controls so opening Wallet tools does not build thousands of hidden table rows and freeze the app.
- The visible tab order is Files, Recovery, Security, Addresses, Tools, Messages, Compatibility. The QML panels use `walletPanelIndexForTab()` because the Tools panel is historically declared before Recovery; keep the mapping in sync if panels move.

## Do Not Break

- Never log or persist paper wallet WIF/private keys unless the user explicitly chooses a future import workflow.
- Watch-only addresses cannot spend; keep that warning visible.
- Wallet delete must move to `Deleted Wallets`, not secure-wipe or silently remove active wallet files.
- Keep wallet table sort state and simple/detailed columns aligned.
- Do not bind expensive address-book table rows while the Address Book tab is hidden.

## Verification

- `git diff --check`
- Smoke-test wallet selection, backup, paper wallet generation, watch-only import on a disposable wallet, and rename/delete dialogs without touching real wallets.
