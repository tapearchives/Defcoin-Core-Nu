# Defcoin Core Nu 26.6.4ao Internal Notes

This build tightens the debug launch mode used to isolate UDP Fast Sync.

## Changes

- `--debug-disable-core-tcp-sync` / `DEFCOIN_NU_DEBUG_DISABLE_CORE_TCP_SYNC=1`
  now disables only Core's TCP block-body fetch path, not peer/header
  negotiation.
- When that switch is active, the Fast Sync selector stops allocating any
  Core/TCP quota and uses UDP-only probing/reservation attempts.
- The legacy `--debug-disable-core-sync` / `DEFCOIN_NU_DEBUG_DISABLE_CORE_SYNC`
  alias remains accepted, but now follows the same TCP-block-only behavior.
- Tahoe and Lion carry the same selector rule so live UDP tests compare the
  same protocol behavior on both platforms.

## Test Intent

Use this mode only to prove UDP Fast Sync transport without Core TCP block-body
fetches competing. Full Core sync shutdown remains a Quick Clone / DCOL test
case only.
