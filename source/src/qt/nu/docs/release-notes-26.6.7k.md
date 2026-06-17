# Defcoin Core Nu 26.6.7k Release Notes

Internal Tahoe candidate focused on paper-wallet key-generation security review
and BIP38 hardening.

## Changed

- Paper-wallet and recovery secret bytes now prefer OpenSSL `RAND_priv_bytes()`
  when available, using the private-key DRBG instead of the general public-byte
  path.
- BIP38 paper-wallet encryption now requires a passphrase of at least 12
  characters in both the QML view and the C++ service.
- BIP38 passphrases are cleared from the QML view state after a generation
  attempt.
- Added `crypto-key-generation-audit-26.6.7k.md`, cataloging the crypto
  algorithms, encodings, Brainflayer threat model, hardening decisions, and
  residual recommendations.

## Notes

- Normal wallet private keys continue to use the inherited Core path:
  `GetStrongRandBytes()` plus libsecp256k1 secret-key validation.
- Nu paper-wallet keys are not brainwallets. User entropy is mixed with system
  cryptographic randomness and is not the sole key source.
- BIP38 passphrase strength remains user-dependent; this build blocks trivial
  short passphrases but does not yet include a full password-strength meter.

## Verification

- Configured Tahoe Apple Silicon candidate with Qt 6.11.1 and OpenSSL 3.6.2.
- Built `build/nu-qml-arm64-26.6.7k` successfully.
- `git diff --check` passed for the edited files.
- `codesign --verify --deep --strict --verbose=2` passed for the built app.
- `qmllint` completed with the existing standalone-context warnings for
  injected `NuService` and delegate IDs; no syntax errors were introduced.
