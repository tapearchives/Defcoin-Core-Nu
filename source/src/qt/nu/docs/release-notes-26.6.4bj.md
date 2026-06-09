# Defcoin Core Nu 26.6.4bj

Internal fix build focused on Fast Sync visibility and LAN throughput testing.

## Changes

- Corrected Metrics status accounting so Core header traffic is reported
  separately from block-body transfer.
- Updated the sync overview to compare UDP accepted blocks against Core/TCP path
  chain advances without treating header sync bytes as TCP block download speed.
- Added UDP node success/failure counts based on accepted UDP blocks, timeouts,
  checksum failures, buffer failures, and submit failures.
- For verified LAN Fast Sync peers, removed the overly conservative 5-second
  UDP retry pacing and let block requests refill the active transfer window.
- Increased the UDP receiver window modestly to keep wired LAN sources busier
  while retaining the existing memory cap.

## Notes

- If UDP still measures slower after this build, the likely bottleneck is block
  reservation/validation pacing, not raw LAN bandwidth. Quick Clone/DCOL remains
  the planned validation-bypass path for trusted same-owner LAN snapshots.
