# Defcoin Core Nu 26.6.7b Release Notes

26.6.7b is a mining stability and release-packaging cleanup build for the
Tahoe and Windows first-release path.

## Mining Stability

- Miner output is now parsed continuously but UI updates are throttled and the
  visible live log is capped, reducing the chance that high-volume pool output
  overwhelms the QML scene.
- The Mining Monitor follow-tail behavior now tracks the real scroll position
  and keeps the latest lines visible when enabled, while still allowing manual
  scrollback when disabled.
- On Windows, Nu-owned child processes are assigned to a kill-on-close job
  object where the OS allows it. This helps prevent `defcoind.exe`, traceroute
  helpers, or the mining executable from surviving a frontend crash.

## Windows Updates and Packaging

- The Windows release notes and build runbook now treat Velopack as the primary
  public installer/update path.
- NSIS remains documented as a fallback or repair installer only; it does not
  provide the managed Velopack check-for-updates flow.
- The NSIS fallback installer now writes a Nu install marker and refuses
  uninstall cleanup if the recorded install path no longer contains either that
  marker or the Nu application binary.
- Non-Velopack GitHub release fallback now opens the release page for manual
  download instead of auto-downloading and auto-installing a package whose
  checksum is published through the same release channel.

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

## Verification

- Tahoe Qt Quick app rebuilt successfully with the mining changes.
- Tahoe Qt Quick app rebuilt successfully with local secp256k1 linked for paper
  wallet generation.
- Tahoe UI self-test completed successfully after the mining monitor changes.
- Windows Qt Quick app and resources rebuilt successfully from the parity
  source tree.
