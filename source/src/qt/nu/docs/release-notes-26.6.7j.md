# Defcoin Core Nu 26.6.7j Release Notes

Internal Tahoe candidate focused on Paper Wallet preview stability and entropy
visual polish.

## Changed

- Paper Wallet sheet previews now use a content-keyed cache. The preview no
  longer refreshes every few seconds when the selected design and wallet inputs
  have not changed.
- Added a render-only paper-wallet preview path for fast layout iteration
  without launching the full Nu UI self-test route/menu walk.
- Replaced the entropy image with a sealed gold-capped hourglass and kept sand
  motion as a lightweight QML overlay.
- Added persistent vertical scrolling to the Paper Wallet step area so deeper
  stages remain reachable.
- Added zoom controls to the full print preview pop-out.
- Moved unusable/test-print warnings to the printout footer so they do not hide
  the first wallet preview.
- Tightened hide-art behavior for Paper Wallet designs, including the Defcoin
  Bulk design retaining only the intended static/noise and project mark while
  removing the heavy art background.

## Verification

- `cmake --build build/nu-qml-arm64-26.6.7j -j6`
- `qmllint` on `PaperWalletView.qml` completed with only the existing
  standalone-context warnings for injected `NuService` and delegate scoping.
- `git diff --check`
- Render-only preview pass for all five designs in normal mode.
- Render-only preview pass for all five designs in hide-art mode.
- Contact-sheet inspection of the normal and hide-art preview pages.
