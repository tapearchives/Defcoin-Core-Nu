# Defcoin Core Nu 26.6.2i Release Notes

Defcoin Core Nu `26.6.2i` is a Movement Map stability and load-time update over
`26.6.2h`.

## Movement Map

- Strengthens graph collision spacing so large neighboring nodes are less likely
  to cover amount labels.
- Uses a more conservative per-node fitted font calculation for rounded whole
  DFC values such as `999.-`.
- Expands node margins so address labels stay anchored below circles with more
  room at the graph edges.
- Caps the Movement Network density at `Top 50`, which keeps the force graph
  readable and avoids spending time on visually unusable node counts.
- Keeps the richer graph treatment from `26.6.2h`: colored flow roles,
  stronger blue transfer lines, directional arrows, hover details, click-through
  addresses, drag repositioning, popout view, and node-scale sliders.

## Explorer Analytics

- Loads movement rows through the indexed high-value-output path, then adds
  source address endpoints only for the newest/largest rows used by the
  Movement Network graph.
- Avoids the expensive full grouped transaction scan during movement loading;
  the table and graph sort the loaded threshold sample in the UI.
