# ReceiveView.qml Agent Notes

## Purpose

Owns Receive page address display, QR generation, generated request table, request details dialog, and copy/inspect actions.

## Nu Divergence

- Generated request selection updates the main QR/address display and details dialog.
- Details dialog routes Inspect Address to the local Explore app/path when available.

## Do Not Break

- Keep Date column mapping correct for generated requests.
- Long addresses and URI text must not clip; wrap or make copy fields scroll/selectable.
- Do not expose private key material here; Receive handles public addresses and payment request URIs only.

## Verification

- `git diff --check`
- Create/select multiple receive requests and verify QR, address, date, details, copy URI, copy address, and Inspect Address.
