# ReceiveView.qml Agent Notes

## Purpose

Owns Receive page address display, QR generation, generated request table,
request details dialog, copy/inspect actions, and paper-wallet private-key
import entry points.

## Nu Divergence

- Generated request selection updates the main QR/address display and details dialog.
- Details dialog routes Inspect Address to the local Explore app/path when available.
- Adds an Import tab for paper-wallet WIF/private-key entry. This tab hands the
  key to the local backend import path, then clears the field; it does not show
  or persist the private key in Receive state.

## Do Not Break

- Keep Date column mapping correct for generated requests.
- Long addresses and URI text must not clip; wrap or make copy fields scroll/selectable.
- Do not log, display, cache, or persist imported private-key text. The import
  field must be password-style and clear after submission.

## Verification

- `git diff --check`
- Create/select multiple receive requests and verify QR, address, date, details, copy URI, copy address, and Inspect Address.
