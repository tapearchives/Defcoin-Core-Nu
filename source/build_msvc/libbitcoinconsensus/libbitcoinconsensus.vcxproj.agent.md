# libbitcoinconsensus.vcxproj Agent Notes

## Purpose

Builds the Windows consensus static library.

## Nu Risk

- Includes cryptographic and consensus source membership, including SHA256 implementation files.
- Consensus library membership must stay deterministic across Windows and macOS builds.

## Do Not Break

- Do not remove or swap crypto/consensus files without cross-platform validation tests.
- Architecture-specific crypto changes need functional equivalence and benchmark evidence before becoming default.

## Verification

- `git diff --check`
- Windows consensus build and consensus test target when available.
