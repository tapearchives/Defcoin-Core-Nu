# Windows MSVC Build DOX

## Purpose

This folder owns the Windows Visual Studio/MSBuild project graph for the Litecoin-derived Defcoin Core Nu backend and classic Qt wallet build.

## Ownership

- `.vcxproj` files define executable/static-library build units and project references.
- `common*.vcxproj` files define shared compiler/linker/output conventions.
- `msbuild/tasks/*.targets` define custom helper tasks used by the project graph.

## Local Contracts

- Read sibling `[full filename].agent.md` before editing any `.vcxproj` or `.targets` file.
- Do not silently change project references, output folder layout, generated Qt paths, toolset version, or crypto/consensus source membership.
- Nu QML app packaging is separate from these classic MSVC projects unless explicitly added and documented.

## Work Guidance

- Keep XML formatting stable and minimize churn.
- If changing one project reference, inspect dependent executable/test projects.
- Keep Windows changes in parity with the Tahoe source tree and document any Windows-only exception.

## Verification

- `git diff --check`
- Windows project edits should be followed by a Windows build or documented as not run.

## Child DOX Index

- `bitcoin-cli/`, `bitcoin-qt/`, `bitcoin-tx/`, `bitcoin-wallet/`, `bitcoind/` - executable project files.
- `libbitcoin_qt/`, `libbitcoinconsensus/`, `libleveldb/`, `libsecp256k1/`, `libunivalue/` - library project files.
- `test_bitcoin/`, `test_bitcoin-qt/`, `testconsensus/` - test project files.
- `msbuild/tasks/` - custom MSBuild targets.
