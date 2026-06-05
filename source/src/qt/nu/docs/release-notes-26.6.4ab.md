# Defcoin Core Nu 26.6.4ab Release Notes

## Summary

This build fixes the next UDP Fast Sync / Quick Clone receiver failure found in
live Tahoe-to-Lion testing.

## Changes

- UDP Fast Sync now finishes an in-flight transfer cleanly when Core already has
  the requested block height before all late UDP chunks are processed.
- Quick Clone no longer treats that already-have block state as a missing-chunk
  failure or offline LAN source.
- The prior `26.6.4aa` LAN sender fix is retained.

## Diagnosis

After the LAN sender gate was fixed, Tahoe could acknowledge Lion probes and
serve UDP chunks. Lion then reached the next failure: it could report an
accepted or already-known LAN block and still leave the old transfer in-flight,
eventually timing out. The fix is to release the transfer as soon as the
receiver sees that Core has already advanced to the requested height.

## Compatibility

This does not change consensus, wallet storage, service bits, packet format,
or block validation. UDP-delivered blocks are still submitted through Core.
