# NuTimelineGraph.qml Agent Notes

## Purpose

Renders the Metrics traffic timeline canvas, including total/TCP/UDP rate series, hover readout, and legend.

## Nu Divergence

- Shows total, TCP, and UDP traffic with distinct line styles so every graph item is visually unique.
- Does not draw Quick Clone as a separate series because Quick Clone is UDP traffic; Quick Clone-specific counters can remain in status/CSV diagnostics.

## Do Not Break

- Keep received and sent series distinguishable by both color family and line style.
- Do not double-count Quick Clone in total traffic.
- Keep hover readout compact and consistent with the footer grid in `NodeView.qml`.

## Verification

- `git diff --check`
- Open Metrics > Traffic with live samples and confirm legend labels, hover text, and line styles are unambiguous.
