# Defcoin Core Nu Fast Sync Protocol

This is the authoritative developer note for Defcoin Core Nu Fast Sync. Release
notes and feature maps may summarize the feature, but this file defines the
current protocol behavior and deployment boundary.

## Scope

Fast Sync is an optional transport helper. It does not change consensus rules,
does not replace Defcoin Core peer-to-peer block validation, and does not trust
sender-reported speed. A received block is counted as successful only after the
receiver reassembles it, verifies checksums, and submits it through the normal
Core `submitblock` validation path.

The desktop implementation coordinates the Nu Qt/RPC service layer
(`NuRpcService`) with Core's normal block in-flight table. It mirrors raw
active-chain blocks between eligible Nu peers over UDP while ordinary TCP/Core
block download remains available as fallback and repair path. UDP and TCP are
treated as transport choices for one logical connected peer, not as independent
reasons to request the same block twice.

The public dc903 server implementation is a responder-only sidecar
(`defcoin-fast-syncd`) that talks to the local `defcoind` over RPC. The sidecar
does not replace Core P2P, does not mine, and does not validate blocks on behalf
of clients. It only returns the raw active-chain block requested by a Nu wallet.

## Capability And Port

- UDP port: `10334`
- Datagram prefix: `DFCLAN1\n`
- Capability string: `defcoin-nu-udp-fast-sync-v1`
- Protocol version: `1`
- Service bit: `NODE_DEFCOIN_FASTSYNC = 1 << 29`

Nu discovers Fast Sync candidates from connected peers that advertise
`NODE_DEFCOIN_FASTSYNC`. During the transition to 26.6.1, Nu may also treat a
connected peer whose User-Agent begins with `DefcoinCoreNu` as a tentative
candidate, but this fallback is only for compatibility with earlier Nu builds.
Older `DefcoinCore` peers are not marked Fast Sync capable. A candidate starts
as `TBA`, becomes `Yes` after a valid UDP Fast Sync response, and becomes
`Failed` after a session attempt times out or fails without usable chunks. The
capability is proven by UDP response and normal `submitblock` acceptance, not by
the service bit or User-Agent string alone.

LAN discovery may learn private/local peers, but block data requests are sent to
one selected connected Nu peer. Broadcast is not used for block data requests.

## Packet Format

Every datagram is:

```text
DFCLAN1\n
<compact JSON header>
\n\n
<optional binary payload>
```

The JSON header must fit within the configured header cap and must include a
numeric `payload_size`. The parser rejects malformed JSON, wrong protocol
version, wrong capability string, mismatched payload length, overlarge headers,
overlarge payloads, and overlarge datagrams before any block assembly work.

### Request

The requester sends `type=request-block` with:

- `id`: 32-character request UUID.
- `height`: requested block height.
- `tip`: requester's current block height.
- `port`: reply port, currently `10334`.
- `max_datagram`: maximum datagram size the requester wants to receive.
- `chunk_bytes`: desired payload chunk size.
- `datagram_mode`: `safe-probe` or `lan-probe`.

Requests are always sent as safe small datagrams even when the requested reply
size is larger.

Before sending the request, Nu asks the backend to reserve the requested block
height for the selected connected peer in Core's normal in-flight table. The
backend returns the exact block hash Core expects that peer to be able to serve.
If Core reports that the block is already present, already in flight, outside
the peer's known header chain, or unavailable from that peer, Nu does not send
the UDP request and leaves TCP/Core sync to continue normally. This reservation
is a local coordination step, not a wire-protocol change.

### Response

The responder verifies the request shape, rate-limits requests by source host,
fetches the active-chain block through RPC (`getblockhash`, then
`getblock <hash> 0`), and sends one or more `type=block-chunk` datagrams. The
desktop responder restricts response traffic to eligible Nu peers. The dc903
sidecar uses the same boundary in headless form: it periodically reads
`getpeerinfo` and only serves UDP block chunks to source IPs that are currently
connected over normal Core TCP and advertise `NODE_DEFCOIN_FASTSYNC`. During
the 26.6.1 transition it can still accept a connected `DefcoinCoreNu`
User-Agent as a fallback hint. Loopback can be allowed for local administrator
tests, but public requesters must first be normal connected Nu peers.

Each chunk header includes:

- `id`, `height`, and block `hash`.
- `seq` and `total`.
- `block_size`.
- `chunk_bytes`.
- `max_datagram`.
- `block_checksum`: SHA-256 of the complete raw block bytes.
- `chunk_checksum`: SHA-256 of that chunk payload.

