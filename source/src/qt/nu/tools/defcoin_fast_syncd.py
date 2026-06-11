#!/usr/bin/env python3
"""Headless Defcoin Core Nu UDP Fast Sync responder.

This daemon serves active-chain raw blocks from a local defcoind RPC endpoint
using the same UDP chunk protocol as the Nu desktop helper. It is intentionally
responder-only: the requesting Nu wallet chooses probe size and validates every
received block through Core before accepting it.
"""

import argparse
import base64
import contextlib
import hashlib
import http.client
import ipaddress
import json
import logging
import os
import re
import selectors
import socket
import sys
import time
import uuid
from collections import OrderedDict

PREFIX = b"DFCLAN1\n"
CAPABILITY = "defcoin-nu-udp-fast-sync-v1"
PROTOCOL_VERSION = 1
FAST_SYNC_SERVICE_BIT = 1 << 29

UDP_PORT = 10334
SAFE_DATAGRAM_BYTES = 1232
INTERNET_PROBE_DATAGRAM_BYTES = 1472
MAX_DATAGRAM_BYTES = 16640
MAX_HEADER_BYTES = 768
MIN_CHUNK_BYTES = 128
MAX_CHUNK_BYTES = MAX_DATAGRAM_BYTES - 448
MAX_CHUNKS_PER_BLOCK = 65536
MAX_BLOCK_BYTES = 8 * 1024 * 1024
MIN_REQUEST_INTERVAL_SECONDS = 0.25
MAX_CACHE_BLOCKS = 32
PEER_ALLOWLIST_REFRESH_SECONDS = 10
MAX_IGNORED_LOG_INTERVAL_SECONDS = 60
DEFAULT_NODE_ID_FILE = "/var/lib/defcoin-fast-syncd/node_unique_id"


def checksum(data):
    return hashlib.sha256(data).hexdigest()


def is_private_or_local(host):
    try:
        address = ipaddress.ip_address(normalize_ip(host))
        return address.is_private or address.is_loopback or address.is_link_local
    except ValueError:
        pass
    try:
        packed = socket.inet_pton(socket.AF_INET, host)
        first, second = packed[0], packed[1]
        return (
            first == 10
            or (first == 172 and 16 <= second <= 31)
            or (first == 192 and second == 168)
            or (first == 169 and second == 254)
            or first == 127
        )
    except OSError:
        pass
    try:
        packed = socket.inet_pton(socket.AF_INET6, host)
        return (
            host == "::1"
            or (packed[0] & 0xFE) == 0xFC
            or (packed[0] == 0xFE and (packed[1] & 0xC0) == 0x80)
        )
    except OSError:
        return False


def normalize_ip(host):
    if not isinstance(host, str):
        return ""
    value = host.strip()
    if value.startswith("[") and "]" in value:
        value = value[1 : value.find("]")]
    if value.startswith("::ffff:"):
        maybe_v4 = value[7:]
        try:
            ipaddress.ip_address(maybe_v4)
            return maybe_v4
        except ValueError:
            pass
    return value


def peer_host_from_addr(addr):
    if not isinstance(addr, str) or not addr:
        return ""
    value = addr.strip()
    if value.startswith("[") and "]" in value:
        return normalize_ip(value[1 : value.find("]")])
    if value.count(":") == 1:
        return normalize_ip(value.rsplit(":", 1)[0])
    return normalize_ip(value)


def is_loopback(host):
    try:
        return ipaddress.ip_address(normalize_ip(host)).is_loopback
    except ValueError:
        return False


def peer_advertises_fast_sync_service(peer):
    services = peer.get("services")
    try:
        services_value = (
            int(services.strip() or "0", 16) if isinstance(services, str) else int(services or 0)
        )
    except (TypeError, ValueError):
        return False
    return bool(services_value & FAST_SYNC_SERVICE_BIT)


def load_or_create_node_unique_id(path):
    if path:
        try:
            with open(path, encoding="utf-8") as handle:
                value = handle.read().strip().lower()
            if re.match(r"^[0-9a-f]{32}$", value):
                return value
        except OSError:
            pass
    value = uuid.uuid4().hex
    if path:
        try:
            os.makedirs(os.path.dirname(path), exist_ok=True)
            with open(path, "w", encoding="utf-8") as handle:
                handle.write(value + "\n")
            os.chmod(path, 0o600)
        except OSError as exc:
            logging.warning("could not persist node_unique_id at %s: %s", path, exc)
    return value


