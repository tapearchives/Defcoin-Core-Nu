# Defcoin Core Nu 26.6.4ad Release Notes

## Summary

This build fixes the Quick Clone case where Lion could receive a UDP block and
then report that Core already had it.

## Changes

- Quick Clone now asks Core to reserve the next missing block before requesting
  that block over UDP.
- Quick Clone no longer guesses the next block from the GUI's cached
  `current height + 1` value.
- If a UDP block arrives after Core already accepted that same block through
  normal sync, Quick Clone skips it and immediately reserves the next missing
  block instead of presenting it as useful progress.
- Quick Clone will not start multiple Core reservation calls at once.

## Diagnosis

Normal Fast Sync already used Core's block-reservation path, but Quick Clone's
temporary block-copy scaffolding was still requesting `m_block_height + 1`
directly. That GUI-side height can lag the backend while normal TCP sync is
active. The result was a stale UDP request: by the time the UDP block arrived,
Core had sometimes already accepted the same height through normal sync.

## Compatibility

This does not change consensus, wallet storage, service bits, packet format,
checksum behavior, or block validation. UDP still only transports a block body
and Core still decides whether the block is accepted.

