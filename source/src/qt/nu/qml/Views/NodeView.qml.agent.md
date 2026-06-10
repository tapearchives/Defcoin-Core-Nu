# NodeView.qml Agent Notes

## Purpose

Owns the Metrics view: Traffic graph, Status table, Peers table, banned peers, launch/debug log filters, and normal-vs-Details presentation.

## Nu Divergence

- Renamed Diagnostics to Metrics and made Metrics read-only.
- Uses Details switches for Status and Peers instead of large Simple/Detailed tabs.
- Displays Core Sync (TCP), Fast Sync (UDP), Quick Clone (LAN UDP), peer service bits, workstation discovery, and protocol-method success state.
- Keeps peer sort state when switching between simple and detailed peer views.

## Do Not Break

- The simple Status view should show high-value sync health and UDP/TCP mix at a glance; lower-level probe details belong behind Details.
- Peer column arrays must stay length-aligned: labels, types, sort keys, sort meta fields, weights, minimums, maximums, and tooltips.
- Workstation/LAN cells must remain compact, with LAN icon text integrated into the Seed Source / LAN Workstation Name column.
- Re-test Fast Sync expects exactly one selected peer row; selection helpers must return stable node IDs.

## Verification

- `git diff --check`
- Open Metrics > Status and Metrics > Peers at realistic window widths and check row height, wrapping, sorting, selection, and hover text.
