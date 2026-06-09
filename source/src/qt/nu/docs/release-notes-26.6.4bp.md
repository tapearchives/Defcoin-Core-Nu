# Defcoin Core Nu 26.6.4bp Release Notes

## Fast Sync / Quick Clone

- Repairs UDP Fast Sync transport verification after a peer reconnects or changes
  address family. If a LAN peer is already UDP-verified but Core assigns it a new
  live node id, Nu now re-applies Core's `transport-verified` marker during
  `getpeerinfo` refresh.
- This fixes the observed Tahoe/Lion case where UDP probes were acknowledged, but
  Core refused later reservations with `fast-sync-udp-transport-unverified` after
  the Tahoe peer moved from an IPv4 node id to an IPv6 node id.
- The fix is guarded by a per-node cache so Nu does not repeatedly spam the
  backend with duplicate `transport-verified` RPC calls.

## Lion / Cross-Build Notes

- Port the `m_udp_fast_sync_core_verified_node_ids` member and the
  `getpeerinfo` refresh re-application logic exactly.
- Keep the same behavior on Tahoe, Lion, Catalina, Windows, and server builds:
  UDP verification is still required before UDP block reservations, but verified
  transport should survive normal Core peer id churn.
