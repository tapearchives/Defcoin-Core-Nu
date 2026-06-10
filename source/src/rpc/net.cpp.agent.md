# net.cpp RPC Agent Notes

## Purpose

Implements networking RPCs, including Nu's Fast Sync block-reservation RPC.

## Nu Divergence

- Adds `reservefastsyncblock` with `reserve`, `reserve-next`, `release`, `transport-verified`, and `transport-unverified` actions.
- Accepts numeric node IDs as strings for Qt/front-end callers that stringify hidden RPC parameters.
- Uses backend reservation helpers so UDP and TCP remain two transports for one Core-selected peer/block path.

## Do Not Break

- Do not let this RPC bypass Core in-flight state or consensus validation.
- Keep error/reason strings stable when possible; Nu status rows and logs use them for user-facing diagnostics.
- Keep P2P-disabled and invalid-parameter errors explicit so the frontend can distinguish backend mismatch from transport failure.

## Verification

- `git diff --check`
- Smoke-test `reservefastsyncblock "transport-verified" <nodeid>`, `reserve-next`, and `release` against a connected Nu peer when available.
