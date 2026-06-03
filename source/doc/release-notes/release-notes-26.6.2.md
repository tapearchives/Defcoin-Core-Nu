# Defcoin Core Nu 26.6.2 Release Notes

Defcoin Core Nu `26.6.2` is a diagnostics and Fast Sync polish release over the
`26.6.1` letter builds. The inherited Core client build number remains tied to
the Litecoin-derived backend lineage.

## Fast Sync

- Public UDP Fast Sync is now separated from LAN discovery permission. A peer
  must advertise `NODE_DEFCOIN_FASTSYNC` before Nu sends UDP block-data requests
  to it.
- LAN discovery can still help identify nearby workstations and peers, but it no
  longer makes a local/private host eligible for UDP block data by itself.
- The Fast Sync protocol notes now define supported, enabled, and verified peer
  states so OS local-network or firewall prompts do not get confused with public
  Fast Sync availability.

## Diagnostics

- Removed the separate detailed Peers `LAN` column.
- LAN peers now show the local-network icon inline before the workstation/source
  name in `Seed Source / LAN Workstation Name`.
- The LAN workstation/source cell now has a tooltip describing the discovered
  LAN identity and likely discovery source, such as Bonjour, SMB/NetBIOS, local
  DNS, or host-name probing.

## Wording

- Splash, About, and Help wording now say the backend derives from Litecoin Core
  v0.21.5.5 with Defcoin parameters.
