# NodeView.qml Agent Notes

## Purpose

Owns the Metrics view: Traffic graph, Status table, Peers table, banned peers,
peer inspection, traceroute output, and normal-vs-Details presentation.

## Nu Divergence

- Renamed Diagnostics to Metrics and made Metrics read-only.
- Uses Details switches for Status and Peers instead of large Simple/Detailed tabs.
- Displays Core Sync (TCP), Fast Sync (UDP), Quick Clone (LAN UDP), peer service bits, workstation discovery, and protocol-method success state.
- Keeps peer sort state when switching between simple and detailed peer views.
- Peer inspection values are read-only selectable text so users can copy any
  displayed line.
- Trippy output uses Nu's mono font and a large non-scrolling terminal layout;
  the process environment should provide enough rows/columns for single-page
  output.

## Do Not Break

- The simple Status view should show high-value sync health and UDP/TCP mix at a glance; lower-level probe details belong behind Details.
- Peer column arrays must stay length-aligned: labels, types, sort keys, sort meta fields, weights, minimums, maximums, and tooltips.
- Workstation/LAN cells must remain compact, with LAN icon text integrated into the Seed Source / LAN Workstation Name column.
- Re-test Fast Sync expects exactly one selected peer row; selection helpers must return stable node IDs.
- The visible Node column may show `5 (g1)` to indicate a same-node group. Selection, Retest FastSync, Ban, and Trace must still use the real `meta.nodeId`, and hover text must explain the `(gN)` suffix.
- Do not reintroduce launch/debug log ownership here without also updating RPC
  Console and `NuDebugLogPanel`; the restored Debug Log tab is under RPC
  Console.

## Verification

- `git diff --check`
- Open Metrics > Status and Metrics > Peers at realistic window widths and check row height, wrapping, sorting, selection, and hover text.
- Inspect peer details and traceroute output for selectability, copying, mono
  font, and terminal sizing.
