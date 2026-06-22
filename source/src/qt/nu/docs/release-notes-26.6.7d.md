# Defcoin Core Nu 26.6.7d Release Notes

## Wallet

- Adds the single Paper Wallet generator to `Wallet > Paper Wallet`, immediately after Files.
- Keeps the generator local and one-wallet-at-a-time. Bulk paper-wallet creation remains a future reviewed workflow outside this release.
- Uses the existing secure paper-wallet behavior from 26.6.7c: local key derivation, in-memory QR data, explicit print confirmation, and no private-key logging or settings persistence.

## Branding and UI

- Updates the reusable Nu lockup to use the v26 coin mark instead of the older stacked-coin artwork.
- Applies the current wordmark spacing from the logo construction notes to reusable QML lockups.
- Adds a subtle dark-purple hover outline to left navigation buttons while preserving the existing selected and keyboard-focus states.

## Developer Notes

- Wallet view ownership notes now document that Nu owns the single Paper Wallet tab and keeps future bulk paper-wallet workflows out of this release.
- Paper Wallet view notes now document the shared embedded route mode.
