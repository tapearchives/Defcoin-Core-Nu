# bitcoin-tx.vcxproj Agent Notes

## Purpose

Builds the Windows raw transaction utility.

## Nu Risk

- Used for transaction-format compatibility checks; should not inherit wallet/UI dependencies.

## Do Not Break

- Keep dependencies limited to common, consensus, crypto, script, and utility libraries needed for transaction manipulation.
- Preserve command-line utility behavior independent of Nu frontend changes.

## Verification

- `git diff --check`
- Windows build; smoke-test a basic transaction utility command when available.
