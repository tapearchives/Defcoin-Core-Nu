# net.h Agent Notes

## Purpose

Declares networking types, connection manager state, peer objects, local service management, and network configuration APIs.

## Nu Divergence

- Used by Nu peer display and Fast Sync service-bit plumbing, though most structure remains upstream-derived.
- Local-service advertisements ultimately carry `NODE_DEFCOIN_FASTSYNC` when enabled by `init.cpp`.

## Do Not Break

- Avoid adding frontend-specific state to low-level network classes. Keep Nu UI state in the bridge where possible.
- Do not weaken thread-safety annotations or peer lifetime ownership.
- If local-service state changes, audit `init.cpp`, `protocol.*`, `rpc/net.cpp`, and Nu peer service display.

## Verification

- `git diff --check`
- Build `src/defcoind` after structural changes.
