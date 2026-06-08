# Defcoin Core Nu 26.6.4az Release Notes

## Fast Sync Test Reliability

- Improved UDP Fast Sync Metrics so probe misses are no longer mixed together
  with real block payload failures.
- Split UDP failure reporting into request timeouts, checksum failures, buffer
  failures, Core submit failures, request-send failures, probe-send failures,
  and probe misses.
- Updated the macOS Local Network Allow helper used during Tahoe testing so it
  relies on the native system prompt instead of whole-screen OCR by default.

## Notes

- Consensus, wallet storage, and normal Core block validation are unchanged.
- This build is intended to produce more trustworthy Tahoe-to-Lion Fast Sync
  test evidence before installing the same Fast Sync feature set on the server.
