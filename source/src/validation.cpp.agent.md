# validation.cpp Agent Notes

## Purpose

Owns block and chain validation, active chainstate updates, block index state, and acceptance/rejection of submitted blocks.

## Nu Divergence

- Nu Fast Sync intentionally does not add a validation bypass here. UDP-delivered blocks must arrive through normal submission and acceptance paths.
- Quick Clone/DCOL trusted-copy planning must not modify this file to silently accept unvalidated live network data.

## Do Not Break

- Do not special-case Fast Sync blocks as valid because they arrived over UDP or LAN.
- Do not mix Quick Clone trusted snapshot installation with normal P2P block validation unless the user explicitly approves a separate trusted-copy workflow.
- Keep denial-of-service, script-check, and chainstate consistency checks intact.

## Verification

- `git diff --check`
- Run focused validation tests or a clean sync smoke test after any functional edit.
