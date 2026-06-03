# Defcoin Core Nu 26.6.3a Release Notes

Defcoin Core Nu `26.6.3a` is a LAN discovery and Fast Sync peer-discovery update
over `26.6.2i`.

## LAN Discovery

- Adds explicit Nu LAN announcement beacons on UDP port `10334`.
- Announces only non-sensitive machine metadata: product, build, local
  workstation name, P2P port, Fast Sync port, platform, architecture, and a
  local-install UUID.
- Uses real interface broadcast addresses instead of assuming a `/24` subnet.
- Queues `addnode host:1337 add` after RPC is ready so nearby Nu wallets are
  more likely to become actual P2P peers.

## Workstation Names

- Prefers announced Nu workstation names in the peers table.
- Rejects pseudo names such as `broadcasthost`, `localhost`, `workgroup`, raw
  IP literals, broadcast, multicast, and loopback artifacts.
- Falls back to the older Bonjour, SMB, NetBIOS, ARP/NDP, DNS, and optional
  nmap discovery stack when a node does not announce a clean workstation name.
- Keeps ambiguous workstation-name lookup failures as display-only metadata
  failures; they do not block normal P2P or Fast Sync eligibility.

## Fast Sync

- Keeps Fast Sync negotiation separate from LAN beacons.
- Beacon discovery can help add the peer, but UDP block transfer still requires
  connected peer state, the Defcoin Fast Sync service bit, and a successful UDP
  probe/probe-ack exchange.
