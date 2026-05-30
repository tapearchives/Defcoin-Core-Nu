# Defcoin Core Nu 26.5.2 Release Notes

Codename: `Core Memories`

Defcoin Core Nu `26.5.2` is a focused Explorer and packaging polish release
for the current Nu desktop line. It keeps the same chain rules, wallet storage
policy, recovery flow, and peer compatibility behavior introduced in `26.5.1`.

## Notable Changes

- Added a prominent Explorer search box for block heights, block hashes,
  transaction IDs, and supported Defcoin Base58 addresses.
- Explorer address handling now recognizes current `D...` addresses, canonical
  `M...` P2SH addresses, legacy `3...` P2SH addresses, and compatibility
  `9...`/`A...` P2SH encodings.
- Transaction detail address links now open Explorer details for wallet
  addresses, not only transaction IDs.
- Nu packages include the Litecoin-equivalent Defcoin command-line tool set:
  `defcoind`, `defcoin-cli`, `defcoin-tx`, and `defcoin-wallet`.

Technical details are maintained in
`doc/defcoin-core-nu-technical-guide.md`.
