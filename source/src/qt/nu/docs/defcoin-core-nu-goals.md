# Defcoin Core Nu Goals

This note defines the product and community goals for Defcoin Core Nu and the
Explore explorer/forensics surface. It treats the local Defcoin Core Nu source
tree as authoritative for protocol parameters when public copy conflicts with
the code. In particular, the defcoin.io 60-second block-time copy is not used as
the protocol baseline here.

## Position

Defcoin Core Nu should make Defcoin feel inspectable, repairable, and worth
experimenting with. It is not a market-hype wallet. It is a hacker-friendly full
node, wallet, explorer, and forensic workbench for a small proof-of-work chain
with DEF CON-adjacent history.

The coin's durable niche is not that it can outspend larger networks. Its niche
is that it is small enough to understand, old enough to have real chain history,
and open enough that one motivated user can run a node, mine, inspect flows,
write tools, and see their work affect the network.

## What Keeps Niche Coins Alive

Strong niche coin communities usually have several traits:

- A clear identity that is easy to explain and easy to repeat.
- A low-friction first action: download, sync, get an address, mine, search,
  inspect, or contribute a small fix.
- Public artifacts that reward curiosity: explorers, rich lists, network
  monitors, mining stats, docs, and visible GitHub work.
- A contribution ladder for non-coders and coders: write docs, run a node,
  maintain a seed, mine, test builds, triage issues, build tools, then touch
  core code.
- A reason to stay after the novelty fades: social rituals, project ownership,
  recurring challenges, transparent operations, and useful data.

Dogecoin shows the power of a welcoming identity and social participation.
Monero shows how explicit workgroups turn a wide community into focused
contribution paths. Litecoin shows that a proof-of-work coin can remain relevant
for years when it stays open-source, simple to run, and connected to real node
operation. eIquidus shows what altcoin users expect from a useful explorer:
searchable blocks, transactions, addresses, movement views, network stats,
rich-list style holder views, APIs, and index maintenance.

## What Motivates DEF CON-Aligned Users

The DEF CON community is not motivated by passive ownership alone. The durable
motivators are curiosity, proof, skill growth, experimentation, and credible
participation. The official DEF CON Groups language emphasizes learning,
sharing, hacking, connecting, local projects, and year-round activity. The older
DEF CON Groups FAQ also frames groups as places where newcomers can learn,
people can mentor, and different technical backgrounds can meet around modern
technology.

For Defcoin, that means the app should invite users to do things:

- Search a real address, txid, block hash, or block height.
- Ask why an address accumulated DFC.
- Watch how holder concentration changes.
- Inspect odd OP_RETURN and witness-storage cases.
- Mine against P2Pool and see the chain respond.
- Export or query data to build a tool of their own.
- Run infrastructure that other users can verify.

## Product Goals

1. Explorer first.

   Explore must behave like a normal block explorer before it behaves like a
   specialty forensic tool. The main mast search should accept wallet addresses,
   txids, block hashes, and heights, then route directly to Explorer results.

2. Make public-chain data visually sticky.

   Holder concentration, supply bands, movement thresholds, and forensic oddities
   should make the user ask another question. The charts should not just report
   numbers; they should imply paths for investigation.

3. Show the indexing engine honestly.

   The mast should show Explorer, Holder Atlas, movement, and forensics indexing
   states because those background jobs are the engine of the app. Users should
   know when data is fresh, stale, scanning, paused, or missing.

4. Separate observation from custody.

   Explore can inspect public chain data and local SQLite indexes. It must not
   duplicate consensus rules, wallet signing, private-key handling, or validation
   logic in QML. The backend remains authoritative.

5. Turn mining into a security action.

   Mining copy and status should frame mining as securing and reviving the
   Defcoin chain, not only as earning DFC. P2Pool matters because it lets users
   participate without trusting a central pool balance sheet.

6. Make builders feel invited.

   Nu and Explore should expose enough local data, RPC examples, and schema
   documentation that a curious user can build a dashboard, bot, indexer, miner
   monitor, or research notebook without reverse-engineering the app first.

7. Preserve history without freezing the project.

   Defcoin's old chain, legacy ports, address forms, and DEF CON-adjacent story
   are part of the charm. Nu should preserve compatibility while making the next
   decade about maintainable tooling, active nodes, visible mining, and usable
   public data.

8. Keep Fast Sync, LAN Fast Copy, and Quick Clone/DCOL distinct.

   Fast Sync is a transport optimization for normal Core-selected block
   download and validation. LAN Fast Copy is an online trusted-LAN transfer path
   that pauses ordinary P2P on the receiver and copies block bodies from LAN Nu
   peers through the checksum-protected UDP chunk path while still submitting
   blocks to Core. Quick Clone is the human-friendly name for Direct Copy Over
   LAN (DCOL): a trusted snapshot-style mode for a user who intentionally chooses
   to seed local chain state from machines they control and bypass historical
   validation. DCOL must never copy wallets, keys, settings, peers, or ban
   files. It must move only chain/index state, use explicit manifests and hashes
   before replacing local chain data, require backend shutdown or a coherent
   source snapshot, and leave normal Core validation and repair paths available
   after import.

## Explore Experience Goals

- The first screen should feel like an explorer command center, not a marketing
  page.
- The top-left lockup should state the product clearly: DEFCOIN / CORE NU /
  EXPLORE.
- The first left-pane section should be the Holder Atlas: Largest Holders,
  Supply Bands, and Whale Lens grouped as one study of holder accumulation and
  concentration.
- The Indexer Console should be framed as the monitor and settings page for
  long-running data engines.
- Search results should remain inside the Explorer workflow so users understand
  that Explore is the app's investigative home.

## Voice

Use precise, non-promotional language:

- Prefer "inspect", "verify", "mine", "build", "run", "index", "trace", and
  "experiment".
- Avoid price-first framing and investment promises.
- Avoid implying that one address is one person unless the app has evidence.
- Explain uncertainty plainly, especially around address clustering and holder
  interpretation.

## References

- Local protocol baseline: `source/src/chainparams.cpp` and `source/src/amount.h`.
- Local architecture boundary: `docs/backend-frontend-boundary.md` and
  `docs/functionality-map.md`.
- Defcoin public site for current mining/explorer/community links:
  https://defcoin.io/
- Historical Defcoin source tree:
  https://github.com/mspicer/Defcoin
- DEF CON Groups:
  https://defcon-groups.org/
- DEF CON Groups FAQ:
  https://forum.defcon.org/node/231249
- Dogecoin community onboarding:
  https://dogecoin.com/dogepedia/articles/join-the-dogecoin-community/
- Monero workgroups:
  https://www.getmonero.org/community/workgroups/
- Litecoin project framing:
  https://litecoin.com/what-is-litecoin
- eIquidus explorer feature baseline:
  https://github.com/VECO-Project/eiquidus-explorer
