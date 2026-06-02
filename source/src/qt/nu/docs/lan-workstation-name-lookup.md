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

## Windows IPv6 Bridge

A Windows peer can arrive in `getpeerinfo` as an IPv6 address while its useful
workstation name is exposed only by SMB/NetBIOS over IPv4. The macOS bridge is:

1. Use `ndp -an` to map the peer IPv6 address to a neighbor MAC.
2. Use `arp -an` to find an IPv4 address with the same MAC.
3. Run `smbutil status -ae <ipv4>` against that IPv4 address.
4. Prefer the `0x00 UNIQUE [Workstation Service]` name over generic service or
   domain names.

This fixed the local node-27 case:

- Peer IPv6: `2603:808c:f40:200::70`
- Neighbor MAC: `00:e0:4c:68:01:44`
- Matching IPv4: `192.168.3.69`
- SMB workstation name: `WHISPER`

The neighbor MAC is useful only as a lookup bridge. It must not be displayed as
the workstation name.

If a future pass needs stronger Windows naming, add a dedicated LLMNR/NBNS/WS-D
probe helper and keep the result bounded, LAN-only, and display-clean.
