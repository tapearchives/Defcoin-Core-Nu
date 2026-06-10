# protocol.cpp Agent Notes

## Purpose

Implements P2P message metadata, service-bit string formatting, and desirable-service selection.

## Nu Divergence

- Defcoin mainnet preserves the historical pre-SegWit chain, so `GetDesirableServiceFlags` avoids forcing Litecoin witness/MWEB bits for peer selection.
- `serviceFlagToStr` maps bit 29 to `DEFCOIN_FASTSYNC` for diagnostics and peer service display.

## Do Not Break

- Keep `protocol.h` and `protocol.cpp` service-bit names in sync.
- Do not make Defcoin peer selection require Litecoin-only service bits unless the chain/network rules change deliberately.
- Unknown service bits must remain printable as `UNKNOWN[...]`; users rely on peer hover text to understand advertised services.

## Verification

- `git diff --check`
- Check the Metrics > Peers Services hover text after service-bit edits.
