# NuDetailsSwitch.qml Agent Notes

## Purpose

Compact details on/off switch used to expose advanced table/status information without consuming the space of a full segmented control.

## Nu Divergence

- Replaces Simple/Detailed controls on Metrics Status and Peers with a smaller "Details" switch.

## Do Not Break

- Keep label contrast high in both dark and light contexts.
- Keep the hit target large enough to click comfortably even though the control is visually compact.
- Help text should describe what extra detail appears without adding noise to the page.

## Verification

- `git diff --check`
- Toggle Details on Metrics Status and Peers and confirm the expected rows/columns appear without layout shift problems.
