# Defcoin Core Nu Goals

This note defines the product and community goals for Defcoin Core Nu. It
treats the local source tree as authoritative for protocol parameters when
public copy conflicts with the code. In particular, the defcoin.io 60-second
block-time copy is not used as the protocol baseline here.

## Position

Defcoin Core Nu should make Defcoin feel inspectable, repairable, and worth
experimenting with. It is not a market-hype wallet. It is a hacker-friendly
full-node wallet for a small proof-of-work chain with DEF CON-adjacent history.

The coin's durable niche is not that it can outspend larger networks. Its niche
is that it is small enough to understand, old enough to have real chain history,
and open enough that one motivated user can run a node, mine, inspect local
wallet activity, write tools, and see their work affect the network.

## What Keeps Niche Coins Alive

Strong niche coin communities usually have several traits:

- A clear identity that is easy to explain and easy to repeat.
- A low-friction first action: download, sync, get an address, mine, test, or
  contribute a small fix.
- Public artifacts that reward curiosity: release notes, mining stats, docs,
  node status, GitHub work, and reproducible builds.
- A contribution ladder for non-coders and coders: write docs, run a node,
  maintain a seed, mine, test builds, triage issues, build tools, then touch
  core code.
- A reason to stay after the novelty fades: social rituals, project ownership,
  recurring challenges, transparent operations, and useful data.

## Product Goals

1. Make custody clear.

   Wallet actions must be explicit, recoverable, and understandable. Sending,
   receiving, backup, encryption, recovery phrases, paper wallets, watch-only
   addresses, message signing, and compatibility tools belong in the Wallet
   section, not hidden behind diagnostics.

2. Keep Core validation authoritative.

   Fast Sync, Quick Clone/DCOL, LAN discovery, and mining helpers must not
   create alternate consensus paths. Transport can be optimized, but accepted
   blocks still go through Core validation.

3. Make node health readable.

   The status strip, Metrics, peer tables, Debug Log, and RPC Console should
   make it obvious whether the backend is connected, synced, mining, fast-sync
   capable, or waiting on a user-visible action.

4. Turn mining into a security action.

   Mining copy and status should frame mining as securing and reviving the
   Defcoin chain, not only as earning DFC. P2Pool matters because it lets users
   participate without trusting a central pool balance sheet.

5. Keep builders invited.

   Nu should expose enough RPC examples, local status, protocol notes, and
   reproducible build instructions that a curious user can build a dashboard,
   miner monitor, seed node, or research notebook without reverse-engineering
   the app first.

6. Preserve history without freezing the project.

   Defcoin's old chain, legacy ports, address forms, and DEF CON-adjacent story
   are part of the charm. Nu should preserve compatibility while making the
   next decade about maintainable tooling, active nodes, visible mining, and
   usable wallet operations.

7. Keep Quick Clone/DCOL distinct from Fast Sync.

   Fast Sync is a transport optimization for normal Core-selected block
   download and validation. Quick Clone is the human-friendly name for Direct
   Copy Over LAN: a trusted snapshot-style mode for a user who intentionally
   chooses to seed local chain state from machines they control and bypass
   historical validation. DCOL must never copy wallets, keys, settings, peers,
   address books, RPC cookies, or ban files.

## Voice

Use precise, non-promotional language:

- Prefer "full-node wallet", "local backend", "public chain data", "trusted
  LAN", "Core validation", and "external block explorer".
- Avoid hype about price, scarcity, investment, or guaranteed speed.
- When a feature is experimental, say so directly and show fallback behavior.
- When a feature touches wallet safety, explain what is and is not copied,
  persisted, or transmitted.

## Practical Product Standard

Every Nu surface should answer one of these questions quickly:

- Can I receive or send DFC safely?
- Is my wallet backed up, encrypted, and recoverable?
- Is my node synced and connected to real Defcoin peers?
- Can I inspect what the backend is doing without leaving the app?
- Can I mine, test, or help the network without damaging wallet data?

If a feature does not support one of those questions, it should stay outside
the Nu wallet release until it has its own product boundary.
