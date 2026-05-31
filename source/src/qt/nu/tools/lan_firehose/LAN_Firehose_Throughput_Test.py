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
from typing import Dict, Iterable, List, Optional, Set, Tuple


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
    incoming: threading.Event = field(default_factory=threading.Event)
    peers: Dict[str, Peer] = field(default_factory=dict)
    peer_log_times: Dict[str, float] = field(default_factory=dict)
    reported_peers: Set[str] = field(default_factory=set)
    results: List[PhaseResult] = field(default_factory=list)
    log_lock: threading.Lock = field(default_factory=threading.Lock)
    csv_lock: threading.Lock = field(default_factory=threading.Lock)
    listener_lock: threading.Lock = field(default_factory=threading.Lock)
    listeners_started: bool = False
    debug_log_path: Optional[Path] = None


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
        json_path = None
    else:
        json_path = path
    lock = state.log_lock if state else threading.Lock()
    with lock:
        if json_path is not None:
            json_path.parent.mkdir(parents=True, exist_ok=True)
            with json_path.open("a", encoding="utf-8") as f:
                f.write(line + "\n")
        if state and state.debug_log_path is not None:
            state.debug_log_path.parent.mkdir(parents=True, exist_ok=True)
            with state.debug_log_path.open("a", encoding="utf-8") as f:
                f.write(format_debug_event(event) + "\n")


def format_debug_event(event: dict) -> str:
    name = str(event.get("event", "event"))
    prefix = f"[{now_iso()}] {name}"
    if name == "start":
        return f"{prefix}: mode={event.get('mode')} host={event.get('hostname')} node={str(event.get('node_id', ''))[:8]}"
    if name == "peer_seen":
        peer = event.get("peer") if isinstance(event.get("peer"), dict) else {}
        return f"{prefix}: {peer.get('host', '?')} {peer.get('hostname', '')} {peer.get('os_name', '')} node={str(peer.get('node_id', ''))[:8]} first={event.get('first_seen')}"
    if name in ("discovery_role_decision", "role_selected", "auto_hose_start", "auto_sink_wait", "auto_sink_promoted_to_hose"):
        peer = event.get("peer") if isinstance(event.get("peer"), dict) else {}
        return f"{prefix}: role={event.get('role', '')} peer={peer.get('host', '')} {peer.get('hostname', '')} local={str(event.get('local_node_id', ''))[:8]} peer_node={str(event.get('peer_node_id', peer.get('node_id', '')))[:8]}"
    if name in ("tcp_listening", "udp_listening", "beacon_sender_started", "beacon_listener_started"):
        return f"{prefix}: bind={event.get('bind', '0.0.0.0')} port={event.get('port')}"
    if name in ("tcp_bind_error", "udp_bind_error", "beacon_bind_error", "beacon_send_error", "tcp_accept_error", "tcp_connection_error", "udp_recv_error"):
        return f"{prefix}: {event.get('error')}"
    if name in ("tcp_phase_result", "udp_phase_result", "hose_phase_result"):
        result = event.get("result") if isinstance(event.get("result"), dict) else {}
        return (
            f"{prefix}: phase={result.get('phase')} role={result.get('role')} "
            f"{str(result.get('protocol', '')).upper()} payload={result.get('payload_size')} "
            f"sent={format_bytes(int(result.get('sent_bytes') or 0))} recv={format_bytes(int(result.get('recv_bytes') or 0))} "
            f"rate={float(result.get('mbps') or 0.0):.2f} Mb/s note={result.get('note', '')}"
        )
    if name == "stop":
        results = event.get("results") if isinstance(event.get("results"), list) else []
        return f"{prefix}: result_count={len(results)}"
    details = " ".join(f"{k}={v}" for k, v in event.items() if k != "event" and k != "phases")
    return f"{prefix}: {details}".rstrip()


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
            "mode": args.mode,
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
        log_event(log_path, {"event": "beacon_disabled"}, state)
        return
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    payload = make_beacon(node_id, args)
    log_event(log_path, {"event": "beacon_sender_started", "port": args.beacon_port}, state)
    sent_count = 0
    while not state.stop.is_set():
        for target in ("255.255.255.255",):
            try:
                sock.sendto(payload, (target, args.beacon_port))
                sent_count += 1
                if sent_count == 1 or sent_count % 10 == 0:
                    log_event(log_path, {"event": "beacon_sent", "target": target, "port": args.beacon_port, "count": sent_count}, state)
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
    log_event(log_path, {"event": "beacon_listener_started", "bind": args.bind, "port": args.beacon_port}, state)
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
        now = time.time()
        peer = Peer(
            node_id=peer_id,
            host=addr[0],
            hostname=str(obj.get("hostname", "")),
            tcp_port=int(obj.get("tcp_port", args.tcp_port)),
            udp_port=int(obj.get("udp_port", args.udp_port)),
            os_name=str(obj.get("os", "")),
            last_seen=now,
        )
        first_seen = peer_id not in state.peers
        state.peers[peer_id] = peer
        last_log = state.peer_log_times.get(peer_id, 0.0)
        if first_seen or now - last_log >= 10.0:
            state.peer_log_times[peer_id] = now
            log_event(log_path, {"event": "peer_seen", "first_seen": first_seen, "peer": peer.__dict__}, state)
        if peer_id not in state.reported_peers:
            state.reported_peers.add(peer_id)
            print(f"Peer seen: {peer.host} {peer.hostname} {peer.os_name}".strip(), flush=True)


