# Defcoin Core Nu 26.6.4x Release Notes

## Summary

This build fixes two targeted interaction issues: peer-row actions now use the
actual selected peer row, and Quick Clone now clearly acknowledges when a LAN
source stops answering.

## Changes

- Fixed `Retest FastSync` and `Ban peer` row handling in Metrics > Peers so the
  action validates one current table row before calling the backend.
- Added a reusable table helper that resolves selected row keys from row
  selection and, when needed, from the selected cell/range.
- Quick Clone now tracks the current LAN source host for an in-flight request.
- If a Quick Clone source times out or cannot be sent to, the receiver marks
  that source offline for this session, removes it from active verified source
  sets, records a diagnostic, and tries another trusted LAN source when one is
  available.

## Safety Boundary

The peer action fix is UI/input validation only. The Quick Clone change does not
alter block validation, wallet data, or private key handling; it only makes the
receiver's source state more accurate after a source disappears.
