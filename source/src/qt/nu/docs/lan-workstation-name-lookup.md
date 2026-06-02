# LAN Workstation Name Lookup

Nu's Diagnostics > Peers detailed view keeps LAN discovery intentionally
best-effort. The goal is to show a human workstation name when local naming
protocols expose one, not to display low-level neighbor data as though it were
a machine name.

## Display Rules

- The detailed peer table shows one narrow `LAN` marker column.
- `Seed Source / LAN Workstation Name` shows either a seed/source domain or a
  clean LAN workstation name.
- Seed/source domains are right-aligned.
- LAN workstation names are left-aligned.
- Displayed LAN names must not include prefixes such as `Name:`, `Bonjour:`, or
  `LAN:`.
- MAC addresses and OUI/vendor bytes are not displayed as workstation names.

## macOS Lookup Path

The Mac path that finally produced useful Macintosh workstation names was:

1. Browse Bonjour SMB services with `dns-sd -B _smb._tcp local`.
2. Resolve each SMB service with `dns-sd -L <name> _smb._tcp local`.
3. Extract the advertised host from the `can be reached at` line.
4. Resolve that host with `dscacheutil -q host -a name <host>`.
5. Match the returned IPv4 or IPv6 address to the peer IP.
6. Use the Bonjour service name as the workstation name.

This avoids treating provider reverse-DNS strings or synthetic IPv6 reverse
names as workstation names.

## Windows IPv6 Caveat

On macOS, a Windows 11 peer reachable only by IPv6 may still show no workstation
name if it does not advertise a usable name through Bonjour/mDNS, local DNS, or
SMB/NetBIOS lookup tools. The neighbor table can expose a MAC address such as
`00:e0:4c:...`, but that is not a workstation name and should be suppressed.

If a future pass needs stronger Windows naming, add a dedicated LLMNR/NBNS/WS-D
probe helper and keep the result bounded, LAN-only, and display-clean.
