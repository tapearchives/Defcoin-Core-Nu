# Core Backend Source DOX

## Purpose

This folder owns the Litecoin-derived backend source used by Defcoin Core Nu: P2P networking, validation, wallet storage, RPC, chain parameters, cryptography, tests, and Qt integration.

## Ownership

- Consensus, validation, chainstate, wallet signing, and peer scheduling remain backend-owned.
- Nu-specific UDP Fast Sync and Quick Clone hooks must stay transport/orchestration boundaries, not alternate consensus paths.
- Companion files named `[full filename].agent.md` identify high-risk Nu divergence from upstream Litecoin/standard Defcoin.

## Local Contracts

- Do not bypass normal block validation in Fast Sync. UDP may deliver bytes, but Core must still reserve, submit, and accept/reject blocks.
- Service-bit advertisements are untrusted. Any `NODE_DEFCOIN_FASTSYNC` peer must still prove UDP return-path capability before use.
- Debug-only launch switches must not become default behavior.
- Do not change wallet storage, encryption, or deletion behavior without explicit user request and verification.

## Work Guidance

- Before editing any file with a sibling `[full filename].agent.md`, read the companion.
- Prefer small, auditable hooks over duplicating Core scheduling or validation logic.
- Keep protocol changes reflected in Nu protocol docs and Lion/Windows handoff notes.

## Verification

- `git diff --check`
- Backend changes should compile at least the focused Core targets when feasible.
- Protocol or RPC changes require matching Nu bridge/UI checks when the app path consumes them.

## Child DOX Index

- `qt/nu/AGENTS.md` - Nu Qt/QML app, bridge, docs, and tools.
- `rpc/` - RPC implementations, including Nu Fast Sync reservation hooks.
- `wallet/` - wallet storage, signing, encryption, and address management.
- `crypto/`, `consensus/`, `script/`, `validation.cpp` - consensus and validation-adjacent implementation.
- `net.cpp`, `net.h`, `net_processing.cpp`, `net_processing.h`, `protocol.*` - P2P networking, service bits, peer/block scheduling, and Fast Sync hooks.
