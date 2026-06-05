# Defcoin Core Nu 26.6.4aa Release Notes

## Summary

This build fixes the remaining LAN UDP Fast Sync gate found during live Tahoe
and Lion testing.

## Changes

- UDP Fast Sync now recognizes private IPv4 peers even when macOS/Qt reports the
  sender through an IPv4-mapped IPv6 socket address.
- LAN discovery invalid-address filtering now applies the same IPv4 rules to
  mapped IPv4 senders.
- Public UDP behavior is unchanged; public senders still need normal Fast Sync
  peer verification.

## Diagnosis

Tahoe `26.6.4z` received Lion UDP packets but still logged:

```text
dropped UDP Fast Sync block request from non-peer - 192.168.0.189:10334
```

The source was an address-classification bug, not a firewall problem. The UDP
listener can receive IPv4 packets on an IPv6 socket, and the private-LAN helper
was checking the socket address family before extracting the embedded IPv4
address.
