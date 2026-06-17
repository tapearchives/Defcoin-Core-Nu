# Defcoin Core Nu 26.6.7c Release Notes

26.6.7c is a Tahoe candidate build focused on paper-wallet safety, CSV export
hardening, and update/install trust boundaries.

## Paper Wallet and Security Hardening

- Paper wallet address derivation now stays local to Nu using Core-compatible
  secp256k1, SHA256, RIPEMD160, and Base58Check code. Generated WIF/private-key
  material is no longer sent through RPC descriptor commands.
- Paper wallet QR images are generated as in-memory data URLs instead of
  deterministic temp files.
- After generating a paper wallet, Nu offers to print a one-page foldable
  Defcoin paper-wallet sheet with public/private QR codes and Defcoin branding.
- Nu refuses non-loopback RPC targets by default unless the operator explicitly
  sets `DEFCOIN_NU_ALLOW_REMOTE_RPC=1`.
- CSV exports now neutralize spreadsheet formula prefixes before quoting fields.
- RPC Console output redacts sensitive return values from private-key dump style
  commands.

## Windows Updates and Packaging

- Non-Velopack GitHub release fallback now opens the release page for manual
  download instead of auto-downloading and auto-installing a package whose
  checksum is published through the same release channel.
- The NSIS fallback installer now writes a Nu install marker and refuses
  uninstall cleanup if the recorded install path no longer contains either that
  marker or the Nu application binary.

## Verification

- Tahoe Qt Quick app rebuilt successfully with local secp256k1 linked for paper
  wallet generation.
