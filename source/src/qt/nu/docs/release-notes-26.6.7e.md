# Defcoin Core Nu 26.6.7e Release Notes

## Branding and Layout

- Corrects the Nu logo lockup and app icon to use a transparent-background v26
  colored Defcoin coin mark rather than the older icon tile/stacked-coin
  artwork.
- Applies the same coin-to-wordmark ratio, spacing, and line alignment used by
  the current Defcoin Core website prototype.
- Updates the startup splash rendering to use the pure v26 coin beside the Nu
  wordmark.
- Adds hover feedback even when the selected left navigation button is already
  active, so rollover state remains visible.

## Paper Wallet

- Removes the decorative logo from the on-screen paper-wallet GUI; branding is
  now reserved for the printable paper wallet.
- Raises the entropy interaction target before a paper wallet can be generated.
- Reworks paper-wallet printing as a one-page foldable Letter sheet with public
  address QR, private key QR, fold guidance, and offline-printing warnings.
- Improves the print confirmation dialog spacing so buttons are not crowded
  against the window edge.

## Developer Notes

- `brand-logo-text.md` now documents the v26 coin-plus-wordmark construction
  rules for future app, website, and installer artwork.
