# Defcoin Core Nu 26.6.4bl

Internal fix build focused on Fast Sync status accuracy.

## Changes

- Keep UDP node success/failure counts useful after a peer is retested or reset.
- Clear a peer from the UDP failed-node bucket when transport verification is
  reset, when stale reservations are cleared, or when a user runs Retest
  FastSync.
- Preserve the 26.6.4bk LAN-first source selection and 26.6.4bj transport-rate
  reporting.

## Notes

- This does not change consensus, validation, or block acceptance. It only
  corrects Fast Sync accounting so the status page reflects current attempts.
