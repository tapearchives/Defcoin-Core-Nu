# Defcoin Core Nu 26.6.4u Release Notes

## Summary

This build adds the first user-facing Quick Clone/DCOL controls while keeping
the risky snapshot replacement path gated behind future manifest verification.
Quick Clone is now the visible trusted-LAN chain-copy name. DCOL / Direct Copy
Over LAN remains the technical name in documentation and hover text.

## Changes

- Added a Quick Clone card to Settings > Connectivity.
- Added manual actions for Sync using Quick Clone now and Validate existing
  blockchain.
- Added Automatically validate blocks after Quick Clone.
- Added a one-per-cycle Quick Clone prompt path for future manifest-ready LAN
  sources when the local chain is more than 5% behind.
- Added Core `verifychain 4 0` integration for validating existing public chain
  data without touching wallet files.
- Renamed visible LAN Fast Copy wording to Quick Clone.
- Added LAN beacon fields for future immutable Quick Clone snapshot
  advertisements. Current nodes explicitly advertise snapshot status as
  not-prepared until manifest exports exist.

## Safety Boundary

Quick Clone copies public blockchain data only. It must never copy wallets,
private keys, passphrases, configuration, address books, peers, bans, or RPC
cookies. Final replacement of `blocks`, `chainstate`, or `indexes` remains
blocked until a source advertises an immutable manifest and the receiver verifies
the manifest before swapping public chain folders.

## Verification

- `git diff --check` passed.
- Apple Silicon `DefcoinCoreNu` built from `build/nu-qml-arm64-26.6.4u`.
- Bundle metadata reports `26.6.4u`.
- QML lint found no new syntax errors; existing context-property warnings
  remain.
