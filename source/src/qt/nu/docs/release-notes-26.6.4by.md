# Defcoin Core Nu 26.6.4by

Internal Fast Sync benchmark build for Tahoe and Lion.

## Changes
- Fixed a UDP Fast Sync staged-block debug log bug where the transfer record was removed before the `chunks=` value was logged, producing bogus large chunk counts.
- Brought the Lion Fast Sync selector into parity with Tahoe by using the short LAN request interval for verified LAN UDP peers instead of the public UDP keepalive interval.
- Kept the LAN UDP-only benchmark launch mode:
  `--debug-disable-core-tcp-sync --debug-disable-quick-clone --debug-fast-sync-lan-only`.

## Verification Notes
- The pre-fix Lion run proved UDP block transport worked but paused after block 49.
- After the Lion selector fix, the physical Lion iMac accepted blocks past the previous stall point over LAN UDP from Tahoe with no fresh failures or duplicates in the sampled window.
