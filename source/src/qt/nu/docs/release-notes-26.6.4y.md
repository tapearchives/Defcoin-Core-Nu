# Defcoin Core Nu 26.6.4y Release Notes

## Summary

This build fixes the live LAN Fast Sync / Quick Clone failure where Tahoe would
answer Lion's UDP probes but then refuse the follow-up block requests as
`non-peer`.

## Changes

- Quick Clone `request-block` packets now pass the outer UDP dispatcher when
  they are marked `clone_mode` and come from a trusted private/LAN address.
- Quick Clone `block-chunk` packets now reach the normal Quick Clone chunk
  handler instead of being dropped by the outer dispatcher before the handler
  can apply its trusted-LAN rule.
- A valid UDP Fast Sync probe from a private/LAN address is now admitted as a
  provisional LAN Fast Sync peer before the probe acknowledgement is sent. This
  keeps the acknowledgement and the following block request in agreement.

## Diagnosis

Tahoe's log showed repeated lines like:

```text
dropped UDP Fast Sync block request from non-peer - 192.168.0.189:10334
```

That proved UDP packets were reaching Tahoe. The issue was not the macOS LAN
permission prompt or firewall; the source-side dispatcher was rejecting the
request before the block-serving handler ran.

## Safety Boundary

The provisional peer admission is limited to private/LAN addresses and only
serves public block data. Wallet files, private keys, configs, peers, bans, and
RPC credentials are not exposed or copied.
