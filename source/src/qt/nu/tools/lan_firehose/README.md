# Defcoin Nu LAN Firehose

`defcoin_lan_firehose.py` is a standalone throughput tester for comparing TCP and
UDP behavior between two machines. It is intentionally separate from the wallet:
it does not read keys, does not use RPC, and does not submit blocks.

`DefcoinLanFirehose` is a native Qt wrapper for the same tester. It provides the
common controls, live stdout, a results table, summary stats, and a small TCP/UDP
throughput chart. The wrapper launches the Python CLI as a subprocess and reads
the CSV/JSONL output files, so the measurement logic stays in one place.

## Qt wrapper

Build the wrapper from the existing Nu CMake tree:

```sh
cmake --build source/build/nu-qml-arm64-26.5.5 --target DefcoinLanFirehose
```

Then open the generated app:

```sh
open "source/build/nu-qml-arm64-26.5.5/DefcoinLanFirehose.app"
```

The wrapper supports:

- Auto, sink, and hose modes.
- Manual peer IP for direct hose tests.
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
python3 defcoin_lan_firehose.py --mode auto --duration 120 --csv ~/Desktop/nu-firehose.csv
```

Both instances broadcast a small discovery beacon. The two nodes choose one
sender (`hose`) and one receiver (`sink`) deterministically, then run a 120
second sweep. By default the test spends about 60 seconds on TCP and then 60
seconds on UDP while stepping through practical payload sizes.

## Direct loopback or manual peer test

Start a sink:

```sh
python3 defcoin_lan_firehose.py --mode sink --duration 30 --no-beacon
```

Then start a sender:

```sh
python3 defcoin_lan_firehose.py --mode hose --peer 127.0.0.1 --duration 30 --no-beacon
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
- `--log-jsonl <path>` writes structured phase and peer discovery events.
- `--csv <path>` writes phase throughput rows.

The live Nu UDP fast-sync path remains conservative and sub-MTU by default.
This tool exists so larger payloads, LAN jumbo frames, and TCP/UDP scheduling can
be tested without risking wallet sync correctness.
