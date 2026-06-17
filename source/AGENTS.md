# Defcoin Core Nu Source DOX

## Purpose

This repository is the git-backed Tahoe source of truth for Defcoin Core Nu
backend, modern Nu frontend, shared protocol docs, and Windows build staging.

## Ownership

- `src/` owns backend, wallet, validation, RPC, P2P networking, and Qt source.
- `src/qt/nu/` owns the modern Nu app, QML, assets, docs, and helper tools.
- `build_msvc/` owns Windows Visual Studio project metadata for the classic
  backend/project graph.
- Generated build directories and release artifacts must stay outside source
  history unless explicitly documented.

## Local Contracts

- Preserve wallet data and secrets. Source/build work must not delete wallets,
  keys, configs, peers, bans, RPC cookies, or address books.
- Version constants, CMake release names, package labels, user agents, and
  release notes must follow `src/qt/nu/docs/defcoin-core-versioning.md`.
- Keep Tahoe, Lion, and Windows protocol behavior in parity unless a platform
  limitation is documented in the matching release notes.
- Apply Nu-local formatting only to Nu-owned code. Do not reformat inherited
  Litecoin/Core files outside the documented Nu/custom scopes.
- If a file has a sibling `[full filename].agent.md`, read it before editing
  that file and update it when durable behavior changes.

## Work Guidance

- Treat this tree as source of truth; generated Windows staging trees should be
  refreshed from here before release builds.
- Prefer small auditable changes around consensus, wallet, and P2P behavior.
- Keep cross-platform changes documented in `src/qt/nu/docs/` so Lion,
  Catalina, and Windows ports can follow them.

## Verification

- `git diff --check`
- `pre-commit run --all-files` for Nu Python, Nu C++ style dry-run, and MSVC
  XML syntax checks.
- Build the affected platform artifacts before release packaging.

## Child DOX Index

- `src/AGENTS.md` - backend, wallet, validation, RPC, P2P networking, and Qt
  source contracts.
- `build_msvc/AGENTS.md` - Windows Visual Studio/MSBuild project metadata.
