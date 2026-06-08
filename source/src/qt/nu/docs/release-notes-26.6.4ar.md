# Defcoin Core Nu 26.6.4ar

## Summary

This build fixes two issues found during Tahoe-to-Lion Fast Sync testing.

## Changes

- Sync progress no longer rounds to `100%` while the node is still behind the
  known header tip. The sync dialog now remains honest until `blocks == headers`
  and then closes through the existing caught-up path.
- UDP Fast Sync target selection no longer rejects a peer before the safe probe
  stage just because the endpoint address looks public.
- Peers that ACK a UDP Fast Sync probe are now treated as proven UDP targets for
  packet-size selection. This matters for UTM/LAN setups where Core exposes the
  peer as a globally routed IPv6 address even though the UDP route is local.

## Port Notes

- Lion must port the same selector behavior. It already had a helper for
  `private/local/proven` targets; this build uses it consistently in selector
  scoring and datagram-size selection.
- Tahoe now has the same helper in `NuRpcService`.
- When testing Fast Sync only, keep using:
  `--debug-disable-core-tcp-sync --debug-disable-quick-clone`

## Test Target

- Launch Tahoe and Lion with Core TCP block copy disabled, not full Core P2P
  disabled.
- Confirm the receiver sends UDP probes to the Tahoe peer and records probe ACKs.
- Confirm the receiver can move from probe ACK to block reservation and UDP
  block chunk receipt.
