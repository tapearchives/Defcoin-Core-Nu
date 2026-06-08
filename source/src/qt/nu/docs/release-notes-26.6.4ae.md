# Defcoin Core Nu 26.6.4ae Release Notes

## Summary

This build adds a controlled Quick Clone test launch path and brings the Lion
Intel port into parity with the Tahoe Quick Clone reservation fix.

## Changes

- Added `--quick-clone-now` and `DEFCOIN_NU_QUICK_CLONE_NOW=1` launch triggers
  so Quick Clone can be initiated during automated Tahoe/Lion LAN testing.
- Kept Quick Clone on the same Core reservation boundary as Fast Sync: Core
  chooses the block and UDP only transports that selected block.
- Ported the same reservation behavior to the Lion `26.6.4ae-Lion-alpha` build
  path.
- Added a local UDP LAN permission gate test helper for live Tahoe/Lion testing.
  If UDP evidence does not appear quickly, it beeps and speaks so the operator
  can check for the macOS Local Network prompt before protocol debugging
  continues.
- Checked the Lion sync-persistence concern before deleting chain data. The
  chain height persisted correctly; the visible percent can appear to fall when
  relaunch discovers a higher header target.

## Compatibility

- No consensus rule changes.
- No wallet format changes.
- No packet-format changes.
- Older TCP-only peers and Defcoin Core 1.0.x peers remain compatible.

## Verification

- Tahoe backend tools built and report `v26.6.4ae`.
- Tahoe app bundle built and staged at
  `Distribution_Versions/Defcoin Core Nu/Nu-26.6.4ae-20260604/Defcoin Core Nu.app`.
- Staged Tahoe app passed deep codesign verification and reports macOS
  Spotlight kind `Application`.
- Lion pre-build backend check confirmed absolute block height persisted across
  backend restart.
