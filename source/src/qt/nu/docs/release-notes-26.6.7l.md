# Defcoin Core Nu 26.6.7l Release Notes

Date: 2026-06-16

## Paper Wallet

- Added an off-by-default `Allow weak phrases?` option beside BIP38 passphrase entry. Normal BIP38 generation still requires a stronger passphrase; the override exists for explicit user-controlled test or compatibility cases.
- Split the Paper Wallet route into independent left workflow and right sheet-preview panes. The staged workflow now owns vertical scrolling, while the sheet preview owns horizontal and vertical scrollbars plus zoom controls for close inspection.
- Tightened sheet-preview fitting so the selected print page uses more of the available preview frame and can zoom beyond the pane when needed.
- Improved the entropy hourglass overlay with denser falling sand and a non-rectangular upper sand surface so the animation better matches a sealed physical hourglass.
- Fixed Design 1 side-panel purple borders so the checkerboard flaps have visible, connected top-layer outlines.
- Reworked Design 2 landscape layout so each panel's QR, coin, and text elements rotate and fit within the printed frame instead of colliding.
- Fixed Design 3 top-layer frame ordering so the Avery 5011 card border stays visible around the printed form.
- Updated Design 5 no-art output to remove ink-heavy artwork while retaining static/noise blocks, a low-ink BrainSilo memorial mark, readable key lanes, and a full `DFC` corner mark.

## Verification

- Built Apple Silicon Tahoe Nu candidate `26.6.7l`.
- Verified bundle signing with `codesign --verify --deep --strict`.
- Rendered and visually inspected affected paper-wallet sheets through `src/qt/nu/tools/render_paper_wallet_previews.sh`, including Design 5 no-art after the final renderer patch.
- Ran QML and whitespace verification for changed UI files.
