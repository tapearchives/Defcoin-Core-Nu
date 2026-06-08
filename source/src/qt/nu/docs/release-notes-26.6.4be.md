# Defcoin Core Nu 26.6.4be

This build is a parity and build-refresh update.

- Updates Tahoe to `26.6.4be`.
- Updates the Lion compatibility build to `26.6.4be-Lion-alpha`.
- Refreshes the physical Lion iMac source from the latest UTM Lion source.
- Aligns Lion Metrics > Peers transport wording with Tahoe by using `Methods`
  for the TCP/UDP observed-transport column.
- Rechecks Fast Sync and Quick Clone invariants across Tahoe and Lion source:
  service bit 29, UDP capability string, debug sync switches, and Core block
  reservation RPC behavior remain aligned.

No UDP wire-format, service-bit, wallet, consensus, or Quick Clone protocol
semantics were changed in this build.
