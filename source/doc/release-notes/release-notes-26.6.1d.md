# Defcoin Core Nu 26.6.1d Release Notes

Defcoin Core Nu `26.6.1d` is a packaging correction over `26.6.1c`.

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
