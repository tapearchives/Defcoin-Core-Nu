# Defcoin Core Nu 26.6.7r Release Notes

Internal Tahoe candidate focused on app-icon sizing and bundled typography.

## UI And Packaging

- Bundles Atkinson Hyperlegible Mono for paper-wallet keys, diagnostics, and
  mono-spaced UI fields.
- Registers the bundled font at startup so the app does not depend on the font
  being installed on the host system.
- Regenerates the macOS app icon from the transparent v26 coin mark with no
  white tile, gray tile, ring, or artificial margin. The same icon is shared by
  Finder, Alt-Tab, and the app runtime icon.
- Updates the classic Qt icon mirrors so older surfaces use the same v26 icon.

## Verification

- Verified `defcoin-nu-icon-1024.png` has transparent corners and an alpha
  bounding box of `1024x1024+0+0`, so the coin reaches the canvas edges and the
  outside is alpha instead of white.
- Verified the reusable v26 coin mark has transparent alpha outside the coin.
