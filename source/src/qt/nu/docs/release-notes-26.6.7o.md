# Defcoin Core Nu 26.6.7o Release Notes

Internal Tahoe candidate focused on finishing the Paper Wallet UI cleanup pass
and adding a local paper-wallet import path.

## Paper Wallet

- Removes the decorative entropy hourglass animation. The entropy step now uses
  progress bars and explicit status text only.
- Entropy capture is opt-in: mouse and keyboard input are ignored until Start
  Entropy Input is pressed, then capture stops automatically at 100%.
- Keeps preview/print on the same C++ renderer path and tightens Design 1 frame,
  QR, and caption placement.

## Receive

- Adds a Receive > Import tab for paper-wallet WIF/private-key import into the
  active wallet.
- The entered private key is passed directly to local wallet RPC import and the
  field is cleared after submission.

## Branding

- Regenerates the app icon from the transparent v26 coin mark with a larger
  fill ratio.

## Verification

- Built Tahoe app target after the update; Ninja reported the target current.
- Rendered all five paper-wallet designs through the shared print/preview
  renderer and inspected the generated contact sheet.
- Ran a route-limited offscreen UI smoke test for Wallet > Paper Wallet and
  verified the staged workflow scrollbar plus width-fitted sheet preview.
- Ran `git diff --check` on the touched source, QML, and documentation files.
