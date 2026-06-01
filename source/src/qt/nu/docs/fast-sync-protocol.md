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

The current implementation lives in the Nu Qt/RPC service layer
(`NuRpcService`). It mirrors raw active-chain blocks between eligible Nu peers
over UDP while ordinary TCP/Core block download remains active as fallback and
repair path.

## Capability And Port

- UDP port: `10334`
- Datagram prefix: `DFCLAN1\n`
- Capability string: `defcoin-nu-udp-fast-sync-v1`
- Protocol version: `1`

Nu currently discovers Fast Sync candidates from connected peers whose
User-Agent begins with `DefcoinCoreNu`. Older `DefcoinCore` peers are not marked
Fast Sync capable. A Nu peer starts as `TBA`, becomes `Yes` after a valid UDP
Fast Sync response, and becomes `Failed` after a session attempt times out or
fails without usable chunks.

LAN discovery may also send local broadcast requests when the user enables LAN
node discovery. Broadcast is intentionally limited to private/local networks.

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

### Response

The responder verifies that the requester is eligible, rate-limits requests by
source host, fetches the active-chain block through RPC (`getblockhash`, then
`getblock <hash> 0`), and sends one or more `type=block-chunk` datagrams.

Each chunk header includes:

- `id`, `height`, and block `hash`.
- `seq` and `total`.
- `block_size`.
- `chunk_bytes`.
- `max_datagram`.
- `block_checksum`: SHA-256 of the complete raw block bytes.
- `chunk_checksum`: SHA-256 of that chunk payload.

The receiver rejects chunks that do not match the active request, expected
height, negotiated size caps, checksum, sequence bounds, or block-size bounds.
After all chunks arrive, the receiver verifies the complete block checksum and
then calls `submitblock`. Only accepted or duplicate-valid submit results count
as UDP success.

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

On a receiver-confirmed success, Nu steps one candidate upward. On timeout,
checksum failure, retransmit failure, or validation failure, Nu steps one
candidate downward. This means the displayed probe pair such as
`1472/1024 B` is the current datagram/chunk selection, not a permanent static
setting.

## TCP/UDP Selection

The selector is a two-arm online comparison between TCP/Core sync and UDP Fast
Sync.

Tracked per protocol:

- successes and failures.
- EWMA blocks per second.
- bytes and packets.
- UDP checksum/retransmit/error counts.
- UDP cooldown after failures.

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

## Server Deployment Boundary

The current code path is a Qt/RPC helper. It is suitable for desktop Nu peers,
but a public server should not run a GUI just to provide Fast Sync.

There are two safe server options:

1. Port the Fast Sync helper into the headless backend or a dedicated audited
   sidecar daemon that talks to the local `defcoind` over RPC.
2. Deploy that daemon on UDP `10334`, keep TCP/Core `10332` as the authoritative
   P2P service, and expose the same capability/version/checksum/rate-limit
   behavior documented above.

Do not mark the dc903 server as Fast Sync deployed until the live host is
running a headless implementation and at least one Nu wallet has accepted a
validated block from it over UDP. The local development environment currently
cannot update the live server because `gladjoe@50.116.19.40` rejects the local
public key; a server deploy needs restored SSH access or a separate operator
session.

## Security Rules

- Never accept datagrams without the protocol prefix, version, and capability.
- Keep datagram, header, payload, chunk-count, block-size, and request-rate caps.
- Restrict broadcast handling to LAN/private mode.
- Never count sender-side bytes as proof of speed.
- Never bypass `submitblock`.
- Treat TCP/Core as the repair path.
- Keep the UDP helper disableable from Settings.

