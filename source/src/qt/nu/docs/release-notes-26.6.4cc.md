# Defcoin Core Nu 26.6.4cc Release Notes

Date: 2026-06-09

## Fast Sync UDP

- Fixed the all-modes LAN Fast Sync reservation path so UDP no longer races
  Core TCP for the same next block height.
- Normal sync now keeps Core's peer/block scheduler in charge and uses UDP only
  as an alternate transport for Core-reserved blocks.
- UDP-only benchmark/debug mode still uses explicit LAN height reservations.
- Expanded the backend `reserve-next` candidate scan so UDP can find a nearby
  block that is not already active, already stored, or already in flight.

## Verification

- Built Tahoe Apple Silicon `26.6.4cc` and Lion Intel
  `26.6.4cc-Lion-alpha` with matching Fast Sync scheduler logic.
- Reset only the Lion public chain/index folders, leaving wallet/config data
  untouched.
- Launched Tahoe through the Local Network Allow launch gate; no prompt was
  visible for this already-allowed build and the gate recorded a clean audit.
- Launched Lion with Core TCP, UDP Fast Sync, and Quick Clone discovery all
  enabled; Quick Clone was not selected.
- Confirmed current-run UDP block delivery from Tahoe to Lion:
  Lion logged UDP-accepted blocks including `3005`, `3006`, `3015`, `16962`,
  `17864`, and `19368`, while Tahoe logged matching `NU_UDP_FASTSYNC_SERVE`
  rows.
- Confirmed persistence: Lion stopped cleanly at block `21559`, relaunched from
  the same datadir at block `22632`, and continued syncing past block `27024`.

## Notes

- UDP is now proven to work in all-modes sync, but it is currently a
  supplemental path. Core TCP still handles most blocks during normal sync.
- Startup already overlaps headers and block syncing once Core has loaded the
  block index and RPC becomes available. Earlier UDP requests should not bypass
  Core reservation/validation gates.
