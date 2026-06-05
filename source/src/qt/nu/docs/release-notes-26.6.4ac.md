# Defcoin Core Nu 26.6.4ac Release Notes

## Summary

This build fixes a Quick Clone / Fast Sync interaction found during live
Tahoe-to-Lion rebuild testing.

## Changes

- Quick Clone no longer turns off ordinary Core P2P networking while it is only
  listening, probing, or requesting LAN block data.
- If a prior Quick Clone attempt left Core networking paused, Nu now resumes
  Core P2P sync before continuing.
- Quick Clone status text now says when it is receiving blockchain data over
  LAN and which block/source it is requesting.
- The earlier IPv4-mapped LAN sender fix and already-have receiver cleanup are
  retained.

## Diagnosis

After the Lion blockchain/index folders were removed for a clean rebuild test,
Lion briefly connected to Tahoe and then showed `networkactive=false` with zero
peers. The cause was Quick Clone's scaffolding path pausing Core P2P before any
real snapshot install stage existed. That prevented normal peer selection and
therefore prevented the lower-level Fast Sync reservation path from doing useful
work.

Quick Clone should only isolate Core networking during a future final snapshot
install/swap stage. It should not isolate networking while waiting for LAN
sources or requesting normal Core-accepted block transfers.

## Compatibility

This does not change consensus, wallet storage, service bits, packet format,
checksum behavior, or block validation. UDP-delivered blocks still enter Core's
normal block acceptance path.