def chunk_bytes_for_datagram(max_datagram):
    return max(MIN_CHUNK_BYTES, min(MAX_CHUNK_BYTES, max_datagram - 448))


def build_datagram(header, payload=b"", max_datagram=SAFE_DATAGRAM_BYTES):
    if len(payload) > MAX_CHUNK_BYTES:
        return None
    copy = dict(header)
    copy["payload_size"] = len(payload)
    encoded = json.dumps(copy, separators=(",", ":"), sort_keys=True).encode("utf-8")
    if not encoded or len(encoded) > MAX_HEADER_BYTES:
        return None
    datagram = PREFIX + encoded + b"\n\n" + payload
    if len(datagram) > max(576, min(MAX_DATAGRAM_BYTES, max_datagram)):
        return None
    return datagram


def parse_datagram(datagram):
    if len(datagram) < len(PREFIX) + 2 or len(datagram) > MAX_DATAGRAM_BYTES:
        return None, None
    if not datagram.startswith(PREFIX):
        return None, None
    split = datagram.find(b"\n\n", len(PREFIX))
    if split < 0:
        return None, None
    header_bytes = datagram[len(PREFIX) : split]
    if not header_bytes or len(header_bytes) > MAX_HEADER_BYTES:
        return None, None
    try:
        header = json.loads(header_bytes.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None, None
    if not isinstance(header, dict):
        return None, None
    payload = datagram[split + 2 :]
    payload_size = header.get("payload_size")
    if not isinstance(payload_size, int) or payload_size < 0 or payload_size > MAX_CHUNK_BYTES:
        return None, None
    if payload_size != len(payload):
        return None, None
    if header.get("version") != PROTOCOL_VERSION:
        return None, None
    if header.get("capability") != CAPABILITY:
        return None, None
    return header, payload


class RpcClient:
    def __init__(self, conf_path):
        settings = self._read_conf(conf_path)
        self.host = settings.get("rpcconnect", "127.0.0.1")
        self.port = int(settings.get("rpcport", "1335"))
        user = settings.get("rpcuser", "")
        password = settings.get("rpcpassword", "")
        token = base64.b64encode(f"{user}:{password}".encode()).decode("ascii")
        self.auth_header = "Basic " + token
        self.request_id = 0

    @staticmethod
    def _read_conf(path):
        settings = {}
        with open(path, encoding="utf-8") as handle:
            for raw in handle:
                line = raw.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                key, value = line.split("=", 1)
                settings[key.strip()] = value.strip()
        return settings

    def call(self, method, params=None):
        self.request_id += 1
        body = json.dumps(
            {
                "jsonrpc": "1.0",
                "id": self.request_id,
                "method": method,
                "params": params or [],
            }
        ).encode("utf-8")
        conn = http.client.HTTPConnection(self.host, self.port, timeout=15)
        try:
            conn.request(
                "POST",
                "/",
                body,
                {
                    "Authorization": self.auth_header,
                    "Content-Type": "application/json",
                    "Content-Length": str(len(body)),
                },
            )
            response = conn.getresponse()
            payload = response.read()
        finally:
            conn.close()
        if response.status != 200:
            raise RuntimeError(f"RPC HTTP {response.status}: {payload[:120]!r}")
        decoded = json.loads(payload.decode("utf-8"))
        if decoded.get("error"):
            raise RuntimeError(f"RPC {method} error: {decoded['error']}")
        return decoded.get("result")


class FastSyncDaemon:
    def __init__(
        self,
        rpc,
        bind,
        port,
        require_nu_peer=True,
        allow_loopback=True,
        node_unique_id="",
    ):
        self.rpc = rpc
        self.bind = bind
        self.port = port
        self.require_nu_peer = require_nu_peer
        self.allow_loopback = allow_loopback
        self.node_unique_id = node_unique_id
        self.selector = selectors.DefaultSelector()
        self.block_cache = OrderedDict()
        self.last_request_by_host = {}
        self.allowed_fast_sync_hosts = {}
        self.allowed_fast_sync_hosts_refreshed = 0.0
        self.last_ignore_log_by_host = {}
        self.stats = {
            "requests": 0,
            "probes": 0,
            "served_blocks": 0,
            "sent_datagrams": 0,
            "sent_bytes": 0,
            "dropped": 0,
            "ignored_non_fast_sync_peer": 0,
            "peer_allowlist_refreshes": 0,
        }

    def open_sockets(self):
        families = [socket.AF_INET]
        if self.bind in ("", "::", "0.0.0.0"):
            families.append(socket.AF_INET6)
        for family in families:
            sock = socket.socket(family, socket.SOCK_DGRAM)
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            if family == socket.AF_INET6:
                with contextlib.suppress(OSError):
                    sock.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
                sock.bind(("::", self.port))
            else:
                sock.bind((self.bind if self.bind else "0.0.0.0", self.port))
            sock.setblocking(False)
            self.selector.register(sock, selectors.EVENT_READ)
            logging.info("listening udp %s:%s", sock.getsockname()[0], self.port)

    def run(self):
        self.open_sockets()
        last_stats = time.time()
        while True:
            for key, _ in self.selector.select(timeout=1.0):
                self.handle_socket(key.fileobj)
            now = time.time()
            if now - last_stats >= 60:
                last_stats = now
                logging.info("stats %s", self.stats)

    def handle_socket(self, sock):
        try:
            datagram, sender = sock.recvfrom(MAX_DATAGRAM_BYTES + 1)
        except OSError:
            return
        if len(datagram) > MAX_DATAGRAM_BYTES:
            self.stats["dropped"] += 1
            return
        header, payload = parse_datagram(datagram)
        if header is None or payload:
            self.stats["dropped"] += 1
            return
        message_type = header.get("type")
        if message_type not in ("probe", "request-block"):
            self.stats["dropped"] += 1
            return
        try:
            if message_type == "probe":
                self.handle_probe(sock, sender, header)
            else:
                self.handle_request(sock, sender, header)
        except Exception as exc:
            self.stats["dropped"] += 1
            logging.warning("request from %s failed: %s", sender[0], exc)

    def throttle_sender(self, host, now):
        last = self.last_request_by_host.get(host, 0.0)
        if now - last < MIN_REQUEST_INTERVAL_SECONDS:
            return False
        self.last_request_by_host[host] = now
        if len(self.last_request_by_host) > 2048:
            self.last_request_by_host = {
                key: value for key, value in self.last_request_by_host.items() if now - value < 300
            }
        return True

    def handle_probe(self, sock, sender, header):
        host = normalize_ip(sender[0])
        now = time.time()
        if not self.throttle_sender(host, now):
            return

        request_id = header.get("id", "")
        if not isinstance(request_id, str) or not re.match(r"^[0-9A-Fa-f]{32}$", request_id):
            return
        if not self.is_allowed_fast_sync_client(host, now):
            self.stats["ignored_non_fast_sync_peer"] += 1
            self.log_ignored_client(host, now)
            return

        sender_cap = (
            MAX_DATAGRAM_BYTES if is_private_or_local(host) else INTERNET_PROBE_DATAGRAM_BYTES
        )
        peer_max_datagram = max(
            576, min(sender_cap, int(header.get("max_datagram", SAFE_DATAGRAM_BYTES)))
        )
        requested_chunk = int(
            header.get("chunk_bytes", chunk_bytes_for_datagram(peer_max_datagram))
        )
        peer_chunk_bytes = max(
            MIN_CHUNK_BYTES,
            min(MAX_CHUNK_BYTES, requested_chunk, chunk_bytes_for_datagram(peer_max_datagram)),
        )
        try:
            tip = int(self.rpc.call("getblockcount"))
        except Exception:
            tip = 0

        ack = {
            "type": "probe-ack",
            "version": PROTOCOL_VERSION,
            "capability": CAPABILITY,
            "id": request_id,
            "node_unique_id": self.node_unique_id,
            "port": self.port,
            "tip": tip,
            "max_datagram": peer_max_datagram,
            "chunk_bytes": peer_chunk_bytes,
            "observed_sender_port": int(sender[1]),
        }
        out = build_datagram(ack, b"", SAFE_DATAGRAM_BYTES)
        if out is None:
            self.stats["dropped"] += 1
            return
        sent = sock.sendto(out, sender)
        if sent > 0:
            self.stats["probes"] += 1
            self.stats["sent_datagrams"] += 1
            self.stats["sent_bytes"] += sent
            logging.info(
                "acked probe host=%s datagram=%s chunk=%s",
                host,
                peer_max_datagram,
                peer_chunk_bytes,
            )

    def handle_request(self, sock, sender, header):
        host = normalize_ip(sender[0])
        now = time.time()
        if not self.throttle_sender(host, now):
            return

        request_id = header.get("id", "")
        if not isinstance(request_id, str) or not re.match(r"^[0-9A-Fa-f]{32}$", request_id):
            return
        height = header.get("height")
        if not isinstance(height, int) or height < 0:
            return

        if not self.is_allowed_fast_sync_client(host, now):
            self.stats["ignored_non_fast_sync_peer"] += 1
            self.log_ignored_client(host, now)
            return

        tip = int(self.rpc.call("getblockcount"))
        if height > tip:
            return

        sender_cap = (
            MAX_DATAGRAM_BYTES if is_private_or_local(host) else INTERNET_PROBE_DATAGRAM_BYTES
        )
        peer_max_datagram = max(
            576, min(sender_cap, int(header.get("max_datagram", SAFE_DATAGRAM_BYTES)))
        )
        requested_chunk = int(
            header.get("chunk_bytes", chunk_bytes_for_datagram(peer_max_datagram))
        )
        peer_chunk_bytes = max(
            MIN_CHUNK_BYTES,
            min(MAX_CHUNK_BYTES, requested_chunk, chunk_bytes_for_datagram(peer_max_datagram)),
        )

        raw_hash, raw_block = self.raw_block(height)
        if not raw_block or len(raw_block) > MAX_BLOCK_BYTES:
            return
        total_chunks = (len(raw_block) + peer_chunk_bytes - 1) // peer_chunk_bytes
        if total_chunks <= 0 or total_chunks > MAX_CHUNKS_PER_BLOCK:
            return

        self.stats["requests"] += 1
        block_sum = checksum(raw_block)
        # Reply to the exact source tuple. Reconstructing an address from the
        # normalized host can lose IPv6 scope/flow fields and is less precise.
        reply_address = sender
        sent_any = False
        for seq in range(total_chunks):
            chunk = raw_block[seq * peer_chunk_bytes : (seq + 1) * peer_chunk_bytes]
            chunk_header = {
                "type": "block-chunk",
                "version": PROTOCOL_VERSION,
                "capability": CAPABILITY,
                "id": request_id,
                "height": height,
                "hash": raw_hash,
                "seq": seq,
                "total": total_chunks,
                "block_size": len(raw_block),
                "chunk_bytes": peer_chunk_bytes,
                "max_datagram": peer_max_datagram,
                "block_checksum": block_sum,
                "chunk_checksum": checksum(chunk),
            }
            out = build_datagram(chunk_header, chunk, peer_max_datagram)
            if out is None:
                return
            try:
                sent = sock.sendto(out, reply_address)
            except OSError as exc:
                logging.warning("send to %s failed: %s", reply_address, exc)
                return
            if sent > 0:
                sent_any = True
                self.stats["sent_datagrams"] += 1
                self.stats["sent_bytes"] += sent
        if sent_any:
            self.stats["served_blocks"] += 1
            logging.info(
                "served height=%s host=%s chunks=%s datagram=%s chunk=%s bytes=%s",
                height,
                host,
                total_chunks,
                peer_max_datagram,
                peer_chunk_bytes,
                len(raw_block),
            )

    def log_ignored_client(self, host, now):
        last = self.last_ignore_log_by_host.get(host, 0.0)
        if now - last < MAX_IGNORED_LOG_INTERVAL_SECONDS:
            return
        self.last_ignore_log_by_host[host] = now
        logging.info(
            "ignored udp request from host without connected Fast Sync service bit=%s", host
        )
        if len(self.last_ignore_log_by_host) > 2048:
            self.last_ignore_log_by_host = {
                key: value
                for key, value in self.last_ignore_log_by_host.items()
                if now - value < 600
            }

    def is_allowed_fast_sync_client(self, host, now):
        if not self.require_nu_peer:
            return True
        if self.allow_loopback and is_loopback(host):
            return True
        self.refresh_allowed_fast_sync_hosts(now)
        return host in self.allowed_fast_sync_hosts

    def refresh_allowed_fast_sync_hosts(self, now):
        if now - self.allowed_fast_sync_hosts_refreshed < PEER_ALLOWLIST_REFRESH_SECONDS:
            return
        self.allowed_fast_sync_hosts_refreshed = now
        allowed = {}
        try:
            peers = self.rpc.call("getpeerinfo")
        except Exception as exc:
            logging.warning("could not refresh Fast Sync peer allowlist: %s", exc)
            self.allowed_fast_sync_hosts = {}
            return
        if not isinstance(peers, list):
            self.allowed_fast_sync_hosts = {}
            return
        for peer in peers:
            if not isinstance(peer, dict):
                continue
            has_fast_sync_service = peer_advertises_fast_sync_service(peer)
            if not has_fast_sync_service:
                continue
            host = peer_host_from_addr(peer.get("addr", ""))
            if host:
                allowed[host] = "service-bit"
        self.allowed_fast_sync_hosts = allowed
        self.stats["peer_allowlist_refreshes"] += 1
        logging.debug("Fast Sync UDP peer allowlist hosts=%s", sorted(allowed.keys()))

    def raw_block(self, height):
        cached = self.block_cache.get(height)
        if cached:
            self.block_cache.move_to_end(height)
            return cached
        block_hash = self.rpc.call("getblockhash", [height])
        block_hex = self.rpc.call("getblock", [block_hash, 0])
        raw = bytes.fromhex(block_hex)
        cached = (block_hash, raw)
        self.block_cache[height] = cached
        while len(self.block_cache) > MAX_CACHE_BLOCKS:
            self.block_cache.popitem(last=False)
        return cached


def main():
    parser = argparse.ArgumentParser(description="Defcoin Core Nu UDP Fast Sync responder")
    parser.add_argument("--conf", default="/home/dfcpool/.defcoin/defcoin.conf")
    parser.add_argument("--bind", default="0.0.0.0")
    parser.add_argument("--port", type=int, default=UDP_PORT)
    parser.add_argument("--log", default="")
    parser.add_argument(
        "--allow-unconnected",
        action="store_true",
        help="serve valid UDP requests without requiring a connected TCP peer advertising NODE_DEFCOIN_FASTSYNC; not recommended for public servers",
    )
    parser.add_argument(
        "--no-loopback-test",
        action="store_true",
        help="also require loopback requesters to appear in the Nu TCP peer allowlist",
    )
    parser.add_argument(
        "--node-id-file",
        default=DEFAULT_NODE_ID_FILE,
        help="path used to persist this responder's stable Nu node_unique_id",
    )
    args = parser.parse_args()

    handlers = []
    if args.log:
        os.makedirs(os.path.dirname(args.log), exist_ok=True)
        handlers.append(logging.FileHandler(args.log))
    handlers.append(logging.StreamHandler(sys.stdout))
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        handlers=handlers,
    )
    rpc = RpcClient(args.conf)
    require_nu_peer = not args.allow_unconnected
    allow_loopback = not args.no_loopback_test
    node_unique_id = load_or_create_node_unique_id(args.node_id_file)
    logging.info(
        "defcoin-fast-syncd starting rpc=127.0.0.1 port=%s udp=%s require_nu_peer=%s allow_loopback=%s node_unique_id=%s",
        rpc.port,
        args.port,
        require_nu_peer,
        allow_loopback,
        node_unique_id[:12],
    )
    daemon = FastSyncDaemon(
        rpc, args.bind, args.port, require_nu_peer, allow_loopback, node_unique_id
    )
    daemon.run()


if __name__ == "__main__":
    main()
