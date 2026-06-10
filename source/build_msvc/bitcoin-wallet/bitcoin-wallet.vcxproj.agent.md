# bitcoin-wallet.vcxproj Agent Notes

## Purpose

Builds the Windows wallet maintenance command-line utility.

## Nu Risk

- Touches wallet storage and recovery tooling. Mistakes here can affect user safety.

## Do Not Break

- Keep wallet, crypto, common, and util project references aligned with backend wallet code.
- Do not add behavior that rewrites or deletes wallet data without explicit command semantics.

## Verification

- `git diff --check`
- Windows build; wallet utility smoke test on a disposable test wallet only.