The receiver rejects chunks that do not match the active request, the backend
reserved hash, negotiated size caps, checksum, sequence bounds, or block-size
bounds. After all chunks arrive, the receiver verifies the complete block
checksum and then calls `submitblock`. The reservation is released on success,
timeout, checksum failure, validation failure, or skip.

Accepted blocks count as receiver-confirmed UDP transport samples. Duplicate
valid blocks should become uncommon because Core sees the reserved block as
already in flight and normally avoids requesting it over TCP. If a duplicate
still occurs due to timing, it is counted as transport evidence but treated as a
repair/race case rather than the normal path.

## Packet Size Selection

Packet sizing is adaptive, but bounded.

Constants:

- Safe/default datagram: `1232` bytes.
- Internet probe datagram: `1472` bytes.
- Maximum allowed datagram: `16640` bytes.
- Chunk size: `datagram_size - 448`, clamped to protocol min/max.

Candidate ladders:

- Internet/default mode: `1232`, `1472`.
- LAN/private mode: `1472`, `4096`, `8192`, `12000`, `16000`.

The mode is LAN/private when LAN discovery is enabled or when a Fast Sync target
is a private/local address. Non-private internet peers are capped at the
internet probe size even if they request or advertise larger datagrams.

On a receiver-confirmed success, including duplicate-valid delivery, Nu steps
one candidate upward. On timeout, checksum failure, retransmit failure, or
validation failure, Nu steps one candidate downward. This means the displayed
probe pair such as
`1472/1024 B` is the current datagram/chunk selection, not a permanent static
setting.

The responder does not choose an independent packet-size strategy. The Nu
wallet requester sends `max_datagram` and `chunk_bytes`; the responder clamps
those values to its safety limits and echoes the resulting values in each chunk.
This keeps packet-size tuning based on receiver-confirmed success instead of
server-side sender throughput.

## TCP/UDP Selection

The selector is a two-arm online comparison between TCP/Core sync and UDP Fast
Sync.

Nu's UDP path is coordinated with Core P2P by reserving one block in Core's
in-flight table before a UDP request is sent. Core's normal downloader then sees
that block as already assigned and should not also request it by TCP unless the
reservation is released after failure or timeout.

Tracked per protocol:

- successes and failures.
- EWMA blocks per second.
- bytes and packets.
- UDP checksum/retransmit/error counts.
- UDP cooldown after failures.

The TCP and UDP selector counters are maintained through one shared
transport-scoring path. The transport label decides which counters are updated;
the scoring, reliability, and quota logic is otherwise protocol-agnostic. This
keeps UDP from developing a separate hidden trust or scheduling model while
leaving TCP/Core behavior intact.

Warmup requires four UDP samples when UDP is possible. TCP-only peer traffic is
not allowed to swamp the comparison: TCP success samples are capped relative to
the number of UDP samples when calculating the selector score.

Score:

```text
score = ewma_blocks_per_second * reliability + exploration_bonus
reliability = (successes + 1) / (successes + failures + 2)
exploration_bonus = c * sqrt(log(total_samples + 1) / (samples + 1))
```

If one protocol wins by at least 25 percent and there are no fresh failures, the
window may grow up to the configured cap. The slower path still receives probes
unless it is cooling down after UDP failure. Status text such as
`UDP favored 4:1` or `TCP favored 30:2` reflects this quota window, not a
consensus rule.

The live wallet currently reserves and requests one UDP block at a time from one
selected Nu peer. It immediately starts the next UDP probe after a
receiver-confirmed success instead of waiting for the periodic timer. The timer
is only a safety/maintenance cadence. This is important on LANs because a slow
timer can make TCP/Core appear dominant even when UDP has higher raw throughput.

## Diagnostics

Diagnostics exposes:

- Combined syncing average.
- Fast Sync TCP totals, recent rate, sample counts, and Core-managed packet
  note.
- Fast Sync UDP totals, packet counts, accepted blocks, recent rate, samples,
  and retransmit/checksum count.
- Current TCP/UDP decision summary.
- Current UDP probe datagram/chunk size.
- Per-peer observed transfer method: `TCP`, `UDP`, or `TCP+UDP`, shown only
  after that method has transferred accepted data with that peer.

UDP averages include time spent in failed attempts, timeouts, checksum failures,
and retries so UDP cannot look artificially faster by ignoring failed work.

## Server Deployment

The server implementation is `source/src/qt/nu/tools/defcoin_fast_syncd.py`
with the matching `defcoin-fast-syncd.service` systemd unit. It should run as
the same unprivileged account that owns the local Defcoin data directory and
read the existing RPC credentials from `defcoin.conf`.

Deployment rules:

