# Defcoin Core Nu 26.6.4br

## Sync UI

- Changes the header sync estimate from compact prose such as `Est. 2h 14m`
  to fixed clock text: `ETA HH:MM:SS`.
- Bases the primary ETA on a smoothed average of accepted block-height progress,
  so the mast reflects the recent block acceptance rate rather than only Core's
  floating verification-progress delta.
- Resets the sampled average when the backend disconnects or the node reaches
  up-to-date state, preventing stale sync speed from leaking into a later run.

## Cross-Build Notes

- Lion, Catalina, and Windows should port the same `NuRpcService` sync ETA
  changes if they share this QML service path.
- Server builds do not need this update unless they expose the Nu GUI status
  header; the Fast Sync protocol itself is unchanged.
