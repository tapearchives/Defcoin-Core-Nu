# NuRpcService.h Agent Notes

## Purpose

Declares the Nu frontend service API exposed to QML, including properties, invokable wallet/RPC/network actions, timers, metrics state, and Fast Sync/Quick Clone counters.

## Nu Divergence

- Exposes traffic totals split into TCP, UDP, total, and Quick Clone subset counters.
- Exposes Metrics rows, peer data, Quick Clone settings/status, paper wallet/watch-only actions, and Fast Sync diagnostic state to QML.

## Do Not Break

- QML property names are part of the frontend contract. Rename only with synchronized QML changes.
- Keep Quick Clone counters clearly subordinate to UDP totals to avoid double-counted graphs.
- Keep signal emissions paired with property changes (`trafficChanged`, `stateChanged`, `settingsChanged`) or QML will show stale data.

## Verification

- `git diff --check`
- Build Nu frontend after property or signal changes.
- Open Metrics and any touched wallet view to confirm bindings update.
