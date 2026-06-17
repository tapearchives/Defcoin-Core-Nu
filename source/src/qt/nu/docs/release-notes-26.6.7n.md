# Defcoin Core Nu 26.6.7n Release Notes

Internal Tahoe candidate focused on shipping the Paper Wallet polish build with
the latest OpenSSL 3.6 patch runtime.

## Paper Wallet

- Keeps the 26.6.7m entropy-hourglass polish: the upper sand follows the glass
  chamber, drains from a flatter-to-slightly-concave surface, and avoids the
  earlier rectangular source-sand shape.
- Keeps the right-side Sheet Preview wider and tied to the real print renderer,
  so the visible preview reflects the actual printout rather than a separate
  QML approximation.
- Keeps the split scroll behavior: the staged workflow scrolls vertically on
  the left, while the sheet preview owns its own scroll/zoom surface.

## OpenSSL

- Pins the Tahoe Apple Silicon candidate to OpenSSL 3.6.3 from the official
  OpenSSL source tarball.
- The Nu frontend is configured against the local OpenSSL 3.6.3 static crypto
  library, and the app bundle carries OpenSSL 3.6.3 `libcrypto.3.dylib` and
  `libssl.3.dylib` for backend/runtime use.
- The OpenSSL 3.6.3 tarball checksum was verified before build:
  `243a86649cf6f23eeb6a2ff2456e09e5d77dd9018a54d3d96b0c6bdd6ba6c7f1`.

## Verification

- Tahoe CMake build completed for `26.6.7n`.
- Bundle signing was refreshed after replacing the OpenSSL runtime dylibs.
- The bundled `libcrypto.3.dylib` reports `OpenSSL 3.6.3 9 Jun 2026`.
