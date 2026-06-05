# Defcoin Core Nu 26.6.4z Release Notes

## Summary

This build completes the Tahoe-side LAN UDP Fast Sync fix after live testing
showed that Lion's follow-up block requests were still being rejected when the
packet did not carry `clone_mode`.

## Changes

- Private/LAN UDP `request-block` packets now reach the guarded block-serving
  handler even when they are not marked as Quick Clone packets.
- Private/LAN UDP `block-chunk` packets now reach the guarded chunk handler so
  an in-flight request can validate request id, height, checksums, and block
  hash before accepting data.
- Public internet UDP senders still require the existing Fast Sync peer
  verification path before request or chunk packets are accepted.

## Diagnosis

The `26.6.4y` fix handled Quick Clone packets marked with `clone_mode`, but the
Lion build was sending LAN UDP block requests without that flag. Tahoe therefore
continued to log:

```text
dropped UDP Fast Sync block request from non-peer - 192.168.0.189:10334
```

The new gate treats private/LAN block transport as eligible for the same public
block-serving handler. Wallet data is not exposed.

