# net.cpp Agent Notes

## Purpose

Owns low-level P2P connection management, DNS seed/fixed seed handling, address manager selection, binding, and outbound connection policy.

## Nu Divergence

- Adds Defcoin-specific seed timing, preferred ports, alternate port handling, and broader addrman retry behavior for sparse historical nodes.
- Preserves service-bit-aware DNS seed behavior while allowing Defcoin's legacy reachable node patterns.

## Do Not Break

- Keep peer discovery compatible with legacy Defcoin nodes and Nu nodes advertising Fast Sync.
- Do not make Fast Sync service-bit filtering exclude normal usable peers; Fast Sync is optional.
- Do not alter bind/listen behavior in a way that silently reintroduces macOS Local Network prompts before the user enables LAN features.

## Verification

- `git diff --check`
- Check `getpeerinfo`, seed-source display, and outbound peer count after connection-policy changes.