def choose_peer(args: argparse.Namespace, node_id: str, state: SharedState, log_path: Optional[Path]) -> Tuple[str, Optional[Peer]]:
    if args.peer:
        peer = Peer(
            node_id=args.peer_node_id or "manual-peer",
            host=args.peer,
            hostname=args.peer_hostname or args.peer,
            tcp_port=args.peer_tcp_port or args.tcp_port,
            udp_port=args.peer_udp_port or args.udp_port,
            last_seen=time.time(),
        )
        role = args.mode
        if role == "auto":
            role = "hose" if peer.node_id == "manual-peer" or node_id > peer.node_id else "sink"
        log_event(log_path, {"event": "manual_peer_selected", "role": role, "peer": peer.__dict__}, state)
        return role, peer
    if args.mode in ("sink", "hose"):
        log_event(log_path, {"event": "manual_role_selected", "role": args.mode}, state)
        return args.mode, None
    print("Waiting for another firehose app on the LAN. Use --peer <ip> for direct testing.", flush=True)
    log_event(log_path, {"event": "discovery_wait_start", "timeout_s": args.discovery_timeout, "local_node_id": node_id}, state)
    deadline = time.time() + args.discovery_timeout
    while time.time() < deadline and not state.stop.is_set():
        fresh = [p for p in state.peers.values() if time.time() - p.last_seen < 10.0]
        if fresh:
            peer = sorted(fresh, key=lambda p: p.node_id)[0]
            role = "hose" if node_id > peer.node_id else "sink"
            log_event(
                log_path,
                {
                    "event": "discovery_role_decision",
                    "role": role,
                    "local_node_id": node_id,
                    "peer_node_id": peer.node_id,
                    "peer": peer.__dict__,
                    "fresh_peer_count": len(fresh),
                },
                state,
            )
            return role, peer
        time.sleep(0.25)
    log_event(log_path, {"event": "discovery_timeout", "fallback_role": "sink", "known_peer_count": len(state.peers)}, state)
    return "sink", None


def start_sink_listeners(
    args: argparse.Namespace,
    phases: List[Phase],
    state: SharedState,
    log_path: Optional[Path],
    csv_path: Optional[Path],
) -> None:
    with state.listener_lock:
        if state.listeners_started:
            return
        state.listeners_started = True
    threading.Thread(target=tcp_server, args=(args, phases, state, log_path, csv_path), daemon=True).start()
    threading.Thread(target=udp_receiver, args=(args, state, log_path, csv_path), daemon=True).start()


def wait_for_sink_completion(args: argparse.Namespace, state: SharedState) -> None:
    until = time.monotonic() + args.duration + args.discovery_timeout + 20.0
    while time.monotonic() < until and not state.stop.is_set():
        time.sleep(0.25)


def peer_allowed(args: argparse.Namespace, host: str) -> bool:
    allowed = getattr(args, "accept_peer", None) or []
    if not allowed:
        return True
    return host in set(allowed)


