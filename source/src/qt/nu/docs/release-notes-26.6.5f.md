# Defcoin Core Nu 26.6.5f Release Notes

26.6.5f is a splash, mast, wallet-backup, large-wallet, and Metrics Traffic
clarity fix after 26.6.5e.

## Changes

- Startup splash loading text now renders centered at the top of the splash
  instead of colliding with the bottom copyright/version block.
- The mast status strip now uses stable two-line slots. `Wallet` is directly
  under `Network`, and `Sync` follows it on the second line so ordinary TX/RX
  and block-number changes do not shove every field across the header. Normal
  width slots are learned and remembered, and Reset views returns them to
  first-launch defaults.
- `Wallet > Backup active` now defaults to a filename based on the selected
  wallet and storage type, such as `wallet_test.dat` for BDB wallets and
  `wallet_test.sqlite` for SQL wallets.
- The Wallet address-book table now lazy-renders large wallets. Hidden tabs do
  not rebuild thousands of address rows, and the Addresses tab renders an
  initial 500 rows with controls to show more or all rows.
- Metrics Traffic Details mode now uses non-overlapping receive/send color
  lanes and draws a clear total receive/send outline over the stacked TCP,
  Fast Sync UDP, and Quick Clone UDP fills.
- Traffic peak labels now use a compact readable label plate instead of a
  heavy text stroke that made labels look doubled.

## Cross-Build Notes

- Windows and Lion must receive the splash/header/wallet/traffic behavior.
- Windows parity needs special verification because 26.6.5e packaging had a
  current frontend but an older inherited backend. Do not assume the Windows
  package is in full feature parity until the bundled backend version and
  Metrics Traffic UI are checked together.
- Lion may need an equivalent lazy address-book rendering change in its legacy
  QtWidgets wallet view rather than a literal QML port.

## Verification

- `git diff --check` passed for the touched Tahoe files.
- `qmllint` on the touched QML files exited 0 with only the known local
  `Defcoin.Nu` import warning outside a built bundle.
