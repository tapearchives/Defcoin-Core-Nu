# init.cpp Agent Notes

## Purpose

Initializes backend runtime options, service flags, networking, wallet loading, and node startup.

## Nu Divergence

- Adds `-defcoinfastsync` to advertise Defcoin Fast Sync service bit 29.
- Adds debug-only Core block-body isolation switches used for UDP Fast Sync and Quick Clone testing.
- Sets `NODE_DEFCOIN_FASTSYNC` in local services only when Fast Sync is enabled by the frontend/service.

## Do Not Break

- Debug switches must stay opt-in and must not alter normal release sync behavior by default.
- Service-bit advertisement means "capable and willing to negotiate"; peers still need UDP probe verification before block transfer.
- Do not add launch behavior that deletes or rewrites wallets, configs, peers, bans, or RPC cookies.

## Verification

- `git diff --check`
- Launch once with normal settings and once with Fast Sync enabled; confirm advertised services and startup logs match expectations.
