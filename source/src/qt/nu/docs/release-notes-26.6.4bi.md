# Defcoin Core Nu 26.6.4bi

This build fixes a test-contamination problem that could silently disable
Fast Sync or Quick Clone when a stale debug environment variable was left in
macOS launchd.

## Changes

- Added a startup guard that clears inherited `DEFCOIN_NU_DEBUG_DISABLE_*`
  variables unless the app is explicitly launched with `--debug-use-env` or
  `DEFCOIN_NU_ALLOW_DEBUG_ENV=1`.
- Command-line debug switches still work for controlled tests, including
  `--debug-disable-core-tcp-sync` and `--quick-clone-now`.
- Tahoe and Lion were tested with the iMac chain reset and Core TCP block
  downloads disabled. Lion accepted UDP Fast Sync blocks through Core
  validation, proving UDP block transfer was active.
- Quick Clone was retested after clearing the stale disable flag. Lion accepted
  LAN blocks through the Quick Clone path while Core TCP block downloads were
  disabled.

## Notes

- Quick Clone in this build is still the validated LAN block-copy scaffolding,
  not the future validation-bypass DCOL snapshot installer.
- Wallet files are never deleted or copied by these tests.
