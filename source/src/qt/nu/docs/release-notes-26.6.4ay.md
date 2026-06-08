# Defcoin Core Nu 26.6.4ay Release Notes

## Summary

This build corrects Fast Sync diagnostics after fresh Tahoe-to-Lion testing with
the current builds and macOS LAN permission allowed. A UDP probe can succeed
while Core still cannot schedule a block body because the receiver is still
building enough headers. The UI now reports that state clearly instead of making
it look like UDP failed.

## Changes

- Added specific backend reservation reasons for early Core scheduling gates:
  peer best block unknown, peer chain not ahead, and headers below minimum
  chainwork.
- Updated Fast Sync and Quick Clone status text to distinguish header-sync
  waiting from UDP transport failure.
- In UDP-only test mode, status text now states that Core TCP block copy is off
  instead of saying normal TCP fallback is active.
- Startup RPC batch calls now normalize transient backend transport errors so a
  raw "Connection refused" popup should not appear while the backend is still
  coming up.
- macOS LAN workstation-name discovery now bounds the Bonjour `dns-sd` scan so
  peer refreshes do not leave orphaned helper processes.

## Testing Notes

Live testing before this build showed Tahoe sending a UDP probe acknowledgement
to the Lion VM. The remaining gate was Core scheduling while Lion was still at
block 0 and building headers. Retest accepted UDP block transfer after the
receiver has enough headers for Core to reserve downloadable blocks.
