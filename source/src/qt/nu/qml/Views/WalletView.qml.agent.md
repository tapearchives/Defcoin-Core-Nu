# WalletView.qml Agent Notes

## Purpose

Owns wallet management, wallet lists, backups, single paper-wallet generation, advanced wallet tools, watch-only import, BIP39 recovery, encryption, message signing, and address tables.

## Nu Divergence

- Hosts the single paper-wallet generator as a Wallet tab immediately after Wallets. The route is for one offline wallet at a time; bulk paper-wallet workflows belong in Explore.
- Guards tab changes away from Paper Wallet while generated private keys remain
  in memory. Accepting the warning clears the generated keys before switching;
  canceling leaves the user on Paper Wallet.
- Adds watch-only address import with optional rescan/start height.
- Adds BIP39 create, recovery, and preview workflows with guarded sensitive
  clipboard flows. BIP39 creation is launched from Files > Create through the
  combined Create Wallet dialog; the Recovery tab restores existing phrases.
- Provides wallet rename/delete safeguards around the legacy default `wallet.dat`.
- The Wallets table exposes compact encrypted, total, transaction,
  address-count, and non-zero address columns in the simple view, while
  detailed view keeps the broader balance/address breakdown.
- The Wallets panel must stay usable at narrow widths: active-wallet text,
  metric rows, toolbar actions, and explanatory copy wrap or elide inside the
  panel, while the wallet table keeps overflow inside its own scrollable frame.
- Large address books are rendered lazily/capped by default. Keep the first-page/expand controls so opening Wallet tools does not build thousands of hidden table rows and freeze the app.
- The visible tab order is Wallets, Watch-Only Addr., Paper Wallet, Recovery, Addresses, Messages, Compatibility. The QML panels use `walletPanelIndexForTab()` because the Watch-Only and Paper Wallet panels are historically declared outside visible order; keep the mapping in sync if panels move. Wallet tab buttons also set `walletTabs.currentIndex` explicitly on click so tab navigation stays reliable across Qt/platform focus behavior.

## Do Not Break

- Keep Paper Wallet as a single-wallet flow. Do not add bulk generation or coin-splitting workflows here; those belong in Explore.
- Do not bypass the generated-key leave warning when changing Wallet tabs.
- Watch-only addresses cannot spend; keep that warning visible.
- Wallet delete must move to `Deleted Wallets`, not secure-wipe or silently remove active wallet files.
- Keep wallet table sort state and simple/detailed columns aligned, including
  the compact Wallets columns for encrypted status, total, transactions,
  addresses, and non-zero addresses.
- Keep the Wallets table vertical scrollbar visible so users can tell when more
  wallets exist below the fold.
- Do not bind expensive address-book table rows while the Address Book tab is hidden.

## Verification

- `git diff --check`
- Smoke-test wallet selection, Paper Wallet tab generation/clear/print prompt on a disposable backend, backup, watch-only import on a disposable wallet, and rename/delete dialogs without touching real wallets.
