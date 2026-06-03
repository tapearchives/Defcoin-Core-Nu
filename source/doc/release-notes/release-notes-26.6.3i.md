# Defcoin Core Nu 26.6.3i Release Notes

Defcoin Core Nu `26.6.3i` is a Nu Explore Network Pulse update over
`26.6.3h`.

## Nu Explore Network Pulse

- Adds recent average block time to the top mast beside current hash estimate,
  difficulty, peers, block height, sync state, and wallet status.
- Adds a Network Pulse Analyze section for at-a-glance macro network state.
- Charts indexed history for estimated hashrate, difficulty, and average block
  spacing with selectable 30, 120, 720, and 2016 block sampling windows.
- Adds hover details, block-linked table rows, and a dedicated pop-out chart
  for the Network Pulse history view.

## Index Reuse

- Reuses the existing Explorer block cache for historical pulse charts instead
  of adding another database.
- Samples current average block time from RPC block headers, with the Explorer
  index available as a fallback when header sampling is unavailable.
