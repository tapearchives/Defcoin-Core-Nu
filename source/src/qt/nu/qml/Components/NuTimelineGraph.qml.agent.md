# NuTimelineGraph.qml Agent Notes

## Purpose

Renders the Metrics traffic timeline canvas, including total traffic in simple mode and stacked TCP / Fast Sync UDP / Quick Clone UDP rate components in Details mode.

## Nu Divergence

- Simple mode intentionally stays quiet: total received and total sent only.
- Details mode separates TCP, Fast Sync UDP, and Quick Clone UDP while preserving total received/sent scaling.
- Quick Clone is still counted inside UDP totals; the separate QC UDP stack is a visual diagnostic breakout, not a third transport.
- Detailed stacked rendering keeps received traffic in green-family colors and sent traffic in blue-family colors, with the total top stroke using the historical received/sent colors.
- Peak labels use a light plate instead of text stroke/drop shadow because stroked text becomes visually doubled on some renderers.

## Do Not Break

- Keep every visible graph component distinguishable by label and color.
- Do not double-count Quick Clone in total traffic.
- Keep hover readout compact and consistent with the footer grid in `NodeView.qml`.
- Paint larger total groups first and smaller groups later so the smaller stack remains visible when sent/received rates overlap.

## Verification

- `git diff --check`
- Open Metrics > Traffic with live samples and confirm legend labels, hover text, and line styles are unambiguous.