1. Keep TCP/Core `10332` as the authoritative P2P service.
2. Open UDP `10334` only for the Fast Sync responder.
3. Start `defcoin-fast-syncd` after `defcoind.service`.
4. Confirm `ss -lunp` shows UDP `10334`.
5. Confirm `defcoin-fast-syncd` logs `require_nu_peer=True`.
6. Confirm a Nu wallet receives at least one validated block over UDP before
   treating the server as deployed.

The server can serve larger datagrams to private/local requesters, but internet
requesters are capped to the internet probe size. This avoids assuming jumbo UDP
works across arbitrary public routes.

The server sidecar is responder-only. It never asks legacy v1.0.0 wallets to
use UDP, never sends UDP first, and never changes the ordinary TCP/Core service
used by older wallets. Legacy peers do not advertise `NODE_DEFCOIN_FASTSYNC`,
so their addresses are not placed in the UDP response allowlist.

## Security Rules

- Never accept datagrams without the protocol prefix, version, and capability.
- Keep datagram, header, payload, chunk-count, block-size, and request-rate caps.
- On public sidecars, serve only currently connected TCP peers advertising
  `NODE_DEFCOIN_FASTSYNC`, with temporary `DefcoinCoreNu` User-Agent fallback
  only during the 26.6.1 transition.
- Reply to the datagram source address and source port; do not use UDP requests
  as a reflection mechanism to an arbitrary advertised port.
- Restrict broadcast handling to LAN/private mode.
- Never count sender-side bytes as proof of speed.
- Never bypass `submitblock`.
- Treat TCP/Core as the repair path.
- Keep the UDP helper disableable from Settings.

## Future Security Roadmap

Fast Sync currently prioritizes safe transport coordination, bounded packet
handling, receiver-confirmed checksums, and normal Core block validation. The
next hardening layer should evaluate authenticated encryption for UDP after the
basic transport proves stable. The same review should also cover normal TCP P2P
transport because this Litecoin-era codebase does not currently treat ordinary
TCP block sync as SSL/TLS-encrypted transport.

TCP is still materially more mature than the UDP helper because it already uses
Core's peer handshake, peer identity, inventory/getdata flow, block in-flight
tracking, timeout handling, misbehavior/disconnect paths, traffic accounting,
and full block validation. UDP should continue borrowing those protections where
they fit instead of growing a separate hidden scheduler or trust model.

Reusable TCP/Core protections to keep applying to UDP:

- Reserve UDP-requested blocks through Core's in-flight table before sending the
  UDP request.
- Request block data only from connected peers whose headers indicate they
  should have that block.
- Enable UDP probing only when there is an actual connected Nu peer; LAN
  discovery alone is not enough to start block-data requests.
- Use large UDP datagrams only for actual private/local Fast Sync peers, not
  merely because LAN discovery is enabled.
- Keep one clear active owner for a requested block; release it on timeout,
  checksum failure, validation failure, or completion.
- Feed completed blocks through normal Core validation instead of trusting the
  UDP sender.
- Mirror Core-style rate, timeout, and memory-pressure limits rather than
  buffering unbounded out-of-order chunks.
- Treat TCP/Core as the repair and fallback path whenever UDP is ambiguous.

Candidate approaches:

- BIP324-style session keys: negotiate or derive keys through the existing
  connected TCP peer relationship, then authenticate/encrypt UDP block chunks
  with an AEAD construction. This aligns conceptually with Bitcoin Core's v2
  encrypted transport while keeping UDP as an auxiliary block-body path.
- Noise Protocol / libsodium secretbox style packets: use a small, explicit
  handshake and per-peer symmetric keys for authenticated UDP payloads. This is
  simpler to reason about than ad hoc encryption but adds a dependency and
  key-rotation design work.
- QUIC as a later benchmark option: QUIC already runs over UDP and provides
  encryption, congestion control, streams, and loss handling, but it is a much
  larger protocol and dependency than the current helper. Treat it as a separate
  benchmark/research item, not an immediate replacement.

Do not add encryption as a substitute for validation. Even encrypted UDP block
data must still pass the same reservation, checksum, size-cap, timeout, and
`submitblock` validation path. The first goal remains preventing spoofing,
amplification, memory pressure, duplicate requests, and unsafe packet handling;
secrecy is a useful later improvement, not the primary safety boundary.

Future TCP hardening should evaluate whether Bitcoin Core's BIP324 v2 encrypted
transport can be ported cleanly into Defcoin Core Nu. If that work is feasible,
prefer sharing the authenticated session/key material with UDP Fast Sync instead
of inventing an unrelated UDP-only cryptographic identity.
