# Defcoin Core Nu 26.6.4bb Release Notes

## Fast Sync

- Refines the 26.6.4ba early-header reservation fallback so automatic UDP Fast
  Sync can start reserving the next needed block during a clean bootstrap, even
  while the peer's best-known header chain is still below minimum chain work.
- Keeps UDP as a transport choice only. Received blocks are still tracked as
  Core in-flight work and accepted through normal Core validation.
- Intended to unblock Tahoe-to-Lion isolated UDP testing where explicit
  reservation worked but automatic `reserve-next` returned
  `headers-below-minimum-chain-work`.

## Compatibility

- Legacy DefcoinCore 1.0.0 peers remain unaffected because they do not advertise
  the Defcoin Fast Sync service bit and cannot pass UDP transport verification.
- Equivalent logic should be ported to Lion, Catalina, Windows, and server
  builds before comparing Fast Sync behavior across platforms.
