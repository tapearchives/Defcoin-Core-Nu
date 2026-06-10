# libsecp256k1.vcxproj Agent Notes

## Purpose

Builds secp256k1 cryptography for Windows signing and validation.

## Nu Risk

- Cryptography source and compiler flag changes can affect consensus and wallet signing safety.

## Do Not Break

- Do not change enabled modules, source membership, or optimization flags without crypto test coverage.
- Keep behavior aligned with macOS/Linux builds.

## Verification

- `git diff --check`
- Windows build and secp256k1/consensus tests when available.
