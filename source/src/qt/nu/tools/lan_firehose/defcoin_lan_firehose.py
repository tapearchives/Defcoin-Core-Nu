#!/usr/bin/env python3
"""Defcoin Core Nu LAN firehose throughput tester.

This is a standalone diagnostic tool for comparing TCP and UDP transfer behavior
between two machines on the same network. It does not talk to the wallet RPC
server, does not read wallet data, and does not write blockchain data.
"""

from __future__ import annotations

import argparse
import csv
import datetime as _dt
import json
import os
import platform
import queue
import random
import select
import signal
import socket
import struct
import sys
import threading
import time
import uuid
import zlib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple


MAGIC = "DFCNU_FIREHOSE_V1"
BEACON_MAGIC = "DFCNU_FIREHOSE_BEACON_V1"
UDP_MAGIC = b"DFCFH1\0\0"
UDP_HEADER_STRUCT = struct.Struct("!HIIHQ")
UDP_HEADER_BYTES = len(UDP_MAGIC) + UDP_HEADER_STRUCT.size
TCP_HELLO_TIMEOUT = 10.0
MAX_JSON_BYTES = 8192
MAX_UDP_PAYLOAD = 65507
DEFAULT_BEACON_PORT = 10344
DEFAULT_TCP_PORT = 10345
DEFAULT_UDP_PORT = 10346
DEFAULT_SWITCH_SECONDS = 60.0
DEFAULT_DURATION_SECONDS = 120.0
DEFAULT_PACKET_SIZES = [576, 1280, 1472, 4096, 8192, 16384, 32768, 60000]


@dataclass
class Peer:
    node_id: str
    host: str
    hostname: str
    tcp_port: int
    udp_port: int
    last_seen: float
    os_name: str = ""


@dataclass
class Phase:
    index: int
    protocol: str
    payload_size: int
    duration: float


@dataclass
class PhaseResult:
    phase: int
    role: str
    protocol: str
    payload_size: int
    duration_s: float
    sent_bytes: int = 0
    recv_bytes: int = 0
    sent_packets: int = 0
    recv_packets: int = 0
    lost_packets: int = 0
    out_of_order: int = 0
    checksum_errors: int = 0
    mbps: float = 0.0
    note: str = ""


@dataclass
class SharedState:
    stop: threading.Event = field(default_factory=threading.Event)
    peers: Dict[str, Peer] = field(default_factory=dict)
    results: List[PhaseResult] = field(default_factory=list)
    log_lock: threading.Lock = field(default_factory=threading.Lock)
    csv_lock: threading.Lock = field(default_factory=threading.Lock)


def now_iso() -> str:
    return _dt.datetime.now().astimezone().isoformat(timespec="seconds")


def clamp_payload_size(size: int) -> int:
    return max(64, min(MAX_UDP_PAYLOAD - 64, size))


def size_profile(name: str, custom: str) -> List[int]:
    if custom:
        values = []
        for part in custom.split(","):
            part = part.strip()
            if not part:
                continue
            values.append(clamp_payload_size(int(part)))
        if values:
            return values
    if name == "conservative":
        return [576, 1280, 1472]
    if name == "jumbo":
        return [576, 1280, 1472, 4096, 8192, 16384, 32768, 60000, 65443, 32768, 8192, 1472]
    return list(DEFAULT_PACKET_SIZES)


def build_phases(duration: float, switch_seconds: float, sizes: List[int]) -> List[Phase]:
    duration = max(2.0, duration)
    switch_seconds = max(2.0, min(switch_seconds, duration))
    phases: List[Phase] = []
    elapsed = 0.0
    protocol_index = 0
    protocols = ["tcp", "udp"]
    while elapsed < duration - 0.001:
        remaining = duration - elapsed
        window = min(switch_seconds, remaining)
        slots = max(1, min(len(sizes), int(max(1, round(window / 5.0)))))
        slot_duration = window / slots
        for slot in range(slots):
            payload_size = sizes[slot % len(sizes)]
            phases.append(Phase(len(phases), protocols[protocol_index % 2], payload_size, slot_duration))
        elapsed += window
        protocol_index += 1
    return phases


