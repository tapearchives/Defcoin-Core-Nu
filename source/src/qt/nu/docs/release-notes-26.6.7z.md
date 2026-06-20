# Defcoin Core Nu 26.6.7z Release Notes

Internal Tahoe candidate after `26.6.7y`.

## Highlights

- Updates dc903 bootstrap defaults now that `defcoin.dc903.org` serves normal
  Defcoin Core P2P on the chain default port `1337`.
- Keeps older deployed Nu builds compatible with the live server's temporary
  `10332` listener, but stops hard-coding `:10332` in new seed lists and
  Nu-managed backend launch arguments.

## Compatibility

- Wallet/Core node connections should use `defcoin.dc903.org:1337` or the
  portless `defcoin.dc903.org` default.
- The DNS seed `seed.defcoin.dc903.org` delegates to the live seeder and should
  be used without an explicit port.
- P2Pool operators should use `defcoin.dc903.org:13370` for the P2Pool
  share-network peer port. Miner stratum remains `defcoin.dc903.org:13372`.

## Verification

- Live dc903 services were verified active after the port split.
- `seed.defcoin.dc903.org` answered direct DNS seed queries from the live
  seeder.
- External TCP checks succeeded for Core `1337`, compatibility Core `10332`,
  P2Pool peer `13370`, and stratum/status `13372`.
- Build/package verification is still pending for this candidate.
