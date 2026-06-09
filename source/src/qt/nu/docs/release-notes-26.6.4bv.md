# Defcoin Core Nu 26.6.4bv

## Summary

26.6.4bv is the next Fast Sync benchmark build after 26.6.4bu. Tahoe keeps the widened UDP reservation-window logic from 26.6.4bu, and Lion is brought into scheduler parity so UDP can keep prefetching future reserved blocks while Core validates the currently staged block.

## Changes

- Rebuilt Tahoe and Lion with matching 26.6.4bv labels.
- Brought physical Lion Fast Sync scheduling into parity with Tahoe by removing the old submit-in-flight gate that prevented UDP prefetch from filling its in-flight/cache window.
- Kept UDP-only benchmark flags:
  - `--debug-disable-core-tcp-sync`
  - `--debug-disable-quick-clone`
  - `--debug-fast-sync-lan-only`

## Test Focus

- Clear only Lion `blocks`, `chainstate`, and `indexes`, preserving wallets.
- Launch Tahoe and Lion with UDP-only flags.
- Confirm Tahoe Local Network permission is not blocking the test.
- Measure Lion accepted UDP block-body transfers from Tahoe LAN sources.
