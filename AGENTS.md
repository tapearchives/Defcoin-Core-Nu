# Tahoe Nu Source DOX

## Purpose

This git tree is the current Tahoe / Apple Silicon Defcoin Core Nu source, based on Litecoin Core with Defcoin parameters and Nu-specific UI, sync, metrics, packaging, and wallet work.

## Ownership

- `source/` contains the active backend and frontend source.
- `source/src/qt/nu/` owns the QML app, Nu bridge, local tools, assets, and Nu docs.
- `scripts/` and build folders support local build/package workflows.

## Local Contracts

- Keep consensus, validation, wallet signing, and chainstate behavior inside the backend's normal trust boundaries.
- Fast Sync and Quick Clone changes must keep transport/orchestration separate from consensus validation unless the user explicitly approves a trusted-copy mode.
- Quick Clone is trusted LAN public-chain data only. It must never copy wallets, keys, configs, peers, bans, RPC cookies, or address books.
- Close existing Nu frontend/backend instances before launch tests or rebuilds.
- A new Tahoe build must use the current versioning rule and update release/change notes.

## Work Guidance

- Prefer established Litecoin/Bitcoin Core patterns for backend changes.
- For QML UI changes, keep Tahoe presentation aligned with Lion where possible and avoid adding dependencies Lion cannot share unless documented.
- For UDP/LAN tests, treat the macOS Local Network Allow prompt as a hard gate before drawing conclusions.

## Verification

- `git diff --check`
- Build focused backend targets when backend code changes: `make -j6 src/defcoind src/defcoin-cli src/defcoin-tx src/defcoin-wallet`
- Build Nu frontend with the documented CMake workflow under `source/src/qt/nu/docs/`.
- Smoke-test the touched UI or protocol path when launch access is available.

## Child DOX Index

- `source/src/qt/nu/AGENTS.md` - Nu Qt/QML frontend, bridge, local docs, tools, and assets.
- `source/src/` - backend and consensus-adjacent source, governed by this doc unless a deeper AGENTS.md is added.
- `scripts/`, `build/`, `.github/` - build helpers and generated/local tooling governed by this doc.
