# Defcoin Core Nu 26.6.7k Crypto and Key-Generation Audit

Date: 2026-06-16

## Executive Summary

Defcoin Core Nu's normal wallet keys use the inherited Core key path:
`CKey::MakeNewKey()` fills 32 bytes with `GetStrongRandBytes()` and retries until
`secp256k1_ec_seckey_verify()` accepts the value. That is the correct model for
modern wallet private-key generation.

The Nu paper-wallet generator is also not a brainwallet: it does not derive a
private key directly from user text. It mixes local user entropy with system
cryptographic randomness, domain-separated SHA512 rounds, validates the final
32-byte value against the secp256k1 order, and fails closed if local secp256k1 or
OpenSSL crypto support is unavailable.

The main Brainflayer-relevant weakness is optional BIP38 passphrase choice.
Brainflayer-style attacks are effective against human-chosen secrets and weak
passphrases, not against uniform 256-bit CSPRNG keys. Nu 26.6.7k therefore:

- uses OpenSSL `RAND_priv_bytes()` for paper-wallet/recovery private material
  when OpenSSL exposes the private-key DRBG, falling back to `RAND_bytes()` only
  for older OpenSSL compatibility;
- requires a minimum 12-character BIP38 passphrase in both QML and C++;
- clears the QML BIP38 passphrase field after the generation attempt;
- keeps generated WIF/BIP38 strings and QR images in memory only until the user
  clears the paper-wallet session or leaves the Paper Wallet tab.

## Brainflayer Attack Model

`brainflayer` is a high-speed brainwallet/passphrase auditing tool. Its practical
threat is candidate generation: a user chooses a guessable phrase, the attacker
derives keys from many candidate phrases, and matching addresses are found
quickly using optimized secp256k1/address code and filters.

Assessment for Nu:

- Normal Core keys: not exposed to this class of attack because keys are
  generated from Core's RNG, not phrases.
- Paper-wallet keys: not exposed if the system RNG is healthy, because user
  entropy is mixed with CSPRNG output and is not the sole key source.
- BIP38 encrypted paper wallets: passphrase strength remains user-dependent.
  Scrypt slows guessing, but a short or common passphrase is still the most
  realistic cracking path. The minimum-length gate reduces accidental trivial
  passphrases; a future passphrase-strength meter would be better.
- BIP39 recovery phrases: 12-word generated phrases contain 128 bits of entropy
  plus checksum. This is acceptable for compatibility, but a future 24-word
  generation option would be stronger for high-value workflows.

## Algorithm and Encoding Catalog

| Area | Current Nu/Core Use | Library/Code Path | Security Status |
| --- | --- | --- | --- |
| Private key generation | 32-byte secp256k1 secret | Core `GetStrongRandBytes()` + `secp256k1_ec_seckey_verify()`; Nu paper wallet uses OpenSSL private DRBG when available | Strong when OS/OpenSSL RNG is healthy |
| Public key/address derivation | Compressed secp256k1 pubkey, HASH160, Base58Check | local `libsecp256k1`, `CRIPEMD160`, double SHA256 checksum | Protocol-compatible and correct |
| BIP38 paper-wallet encryption | non-EC-multiply compressed-key mode | OpenSSL `EVP_PBE_scrypt()` + AES-256-ECB per BIP38 payload format | Correct; passphrase strength is user-dependent |
| BIP39 phrase validation | wordlist checksum validation | local BIP39 wordlist, SHA256 checksum | Correct for compatibility |
| BIP39 seed derivation | PBKDF2-HMAC-SHA512, 2048 rounds, salt `mnemonic` | Nu local HMAC/PBKDF2 implementation over Qt SHA512 | Correct; future cleanup should use a vetted library call where cross-platform compatible |
| BIP32 master material | HMAC-SHA512 key `Bitcoin seed` | Nu local HMAC-SHA512 implementation | Correct BIP32 semantics; future cleanup should use library HMAC |
| Transaction/block hashing | SHA256/double SHA256, scrypt proof-of-work where inherited | inherited Core/Litecoin/Defcoin backend | Protocol-defined; do not replace without consensus planning |
| Checksums/encodings | Base58Check, QR payloads, UDP block checksums | Core/Nu local code, libqrencode | Encoding/checksum only, not secret-bearing cryptography |

## Current Hardening Changes

1. `systemRandomBytes()` now prefers `RAND_priv_bytes()` on OpenSSL 1.1.1+.
   OpenSSL documents that private bytes are intended for private-key material.
2. BIP38 generation now rejects passphrases shorter than 12 trimmed characters
   in the backend even if QML is bypassed.
3. Paper Wallet QML now disables `Generate Wallet Sheet` until the BIP38
   passphrase meets the same minimum.
4. After a BIP38 generation attempt, the visible QML passphrase property is
   cleared so it does not sit in the UI state longer than necessary.

## Residual Risks and Recommendations

- Add a passphrase-strength meter for BIP38 that rejects dictionary words,
  repeated characters, and known leaked/common passwords. Length alone is not
  enough.
- Consider a 24-word BIP39 generation option. Keep 12 words for compatibility
  with older phrase-based wallets and user workflows.
- Replace Nu's local HMAC/PBKDF2 helper with OpenSSL or Core crypto wrappers if
  a clean Tahoe/Lion/Windows-compatible wrapper can be introduced without
  destabilizing recovery behavior.
- Keep paper-wallet private keys out of files, settings, logs, temp images, and
  external URLs. Review any future preview/export feature against this rule.
- Document for users that printing to cloud printers, saving PDFs, screenshots,
  or clipboard copies can defeat the purpose of a paper wallet.
- Keep Core consensus/hash algorithms unchanged unless a hard-fork or network
  upgrade is planned and announced.

## Reference Sources

- Brainflayer: https://github.com/ryancdotorg/brainflayer
- OpenSSL RAND bytes: https://docs.openssl.org/3.0/man3/RAND_bytes/
- Bitcoin BIP38: https://github.com/bitcoin/bips/blob/master/bip-0038.mediawiki
- Bitcoin BIP39: https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki
- libsecp256k1: https://github.com/bitcoin-core/secp256k1
