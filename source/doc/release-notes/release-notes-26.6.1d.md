# Defcoin Core Nu 26.6.1d Release Notes

Defcoin Core Nu `26.6.1d` is a packaging correction over `26.6.1c`.

## Defcoin Core Explore

- Renamed the former Defcoin Core ExpFor app to Defcoin Core Explore.
- Updated the macOS app bundle name, executable, bundle identifier, DMG naming,
  About text, Nu handoff target, and installer wordmark for Explore.
- The Explore wordmark renders `DEFCOIN / CORE NU / EXPLORE`, with the third
  line fitted to the lockup width.

## Explorer Performance

- Cached indexed block and output counts in the local Explorer SQLite metadata
  table so status and stats refreshes do not repeatedly run full-table counts.
- Added covering and partial SQLite indexes for movement joins and rich-list
  unspent-output tallying.
- Kept the Apple Silicon ARM SHA2 backend path used by the Nu wallet for
  validation-heavy work.

## Fixed

- Fixed Apple Silicon distribution staging so the final `.app` always includes
  the required Qt platform, style, SQLite, TLS, image, icon, and QML runtime
  plugins.
- Added this plugin deploy step to the distribution script itself, so the DMG
  build cannot silently pass with bundled frameworks but a missing
  `libqcocoa.dylib` platform plugin.

## Carried Forward

- Keeps the `26.6.1b` Diagnostics Peers table alignment and LAN workstation
  name de-duplication fixes.
- Keeps the `26.6.1c` bundled Qt framework install-name repair.
