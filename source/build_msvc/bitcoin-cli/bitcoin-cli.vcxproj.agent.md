# bitcoin-cli.vcxproj Agent Notes

## Purpose

Builds the Windows command-line RPC client.

## Nu Risk

- Must remain compatible with Defcoin RPC names and backend binaries used by Nu support workflows.

## Do Not Break

- Keep project references aligned with the backend libraries used by `bitcoind`.
- Do not add Qt dependencies to this CLI target.

## Verification

- `git diff --check`
- Windows build; smoke-test a simple RPC such as `getnetworkinfo` when available.
