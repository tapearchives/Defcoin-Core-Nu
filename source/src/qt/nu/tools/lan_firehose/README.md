# LAN Firehose Throughput Test

`LAN_Firehose_Throughput_Test.py` is a standalone throughput tester for comparing
TCP and UDP behavior between two machines. It is intentionally separate from the
wallet: it does not read keys, does not use RPC, and does not submit blocks.

`LAN_Firehose_Throughput_Test.app` is a native Qt wrapper for the same tester. It
provides the common controls, live stdout, a results table, summary stats, and a
small TCP/UDP throughput chart. The wrapper launches the Python CLI as a
subprocess and reads the CSV/JSONL output files, so the measurement logic stays
in one place.

When the Qt wrapper is open, it advertises an idle beacon containing its current
role, IP-visible workstation name, OS string, and test ports. Auto Pair or Spray
on one machine sends a small control packet to visible idle testers so they
enter Catch mode automatically, then return to idle advertising when the test
finishes.

## Qt wrapper

Build the wrapper from the existing Nu CMake tree:

```sh
cmake --build source/build/nu-qml-arm64-26.5.5 --target LAN_Firehose_Throughput_Test
```

Then open the generated app:

```sh
open "source/build/nu-qml-arm64-26.5.5/LAN_Firehose_Throughput_Test.app"
```

The wrapper supports:

- Auto Pair, Spray, and Catch modes. The CLI still accepts `auto`, `hose`, and
  `sink` for script compatibility.
- Manual peer IP for direct Spray tests.
- Automatic all-visible-tester behavior by default. Auto Pair and Spray send to
  all visible testers at once; Catch accepts all visible senders.
- Manual one-to-one picker as an opt-in checkbox. The picker shows each visible
  tester's IP address, discovered workstation name, role, OS string, and ports.
- Duration, protocol switch timing, packet profile, and custom packet sizes.
- Optional pairing token so two testers on the same LAN pair only with each
  other.
- Optional UDP CRC32 payload checks.
- Live TCP/UDP average, best phase, UDP loss/checksum counts, output table,
  stdout log, and chart.
- Open Log / Open CSV buttons for the generated diagnostic files.

## Typical LAN test

Run the same command on two machines on the same LAN:

```sh
python3 LAN_Firehose_Throughput_Test.py --mode auto --duration 120 --csv ~/Desktop/nu-firehose.csv
```

Both instances broadcast a small discovery beacon. The two nodes choose one
Spray side (`hose`) and one Catch side (`sink`) deterministically, then run a 120
second sweep. Auto mode also starts listeners on both sides and promotes a quiet
Catch side to Spray if no incoming traffic arrives, so one-way discovery does not leave
both machines waiting forever.

With more than two testers, the default wrapper behavior is automatic: one Start
from Auto Pair or Spray sends control packets to the visible idle testers, those
testers enter Catch mode, and the starter sprays all targets concurrently. If
`Manual pick one tester` is enabled, the wrapper shows a one-to-one picker
instead. In Catch mode, incoming TCP rows are separated by connection and UDP
rows are separated by sender IP and UDP source port.

## Direct loopback or manual peer test

Start a Catch receiver:

```sh
python3 LAN_Firehose_Throughput_Test.py --mode sink --duration 30 --no-beacon
```

Then start a Spray sender:

```sh
python3 LAN_Firehose_Throughput_Test.py --mode hose --peer 127.0.0.1 --duration 30 --no-beacon
```

## Useful options

- `--size-profile conservative` tests only 576, 1280, and 1472 byte payloads.
- `--size-profile jumbo` also tries near-maximum UDP payloads. On normal
  internet paths these may fragment or fail; on LAN jumbo-capable links they are
  useful for measurement.
- `--packet-sizes 576,1280,1472,4096` supplies a custom sweep.
- `--udp-checksum` adds CRC32 payload checks to UDP packets.
- `--token <text>` pairs only with another firehose instance using the same
  token.
- `--accept-peer <ip>` restricts Catch mode to one incoming peer. Repeat the
  option for several allowed senders.
- `--peers-json <json>` sends to several peers in sequence. The Qt wrapper uses
  this when Auto-connect all testers is enabled in Spray mode.
- `--log-jsonl <path>` writes structured phase and peer discovery events.
- `--debug-log <path>` writes a readable `.log` sidecar for Console/TextEdit.
- `--csv <path>` writes phase throughput rows.

The live Nu UDP fast-sync path remains conservative and sub-MTU by default.
This tool exists so larger payloads, LAN jumbo frames, and TCP/UDP scheduling can
be tested without risking wallet sync correctness.
