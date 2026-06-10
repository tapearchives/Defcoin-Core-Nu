# test_bitcoin.vcxproj Agent Notes

## Purpose

Builds the Windows backend unit test executable.

## Nu Risk

- Should include backend test coverage for consensus, wallet, RPC, networking, and any Nu-specific backend hooks that gain tests.

## Do Not Break

- Keep test project references aligned with the libraries under test.
- Add tests here when backend Fast Sync reservation or service-bit behavior changes materially.

## Verification

- `git diff --check`
- Windows test build and `test_bitcoin` run when available.
