# protocol.h Agent Notes

## Purpose

Defines P2P service bits, message inventory constants, protocol limits, and message type declarations.

## Nu Divergence

- Allocates `NODE_DEFCOIN_FASTSYNC` at bit 29 for Defcoin Nu UDP Fast Sync capability advertisement.
- Documents that the bit is an unauthenticated candidate signal, not proof that UDP is currently reachable.

## Do Not Break

- Do not move bit 29 without updating Nu, Lion, Windows/server builds, service-bit hover text, and protocol docs.
- Do not treat `NODE_DEFCOIN_FASTSYNC` as permission to skip probing, checksums, Core reservation, or validation.
- Keep normal Litecoin/Bitcoin service bits intact, including `NODE_BLOOM`, `NODE_WITNESS`, and MWEB-related bits even when Defcoin does not use every upstream feature.

## Verification

- `git diff --check`
- Confirm `serviceFlagsToStr` in `protocol.cpp` and the Nu peer hover text still name the service bit correctly.