def safe_json_loads(data: bytes) -> Optional[dict]:
    if not data or len(data) > MAX_JSON_BYTES:
        return None
    try:
        obj = json.loads(data.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None
    if not isinstance(obj, dict):
        return None
    return obj


def log_event(path: Optional[Path], event: dict, state: Optional[SharedState] = None) -> None:
    line = json.dumps({"at": now_iso(), **event}, sort_keys=True)
    if path is None:
        return
    lock = state.log_lock if state else threading.Lock()
    with lock:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("a", encoding="utf-8") as f:
            f.write(line + "\n")


def write_csv_result(path: Optional[Path], result: PhaseResult, state: SharedState) -> None:
    if path is None:
        return
    with state.csv_lock:
        path.parent.mkdir(parents=True, exist_ok=True)
        exists = path.exists()
        with path.open("a", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=list(result.__dict__.keys()))
            if not exists:
                writer.writeheader()
            writer.writerow(result.__dict__)


def format_bytes(value: int) -> str:
    units = ["B", "KB", "MB", "GB", "TB"]
    number = float(value)
    for unit in units:
        if number < 1024.0 or unit == units[-1]:
            return f"{number:.1f} {unit}" if unit != "B" else f"{int(number)} B"
        number /= 1024.0
    return f"{value} B"


def bar(mbps: float, max_mbps: float = 1000.0, width: int = 28) -> str:
    if max_mbps <= 0:
        max_mbps = 1.0
    filled = max(0, min(width, int((mbps / max_mbps) * width)))
    return "#" * filled + "." * (width - filled)


def print_result(result: PhaseResult) -> None:
    moved = result.recv_bytes if result.role == "sink" else result.sent_bytes
    loss = ""
    if result.protocol == "udp" and result.role == "sink":
        loss = f" lost={result.lost_packets} cksum={result.checksum_errors}"
    print(
        f"[{now_iso()}] phase {result.phase:02d} {result.role:4s} "
        f"{result.protocol.upper():3s} {result.payload_size:5d} B "
        f"{format_bytes(moved):>10s} {result.mbps:8.2f} Mb/s "
        f"|{bar(result.mbps)}|{loss} {result.note}",
        flush=True,
    )


def local_hostname() -> str:
    return socket.gethostname() or platform.node() or "unknown-host"


def make_beacon(node_id: str, args: argparse.Namespace) -> bytes:
    return json.dumps(
        {
            "magic": BEACON_MAGIC,
            "node_id": node_id,
            "hostname": local_hostname(),
            "os": f"{platform.system()} {platform.release()}",
            "tcp_port": args.tcp_port,
            "udp_port": args.udp_port,
            "token": args.token,
            "version": 1,
            "time": time.time(),
        },
        sort_keys=True,
    ).encode("utf-8")


def beacon_sender(args: argparse.Namespace, node_id: str, state: SharedState, log_path: Optional[Path]) -> None:
    if args.no_beacon:
        return
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    payload = make_beacon(node_id, args)
    while not state.stop.is_set():
        for target in ("255.255.255.255",):
            try:
                sock.sendto(payload, (target, args.beacon_port))
            except OSError as exc:
                log_event(log_path, {"event": "beacon_send_error", "error": str(exc)}, state)
        state.stop.wait(1.0)


def beacon_listener(args: argparse.Namespace, node_id: str, state: SharedState, log_path: Optional[Path]) -> None:
    if args.no_beacon:
        return
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        sock.bind((args.bind, args.beacon_port))
    except OSError as exc:
        log_event(log_path, {"event": "beacon_bind_error", "error": str(exc)}, state)
        return
    sock.settimeout(0.5)
    while not state.stop.is_set():
        try:
            data, addr = sock.recvfrom(MAX_JSON_BYTES)
        except socket.timeout:
            continue
        except OSError as exc:
            log_event(log_path, {"event": "beacon_recv_error", "error": str(exc)}, state)
            continue
        obj = safe_json_loads(data)
        if not obj or obj.get("magic") != BEACON_MAGIC:
            continue
        if obj.get("node_id") == node_id:
            continue
        if args.token and obj.get("token") != args.token:
            continue
        peer_id = str(obj.get("node_id", ""))
        if not peer_id:
            continue
        peer = Peer(
            node_id=peer_id,
            host=addr[0],
            hostname=str(obj.get("hostname", "")),
            tcp_port=int(obj.get("tcp_port", args.tcp_port)),
            udp_port=int(obj.get("udp_port", args.udp_port)),
            os_name=str(obj.get("os", "")),
            last_seen=time.time(),
        )
        state.peers[peer_id] = peer
        log_event(log_path, {"event": "peer_seen", "peer": peer.__dict__}, state)


def choose_peer(args: argparse.Namespace, node_id: str, state: SharedState) -> Tuple[str, Optional[Peer]]:
    if args.peer:
        peer = Peer(
            node_id="manual-peer",
            host=args.peer,
            hostname=args.peer,
            tcp_port=args.peer_tcp_port or args.tcp_port,
            udp_port=args.peer_udp_port or args.udp_port,
            last_seen=time.time(),
        )
        return args.mode if args.mode != "auto" else "hose", peer
    if args.mode in ("sink", "hose"):
        return args.mode, None
    print("Waiting for another firehose app on the LAN. Use --peer <ip> for direct testing.", flush=True)
    deadline = time.time() + args.discovery_timeout
    while time.time() < deadline and not state.stop.is_set():
        fresh = [p for p in state.peers.values() if time.time() - p.last_seen < 10.0]
        if fresh:
            peer = sorted(fresh, key=lambda p: p.node_id)[0]
            role = "hose" if node_id > peer.node_id else "sink"
            return role, peer
        time.sleep(0.25)
    return "sink", None


def tcp_server(args: argparse.Namespace, phases: List[Phase], state: SharedState, log_path: Optional[Path], csv_path: Optional[Path]) -> None:
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    srv.bind((args.bind, args.tcp_port))
    srv.listen(2)
    srv.settimeout(0.5)
    log_event(log_path, {"event": "tcp_listening", "port": args.tcp_port}, state)
    phase_by_index = {p.index: p for p in phases}
    while not state.stop.is_set():
        try:
            conn, addr = srv.accept()
        except socket.timeout:
            continue
        except OSError as exc:
            log_event(log_path, {"event": "tcp_accept_error", "error": str(exc)}, state)
            continue
        threading.Thread(
            target=handle_tcp_connection,
            args=(conn, addr, phase_by_index, state, log_path, csv_path),
            daemon=True,
        ).start()


def recv_exact(conn: socket.socket, size: int) -> bytes:
    buf = bytearray()
    while len(buf) < size:
        chunk = conn.recv(size - len(buf))
        if not chunk:
            raise EOFError("tcp closed")
        buf.extend(chunk)
    return bytes(buf)


def handle_tcp_connection(
    conn: socket.socket,
    addr: Tuple[str, int],
    phase_by_index: Dict[int, Phase],
    state: SharedState,
    log_path: Optional[Path],
    csv_path: Optional[Path],
) -> None:
    with conn:
        conn.settimeout(TCP_HELLO_TIMEOUT)
        try:
            header_len = struct.unpack("!I", recv_exact(conn, 4))[0]
            if header_len <= 0 or header_len > MAX_JSON_BYTES:
                raise ValueError(f"bad tcp header length {header_len}")
            header = safe_json_loads(recv_exact(conn, header_len))
            if not header or header.get("magic") != MAGIC:
                raise ValueError("bad tcp header")
            phase_index = int(header["phase"])
            phase = phase_by_index.get(phase_index)
            if not phase:
                raise ValueError(f"unknown tcp phase {phase_index}")
            start = time.monotonic()
            received = 0
            packets = 0
            while time.monotonic() - start < phase.duration + 2.0 and not state.stop.is_set():
                try:
                    frame_header = recv_exact(conn, 8)
                except EOFError:
                    break
                frame_len = struct.unpack("!I", frame_header[:4])[0]
                if frame_len < 8 or frame_len > MAX_UDP_PAYLOAD + 64:
                    break
                payload = recv_exact(conn, frame_len - 8)
                received += len(frame_header) + len(payload)
                packets += 1
            elapsed = max(0.001, time.monotonic() - start)
            result = PhaseResult(
                phase=phase.index,
                role="sink",
                protocol="tcp",
                payload_size=phase.payload_size,
                duration_s=elapsed,
                recv_bytes=received,
                recv_packets=packets,
                mbps=(received * 8.0) / elapsed / 1_000_000.0,
                note=f"from {addr[0]}",
            )
            state.results.append(result)
            write_csv_result(csv_path, result, state)
            log_event(log_path, {"event": "tcp_phase_result", "result": result.__dict__}, state)
            print_result(result)
        except Exception as exc:
            log_event(log_path, {"event": "tcp_connection_error", "peer": addr[0], "error": str(exc)}, state)


def udp_receiver(args: argparse.Namespace, state: SharedState, log_path: Optional[Path], csv_path: Optional[Path]) -> None:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind((args.bind, args.udp_port))
    sock.settimeout(0.25)
    log_event(log_path, {"event": "udp_listening", "port": args.udp_port}, state)
    active: Dict[int, dict] = {}
    last_report = time.monotonic()
    while not state.stop.is_set():
        try:
            data, addr = sock.recvfrom(MAX_UDP_PAYLOAD)
        except socket.timeout:
            if active and time.monotonic() - last_report > 1.0:
                finish_expired_udp_phases(active, state, log_path, csv_path)
                last_report = time.monotonic()
            continue
        except OSError as exc:
            log_event(log_path, {"event": "udp_recv_error", "error": str(exc)}, state)
            continue
        if len(data) < UDP_HEADER_BYTES or data[:8] != UDP_MAGIC:
            continue
        try:
            phase, seq, payload_len, checksum, end_ns = UDP_HEADER_STRUCT.unpack(data[8:UDP_HEADER_BYTES])
        except struct.error:
            continue
        payload = data[UDP_HEADER_BYTES:]
        if payload_len != len(payload):
            continue
        entry = active.setdefault(
            phase,
            {
                "start": time.monotonic(),
                "end": end_ns / 1_000_000_000.0,
                "received": 0,
                "packets": 0,
                "last_seq": -1,
                "lost": 0,
                "out_of_order": 0,
                "checksum_errors": 0,
                "payload_size": payload_len,
                "addr": addr[0],
            },
        )
        if checksum and zlib.crc32(payload) & 0xFFFFFFFF != checksum:
            entry["checksum_errors"] += 1
            continue
        if seq <= entry["last_seq"]:
            entry["out_of_order"] += 1
        elif entry["last_seq"] >= 0 and seq > entry["last_seq"] + 1:
            entry["lost"] += seq - entry["last_seq"] - 1
        entry["last_seq"] = max(entry["last_seq"], seq)
        entry["received"] += len(payload)
        entry["packets"] += 1
        if time.monotonic() >= entry["end"] + 0.5:
            finish_udp_phase(phase, entry, state, log_path, csv_path)
            active.pop(phase, None)
    for phase, entry in list(active.items()):
        finish_udp_phase(phase, entry, state, log_path, csv_path)


def finish_expired_udp_phases(
    active: Dict[int, dict],
    state: SharedState,
    log_path: Optional[Path],
    csv_path: Optional[Path],
) -> None:
    now = time.monotonic()
    for phase, entry in list(active.items()):
        if now >= entry["end"] + 0.5:
            finish_udp_phase(phase, entry, state, log_path, csv_path)
            active.pop(phase, None)


def finish_udp_phase(phase: int, entry: dict, state: SharedState, log_path: Optional[Path], csv_path: Optional[Path]) -> None:
    elapsed = max(0.001, time.monotonic() - entry["start"])
    result = PhaseResult(
        phase=phase,
        role="sink",
        protocol="udp",
        payload_size=int(entry["payload_size"]),
        duration_s=elapsed,
        recv_bytes=int(entry["received"]),
        recv_packets=int(entry["packets"]),
        lost_packets=int(entry["lost"]),
        out_of_order=int(entry["out_of_order"]),
        checksum_errors=int(entry["checksum_errors"]),
        mbps=(int(entry["received"]) * 8.0) / elapsed / 1_000_000.0,
        note=f"from {entry['addr']}",
    )
    state.results.append(result)
    write_csv_result(csv_path, result, state)
    log_event(log_path, {"event": "udp_phase_result", "result": result.__dict__}, state)
    print_result(result)


def run_sink(args: argparse.Namespace, phases: List[Phase], state: SharedState, log_path: Optional[Path], csv_path: Optional[Path]) -> None:
    print(
        f"Firehose sink ready on TCP {args.tcp_port}, UDP {args.udp_port}. "
        "Start another copy in auto mode or with --mode hose --peer <this-ip>.",
        flush=True,
    )
    threading.Thread(target=tcp_server, args=(args, phases, state, log_path, csv_path), daemon=True).start()
    threading.Thread(target=udp_receiver, args=(args, state, log_path, csv_path), daemon=True).start()
    until = time.monotonic() + args.duration + args.discovery_timeout + 20.0
    while time.monotonic() < until and not state.stop.is_set():
        time.sleep(0.25)


def send_tcp_phase(peer: Peer, phase: Phase, args: argparse.Namespace) -> PhaseResult:
    payload = make_payload(phase.payload_size)
    sent = 0
    packets = 0
    started = time.monotonic()
    with socket.create_connection((peer.host, peer.tcp_port), timeout=5.0) as sock:
        sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
        header = json.dumps(
            {
                "magic": MAGIC,
                "phase": phase.index,
                "protocol": "tcp",
                "payload_size": phase.payload_size,
                "duration": phase.duration,
            },
            sort_keys=True,
        ).encode("utf-8")
        sock.sendall(struct.pack("!I", len(header)) + header)
        deadline = time.monotonic() + phase.duration
        seq = 0
        while time.monotonic() < deadline:
            frame = struct.pack("!II", phase.payload_size + 8, seq) + payload
            sock.sendall(frame)
            sent += len(frame)
            packets += 1
            seq += 1
    elapsed = max(0.001, time.monotonic() - started)
    return PhaseResult(
        phase=phase.index,
        role="hose",
        protocol="tcp",
        payload_size=phase.payload_size,
        duration_s=elapsed,
        sent_bytes=sent,
        sent_packets=packets,
        mbps=(sent * 8.0) / elapsed / 1_000_000.0,
        note=f"to {peer.host}",
    )


def make_payload(size: int) -> bytes:
    size = clamp_payload_size(size)
    pattern = b"DefcoinCoreNuFirehose"
    return (pattern * (size // len(pattern) + 1))[:size]


def send_udp_phase(peer: Peer, phase: Phase, args: argparse.Namespace) -> PhaseResult:
    payload = make_payload(phase.payload_size)
    checksum = zlib.crc32(payload) & 0xFFFFFFFF if args.udp_checksum else 0
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sent = 0
    packets = 0
    started = time.monotonic()
    end_monotonic = started + phase.duration
    end_ns = int(end_monotonic * 1_000_000_000)
    seq = 0
    while time.monotonic() < end_monotonic:
        header = UDP_MAGIC + UDP_HEADER_STRUCT.pack(phase.index, seq, len(payload), checksum, end_ns)
        datagram = header + payload
        try:
            sock.sendto(datagram, (peer.host, peer.udp_port))
        except OSError:
            if phase.payload_size > 1472:
                break
            raise
        sent += len(datagram)
        packets += 1
        seq += 1
    elapsed = max(0.001, time.monotonic() - started)
    return PhaseResult(
        phase=phase.index,
        role="hose",
        protocol="udp",
        payload_size=phase.payload_size,
        duration_s=elapsed,
        sent_bytes=sent,
        sent_packets=packets,
        mbps=(sent * 8.0) / elapsed / 1_000_000.0,
        note=f"to {peer.host}",
    )


def run_hose(args: argparse.Namespace, peer: Peer, phases: List[Phase], state: SharedState, log_path: Optional[Path], csv_path: Optional[Path]) -> None:
    print(
        f"Firehose sending to {peer.host} ({peer.hostname or 'unknown host'}). "
        f"{len(phases)} phases over about {sum(p.duration for p in phases):.0f}s.",
        flush=True,
    )
    for phase in phases:
        if state.stop.is_set():
            break
        try:
            if phase.protocol == "tcp":
                result = send_tcp_phase(peer, phase, args)
            else:
                result = send_udp_phase(peer, phase, args)
        except Exception as exc:
            result = PhaseResult(
                phase=phase.index,
                role="hose",
                protocol=phase.protocol,
                payload_size=phase.payload_size,
                duration_s=0.001,
                note=f"error: {exc}",
            )
        state.results.append(result)
        write_csv_result(csv_path, result, state)
        log_event(log_path, {"event": "hose_phase_result", "result": result.__dict__}, state)
        print_result(result)
        time.sleep(args.phase_gap)
    state.stop.set()


def default_log_path() -> Path:
    base = Path.home() / "Library" / "Application Support" / "Defcoin"
    if not base.exists():
        base = Path.cwd()
    return base / f"nu-firehose-{_dt.datetime.now().strftime('%Y%m%d-%H%M%S')}.jsonl"


def parse_args(argv: Optional[Iterable[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Defcoin Core Nu LAN TCP/UDP throughput firehose tester.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--mode", choices=["auto", "sink", "hose"], default="auto")
    parser.add_argument("--peer", help="Direct peer IP/host. Skips LAN auto role selection and sends to this host.")
    parser.add_argument("--peer-tcp-port", type=int, default=0)
    parser.add_argument("--peer-udp-port", type=int, default=0)
    parser.add_argument("--bind", default="0.0.0.0")
    parser.add_argument("--beacon-port", type=int, default=DEFAULT_BEACON_PORT)
    parser.add_argument("--tcp-port", type=int, default=DEFAULT_TCP_PORT)
    parser.add_argument("--udp-port", type=int, default=DEFAULT_UDP_PORT)
    parser.add_argument("--duration", type=float, default=DEFAULT_DURATION_SECONDS)
    parser.add_argument("--switch-seconds", type=float, default=DEFAULT_SWITCH_SECONDS)
    parser.add_argument("--discovery-timeout", type=float, default=20.0)
    parser.add_argument("--phase-gap", type=float, default=0.15)
    parser.add_argument("--size-profile", choices=["practical", "conservative", "jumbo"], default="practical")
    parser.add_argument("--packet-sizes", default="", help="Comma-separated payload sizes. Overrides --size-profile.")
    parser.add_argument("--token", default="", help="Optional shared token so only matching test nodes pair.")
    parser.add_argument("--no-beacon", action="store_true")
    parser.add_argument("--udp-checksum", action="store_true", help="Add a CRC32 payload check to UDP datagrams.")
    parser.add_argument("--log-jsonl", type=Path, default=None)
    parser.add_argument("--csv", type=Path, default=None)
    return parser.parse_args(list(argv) if argv is not None else None)


def main(argv: Optional[Iterable[str]] = None) -> int:
    args = parse_args(argv)
    if args.log_jsonl is None:
        args.log_jsonl = default_log_path()
    node_id = str(uuid.uuid4())
    state = SharedState()
    phases = build_phases(args.duration, args.switch_seconds, size_profile(args.size_profile, args.packet_sizes))

    def stop_handler(_signum, _frame):
        state.stop.set()

    signal.signal(signal.SIGINT, stop_handler)
    signal.signal(signal.SIGTERM, stop_handler)

    log_event(
        args.log_jsonl,
        {
            "event": "start",
            "node_id": node_id,
            "hostname": local_hostname(),
            "mode": args.mode,
            "phases": [phase.__dict__ for phase in phases],
        },
        state,
    )
    print(f"Defcoin Nu firehose node {node_id[:8]} on {local_hostname()}")
    print(f"JSONL log: {args.log_jsonl}")
    if args.csv:
        print(f"CSV results: {args.csv}")
    print("Payload sizes:", ", ".join(str(p.payload_size) for p in phases))

    threading.Thread(target=beacon_sender, args=(args, node_id, state, args.log_jsonl), daemon=True).start()
    threading.Thread(target=beacon_listener, args=(args, node_id, state, args.log_jsonl), daemon=True).start()

    role, peer = choose_peer(args, node_id, state)
    print(f"Selected role: {role}")
    if peer:
        print(f"Peer: {peer.host} {peer.hostname} {peer.os_name}".strip())
    log_event(args.log_jsonl, {"event": "role_selected", "role": role, "peer": peer.__dict__ if peer else None}, state)

    if role == "sink":
        run_sink(args, phases, state, args.log_jsonl, args.csv)
    else:
        if not peer:
            print("No peer selected for hose mode. Use --peer <ip> or run another auto/sink firehose app.", file=sys.stderr)
            return 2
        run_hose(args, peer, phases, state, args.log_jsonl, args.csv)
    log_event(args.log_jsonl, {"event": "stop", "results": [r.__dict__ for r in state.results]}, state)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
