# bitcoind.vcxproj Agent Notes

## Purpose

Builds the Windows Defcoin backend daemon.

## Nu Risk

- This target must include network, validation, wallet, RPC, and Fast Sync reservation code used by Nu and server builds.

## Do Not Break

- Keep references to server, wallet, consensus, crypto, util, ZMQ, LevelDB, secp256k1, and UniValue projects complete.
- Fast Sync service-bit and `reservefastsyncblock` code must be present in this target when Windows parity is required.

## Verification

- `git diff --check`
- Windows daemon build; smoke-test startup and `getnetworkinfo`.
