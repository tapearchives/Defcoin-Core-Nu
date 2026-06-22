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
- A new Tahoe build must follow `source/src/qt/nu/docs/defcoin-core-versioning.md` and update release/change notes. Public releases use strict `Epoch.Feature.Patch`; suffixes are candidate/staging labels unless explicitly promoted.
- Nu GitHub-facing README, release, and marketing materials must not preview
  sibling or upcoming products with screenshots, logos, download rows, or hype
  copy unless the user explicitly requests that product reveal. Keep each
  product page focused on that product.

## Work Guidance

- Prefer established Litecoin/Bitcoin Core patterns for backend changes.
- For QML UI changes, keep Tahoe presentation aligned with Lion where possible and avoid adding dependencies Lion cannot share unless documented.
- For UDP/LAN tests, treat the macOS Local Network Allow prompt as a hard gate before drawing conclusions.
- If a source or project file has a sibling `[full filename].agent.md`, read it before editing that file. Use companion docs only for files with meaningful Nu divergence, fragile platform behavior, or cross-build risk.

## Verification

- `git diff --check`
- Build focused backend targets when backend code changes: `make -j6 src/defcoind src/defcoin-cli src/defcoin-tx src/defcoin-wallet`
- Build Nu frontend with the documented CMake workflow under `source/src/qt/nu/docs/`.
- Smoke-test the touched UI or protocol path when launch access is available.

## Child DOX Index

- `source/AGENTS.md` - source-root contracts for backend, Nu frontend, Windows staging, and generated build boundaries.
- `scripts/`, `build/`, `.github/` - build helpers and generated/local tooling governed by this doc.