def tcp_server(args: argparse.Namespace, phases: List[Phase], state: SharedState, log_path: Optional[Path], csv_path: Optional[Path]) -> None:
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        srv.bind((args.bind, args.tcp_port))
    except OSError as exc:
        message = f"TCP listen failed on {args.bind}:{args.tcp_port}: {exc}"
        print(message, flush=True)
        log_event(log_path, {"event": "tcp_bind_error", "bind": args.bind, "port": args.tcp_port, "error": str(exc)}, state)
        state.stop.set()
        return
    srv.listen(2)
    srv.settimeout(0.5)
    log_event(log_path, {"event": "tcp_listening", "port": args.tcp_port}, state)
    phase_by_index = {p.index: p for p in phases}
    while not state.stop.is_set():
        try:
            conn, addr = srv.accept()
            if not peer_allowed(args, addr[0]):
                log_event(log_path, {"event": "tcp_ignored_peer", "peer": addr[0], "port": addr[1]}, state)
                conn.close()
                continue
            state.incoming.set()
            log_event(log_path, {"event": "tcp_incoming", "peer": addr[0], "port": addr[1]}, state)
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
    try:
        sock.bind((args.bind, args.udp_port))
    except OSError as exc:
        message = f"UDP listen failed on {args.bind}:{args.udp_port}: {exc}"
        print(message, flush=True)
        log_event(log_path, {"event": "udp_bind_error", "bind": args.bind, "port": args.udp_port, "error": str(exc)}, state)
        state.stop.set()
        return
    sock.settimeout(0.25)
    log_event(log_path, {"event": "udp_listening", "port": args.udp_port}, state)
    active: Dict[Tuple[str, int], dict] = {}
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
        if not peer_allowed(args, addr[0]):
            log_event(log_path, {"event": "udp_ignored_peer", "peer": addr[0], "port": addr[1]}, state)
            continue
        if len(data) < UDP_HEADER_BYTES or data[:8] != UDP_MAGIC:
            continue
        if not state.incoming.is_set():
            state.incoming.set()
            log_event(log_path, {"event": "udp_incoming", "peer": addr[0], "port": addr[1]}, state)
        try:
            phase, seq, payload_len, checksum, end_ns = UDP_HEADER_STRUCT.unpack(data[8:UDP_HEADER_BYTES])
        except struct.error:
            continue
        payload = data[UDP_HEADER_BYTES:]
        if payload_len != len(payload):
            continue
        phase_key = (addr[0], phase)
        entry = active.setdefault(
            phase_key,
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
            active.pop(phase_key, None)
    for (_host, phase), entry in list(active.items()):
        finish_udp_phase(phase, entry, state, log_path, csv_path)


def finish_expired_udp_phases(
    active: Dict[int, dict],
    state: SharedState,
    log_path: Optional[Path],
    csv_path: Optional[Path],
) -> None:
    now = time.monotonic()
    for key, entry in list(active.items()):
        phase = key[1] if isinstance(key, tuple) else key
        if now >= entry["end"] + 0.5:
            finish_udp_phase(phase, entry, state, log_path, csv_path)
            active.pop(key, None)


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
    start_sink_listeners(args, phases, state, log_path, csv_path)
    wait_for_sink_completion(args, state)


def send_tcp_phase(peer: Peer, phase: Phase, args: argparse.Namespace) -> PhaseResult:
    payload = make_payload(phase.payload_size)
    sent = 0
    packets = 0
    started = time.monotonic()
    connect_deadline = time.monotonic() + args.connect_retry_seconds
    while True:
        try:
            sock = socket.create_connection((peer.host, peer.tcp_port), timeout=5.0)
            break
        except OSError:
            if time.monotonic() >= connect_deadline:
                raise
            time.sleep(0.25)
    with sock:
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


def run_hose(args: argparse.Namespace, peer: Peer, phases: List[Phase], state: SharedState, log_path: Optional[Path], csv_path: Optional[Path], stop_when_done: bool = True) -> None:
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
    if stop_when_done:
        state.stop.set()


def run_hose_many(args: argparse.Namespace, peers: List[Peer], phases: List[Phase], state: SharedState, log_path: Optional[Path], csv_path: Optional[Path]) -> None:
    print(f"Firehose sending to {len(peers)} testers in sequence.", flush=True)
    log_event(log_path, {"event": "hose_many_start", "peers": [peer.__dict__ for peer in peers]}, state)
    for peer in peers:
        if state.stop.is_set():
            break
        run_hose(args, peer, phases, state, log_path, csv_path, stop_when_done=False)
    state.stop.set()


def run_auto(args: argparse.Namespace, role: str, peer: Optional[Peer], phases: List[Phase], state: SharedState, log_path: Optional[Path], csv_path: Optional[Path]) -> int:
    # Auto nodes always listen. This makes one-way discovery and role-election
    # races recoverable, while still letting one side become the primary sender.
    start_sink_listeners(args, phases, state, log_path, csv_path)
    if peer is None:
        print("No auto peer discovered. Staying in sink mode so a later/manual hose can connect.", flush=True)
        log_event(log_path, {"event": "auto_no_peer_sink_only"}, state)
        wait_for_sink_completion(args, state)
        return 0
    if role == "hose":
        log_event(log_path, {"event": "auto_hose_start", "peer": peer.__dict__}, state)
        time.sleep(args.auto_hose_delay)
        run_hose(args, peer, phases, state, log_path, csv_path)
        return 0

    print(
        f"Auto selected sink for {peer.host}; waiting {args.auto_sink_grace:.1f}s for incoming traffic before fallback.",
        flush=True,
    )
    log_event(log_path, {"event": "auto_sink_wait", "peer": peer.__dict__, "grace_s": args.auto_sink_grace}, state)
    if state.incoming.wait(args.auto_sink_grace):
        log_event(log_path, {"event": "auto_sink_incoming_detected"}, state)
        wait_for_sink_completion(args, state)
        return 0

    print("No incoming traffic arrived; promoting this node to hose so auto mode cannot stall.", flush=True)
    log_event(log_path, {"event": "auto_sink_promoted_to_hose", "peer": peer.__dict__}, state)
    run_hose(args, peer, phases, state, log_path, csv_path)
    return 0


def default_log_path() -> Path:
    base = Path.home() / "Library" / "Application Support" / "Defcoin"
    if not base.exists():
        base = Path.cwd()
    return base / f"nu-firehose-{_dt.datetime.now().strftime('%Y%m%d-%H%M%S')}.jsonl"


def parse_peers_json(value: str, args: argparse.Namespace) -> List[Peer]:
    if not value:
        return []
    try:
        raw = json.loads(value)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Bad --peers-json: {exc}") from exc
    if not isinstance(raw, list):
        raise SystemExit("Bad --peers-json: expected a JSON list")
    peers: List[Peer] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        host = str(item.get("host", "")).strip()
        if not host:
            continue
        peers.append(
            Peer(
                node_id=str(item.get("node_id", "")) or f"peer-{len(peers) + 1}",
                host=host,
                hostname=str(item.get("hostname", host)),
                tcp_port=int(item.get("tcp_port", args.tcp_port) or args.tcp_port),
                udp_port=int(item.get("udp_port", args.udp_port) or args.udp_port),
                os_name=str(item.get("os_name", item.get("os", ""))),
                last_seen=time.time(),
            )
        )
    return peers


def parse_args(argv: Optional[Iterable[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Defcoin Core Nu LAN TCP/UDP throughput firehose tester.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--mode", choices=["auto", "sink", "hose"], default="auto")
    parser.add_argument("--peer", help="Direct peer IP/host. Skips LAN auto role selection and sends to this host.")
    parser.add_argument("--peer-node-id", default="")
    parser.add_argument("--peer-hostname", default="")
    parser.add_argument("--peer-tcp-port", type=int, default=0)
    parser.add_argument("--peer-udp-port", type=int, default=0)
    parser.add_argument("--peers-json", default="", help="JSON list of peer objects for spraying several testers sequentially.")
    parser.add_argument("--accept-peer", action="append", default=[], help="Restrict Catch mode to a specific incoming peer IP. Repeat for more peers.")
    parser.add_argument("--bind", default="0.0.0.0")
    parser.add_argument("--beacon-port", type=int, default=DEFAULT_BEACON_PORT)
    parser.add_argument("--tcp-port", type=int, default=DEFAULT_TCP_PORT)
    parser.add_argument("--udp-port", type=int, default=DEFAULT_UDP_PORT)
    parser.add_argument("--duration", type=float, default=DEFAULT_DURATION_SECONDS)
    parser.add_argument("--switch-seconds", type=float, default=DEFAULT_SWITCH_SECONDS)
    parser.add_argument("--discovery-timeout", type=float, default=20.0)
    parser.add_argument("--auto-sink-grace", type=float, default=8.0, help="In auto mode, a selected sink promotes to hose if no test traffic arrives within this many seconds.")
    parser.add_argument("--auto-hose-delay", type=float, default=0.75, help="Small auto-mode delay before hosing so the peer can finish opening listeners.")
    parser.add_argument("--connect-retry-seconds", type=float, default=10.0, help="How long TCP hose mode retries connecting before marking a phase failed.")
    parser.add_argument("--phase-gap", type=float, default=0.15)
    parser.add_argument("--size-profile", choices=["practical", "conservative", "jumbo"], default="practical")
    parser.add_argument("--packet-sizes", default="", help="Comma-separated payload sizes. Overrides --size-profile.")
    parser.add_argument("--token", default="", help="Optional shared token so only matching test nodes pair.")
    parser.add_argument("--no-beacon", action="store_true")
    parser.add_argument("--udp-checksum", action="store_true", help="Add a CRC32 payload check to UDP datagrams.")
    parser.add_argument("--log-jsonl", type=Path, default=None)
    parser.add_argument("--debug-log", type=Path, default=None, help="Human-readable text log suitable for TextEdit/Console.")
    parser.add_argument("--csv", type=Path, default=None)
    return parser.parse_args(list(argv) if argv is not None else None)


def main(argv: Optional[Iterable[str]] = None) -> int:
    args = parse_args(argv)
    if args.log_jsonl is None:
        args.log_jsonl = default_log_path()
    if args.debug_log is None and args.log_jsonl is not None:
        args.debug_log = args.log_jsonl.with_suffix(".log")
    node_id = str(uuid.uuid4())
    state = SharedState()
    state.debug_log_path = args.debug_log
    phases = build_phases(args.duration, args.switch_seconds, size_profile(args.size_profile, args.packet_sizes))
    explicit_peers = parse_peers_json(args.peers_json, args)

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
    if args.debug_log:
        print(f"Text log: {args.debug_log}")
    if args.csv:
        print(f"CSV results: {args.csv}")
    print("Payload sizes:", ", ".join(str(p.payload_size) for p in phases))

    threading.Thread(target=beacon_sender, args=(args, node_id, state, args.log_jsonl), daemon=True).start()
    threading.Thread(target=beacon_listener, args=(args, node_id, state, args.log_jsonl), daemon=True).start()

    if explicit_peers:
        role, peer = "hose", explicit_peers[0]
        log_event(args.log_jsonl, {"event": "manual_peer_list_selected", "peers": [p.__dict__ for p in explicit_peers]}, state)
    else:
        role, peer = choose_peer(args, node_id, state, args.log_jsonl)
    print(f"Selected role: {role}")
    if peer:
        print(f"Peer: {peer.host} {peer.hostname} {peer.os_name}".strip())
    log_event(args.log_jsonl, {"event": "role_selected", "role": role, "peer": peer.__dict__ if peer else None}, state)

    if explicit_peers:
        run_hose_many(args, explicit_peers, phases, state, args.log_jsonl, args.csv)
        return_code = 0
    elif args.mode == "auto":
        return_code = run_auto(args, role, peer, phases, state, args.log_jsonl, args.csv)
    elif role == "sink":
        run_sink(args, phases, state, args.log_jsonl, args.csv)
        return_code = 0
    else:
        if not peer:
            print("No peer selected for hose mode. Use --peer <ip> or run another auto/sink firehose app.", file=sys.stderr)
            return 2
        run_hose(args, peer, phases, state, args.log_jsonl, args.csv)
        return_code = 0
    log_event(args.log_jsonl, {"event": "stop", "results": [r.__dict__ for r in state.results]}, state)
    return return_code


if __name__ == "__main__":
    raise SystemExit(main())
