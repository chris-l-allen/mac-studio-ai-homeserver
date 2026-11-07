#!/usr/bin/env python3
"""
Home Network Portal
===================

A self-hosted page for the home network. Documents what is on the network,
what it can do, and acts as the control plane for:

  * a private Certificate Authority (CA bundles + leaf certs)
  * local DNS records (A / AAAA / CNAME / TXT), served by a built-in DNS server
  * static reservations (name -> MAC -> IP), published to DNS automatically

Auth: the FIRST login sets the account password. Everything after that is a
normal username/password login.

Stack: Python 3 stdlib + the system `openssl` CLI. No third-party packages.

Run:  ./run.sh
      sudo ./run.sh          (to bind DNS on port 53 instead of 5353)
"""

import base64
import hashlib
import hmac
import ipaddress
import json
import os
import re
import secrets
import socket
import ssl
import struct
import subprocess
import sys
import threading
import time
import uuid
import zipfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

# --------------------------------------------------------------------------
# Configuration
# --------------------------------------------------------------------------

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, "data")
CA_DIR = os.path.join(DATA_DIR, "ca")
CERTS_DIR = os.path.join(DATA_DIR, "certs")
STATE_FILE = os.path.join(DATA_DIR, "state.json")
INDEX_FILE = os.path.join(DATA_DIR, "cert_index.json")
RECORDS_FILE = os.path.join(DATA_DIR, "dns.json")
RESERVATIONS_FILE = os.path.join(DATA_DIR, "reservations.json")
DNS_QUERY_LOG = os.path.join(DATA_DIR, "dns_queries.log")

HOST = "0.0.0.0"
PORT = int(os.environ.get("PORT", "8443"))
PORT_HTTP = int(os.environ.get("PORT_HTTP", "8081"))
DNS_PORT = int(os.environ.get("DNS_PORT", "53"))
DNS_FALLBACK_PORT = int(os.environ.get("DNS_FALLBACK_PORT", "5053"))
UPSTREAM_DNS = os.environ.get("UPSTREAM_DNS", "10.0.0.1")

DEFAULT_ZONE = "home.arpa"
DEFAULT_USERNAME = "callen"

# Prefer a modern OpenSSL; fall back to the system LibreSSL.
_OPENSSL_CANDIDATES = [
    "/opt/homebrew/bin/openssl",  # brew OpenSSL 3.x (arm64)
    "/usr/local/bin/openssl",   # brew OpenSSL 3.x
    "/usr/bin/openssl",         # macOS LibreSSL
    "/opt/local/bin/openssl",   # MacPorts (old)
    "openssl",
]
OPENSSL = next((p for p in _OPENSSL_CANDIDATES if os.path.exists(p)), "openssl")

CA_NAME = "Home Network CA"
ROOT_CN = "Home Network Root CA"
INT_CN = "Home Network Intermediate CA"

DNS_ACTUAL_PORT = DNS_PORT  # mutated at startup if 53 is unavailable

# Paths that are served over plain HTTP for device enrollment (no TLS warning
# before the CA is installed). Everything else on the HTTP port redirects to HTTPS.
PUBLIC_ENROLL_PATHS = {
    "/setup", "/ca-bundle", "/ca-root", "/ca-int",
    "/install.sh", "/ca/mobileconfig", "/setup-qr.png", "/favicon.ico",
}


def enroll_url(path="/setup"):
    return "http://%s:%d%s" % (get_lan_ip(), PORT_HTTP, path)


# --------------------------------------------------------------------------
# State / files
# --------------------------------------------------------------------------

def ensure_dirs():
    for d in (DATA_DIR, CA_DIR, CERTS_DIR):
        os.makedirs(d, exist_ok=True)


def load_json(path, default):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return default


def save_json(path, obj):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(obj, f, indent=2)
    os.replace(tmp, path)


def load_state():
    return load_json(STATE_FILE, {})


def save_state(state):
    save_json(STATE_FILE, state)


def load_dns():
    d = load_json(RECORDS_FILE, {"zone": DEFAULT_ZONE, "records": []})
    d.setdefault("zone", DEFAULT_ZONE)
    d.setdefault("records", [])
    return d


def save_dns(d):
    save_json(RECORDS_FILE, d)


def load_reservations():
    return load_json(RESERVATIONS_FILE, [])


def save_reservations(r):
    save_json(RESERVATIONS_FILE, r)


# --------------------------------------------------------------------------
# Password hashing (scrypt)
# --------------------------------------------------------------------------

def hash_password(password, salt=None):
    if salt is None:
        salt = secrets.token_bytes(16)
    dk = hashlib.scrypt(password.encode("utf-8"), salt=salt, n=2 ** 14, r=8, p=1, dklen=32)
    return salt.hex(), dk.hex()


def verify_password(password, salt_hex, hash_hex):
    salt = bytes.fromhex(salt_hex)
    dk = hashlib.scrypt(password.encode("utf-8"), salt=salt, n=2 ** 14, r=8, p=1, dklen=32)
    return hmac.compare_digest(dk.hex(), hash_hex)


# --------------------------------------------------------------------------
# openssl helpers
# --------------------------------------------------------------------------

def openssl(*args):
    p = subprocess.run([OPENSSL, *args], capture_output=True, text=True)
    return p.returncode, p.stdout, p.stderr


def openssl_ok(*args):
    code, out, err = openssl(*args)
    if code != 0:
        raise RuntimeError("openssl %s failed: %s" % (" ".join(args[:2]), err.strip() or out.strip()))
    return out


def fingerprint(cert_path):
    out = openssl_ok("x509", "-in", cert_path, "-noout", "-fingerprint", "-sha256")
    m = re.search(r"=([0-9A-F:]{59})", out)
    return m.group(1) if m else "unknown"


def cert_dates(cert_path):
    start = openssl_ok("x509", "-in", cert_path, "-noout", "-startdate").strip()
    end = openssl_ok("x509", "-in", cert_path, "-noout", "-enddate").strip()
    serial = openssl_ok("x509", "-in", cert_path, "-noout", "-serial").strip()
    return start.replace("notBefore=", ""), end.replace("notAfter=", ""), serial.replace("serial=", "")


def write_cnf(path, body):
    with open(path, "w", encoding="utf-8") as f:
        f.write(body)


def ca_cnf(cn):
    return (
        "[req]\ndistinguished_name = dn\nprompt = no\nx509_extensions = v3_ca\n"
        "[dn]\nCN = %s\nO = Home Network\nC = CA\n"
        "[v3_ca]\nbasicConstraints = critical,CA:TRUE\n"
        "keyUsage = critical,keyCertSign,cRLSign\n"
        "subjectKeyIdentifier = hash\nauthorityKeyIdentifier = keyid:always\n" % cn
    )


def intermediate_cnf(cn):
    return (
        "[req]\ndistinguished_name = dn\nprompt = no\n"
        "[dn]\nCN = %s\nO = Home Network\nC = CA\n"
        "[v3_intermediate_ca]\nbasicConstraints = critical,CA:TRUE,pathlen:0\n"
        "keyUsage = critical,keyCertSign,cRLSign\n"
        "subjectKeyIdentifier = hash\nauthorityKeyIdentifier = keyid:always\n" % cn
    )


def leaf_cnf(cn, sans):
    body = (
        "[req]\ndistinguished_name = dn\nprompt = no\nreq_extensions = v3_server\n"
        "[dn]\nCN = %s\nO = Home Network\nC = CA\n"
        "[v3_server]\nbasicConstraints = CA:FALSE\n"
        "keyUsage = critical,digitalSignature,keyEncipherment\n"
        "extendedKeyUsage = serverAuth,clientAuth\nsubjectAltName = @alt_names\n"
        "[alt_names]\n" % cn
    )
    names = [cn] + [s.strip() for s in (sans or []) if s.strip()]
    seen, idx = set(), 1
    for n in names:
        if not n or n in seen:
            continue
        seen.add(n)
        key = "IP" if re.match(r"^\d+\.\d+\.\d+\.\d+$", n) else "DNS"
        body += "%s.%d = %s\n" % (key, idx, n)
        idx += 1
    return body


# --------------------------------------------------------------------------
# CA bootstrap
# --------------------------------------------------------------------------

ROOT_KEY = os.path.join(CA_DIR, "root.key")
ROOT_CRT = os.path.join(CA_DIR, "root.crt")
INT_KEY = os.path.join(CA_DIR, "int.key")
INT_CRT = os.path.join(CA_DIR, "int.crt")
INT_CSR = os.path.join(CA_DIR, "int.csr")
BUNDLE_CRT = os.path.join(CA_DIR, "ca-bundle.crt")
SERVER_KEY = os.path.join(CA_DIR, "server.key")
SERVER_CRT = os.path.join(CA_DIR, "server.crt")
SERVER_FULLCHAIN = os.path.join(CA_DIR, "server-fullchain.crt")


def ca_ready():
    return all(os.path.exists(p) for p in (ROOT_KEY, ROOT_CRT, INT_KEY, INT_CRT))


def bootstrap_ca():
    ensure_dirs()
    if ca_ready():
        return
    tmp = os.path.join(CA_DIR, "work")
    os.makedirs(tmp, exist_ok=True)

    root_cnf = os.path.join(tmp, "root.cnf")
    write_cnf(root_cnf, ca_cnf(ROOT_CN))
    openssl_ok("req", "-new", "-x509", "-newkey", "rsa:2048", "-nodes",
               "-keyout", ROOT_KEY, "-out", ROOT_CRT, "-days", "3650",
               "-config", root_cnf, "-sha256")

    int_cnf = os.path.join(tmp, "int.cnf")
    write_cnf(int_cnf, intermediate_cnf(INT_CN))
    openssl_ok("req", "-new", "-newkey", "rsa:2048", "-nodes",
               "-keyout", INT_KEY, "-out", INT_CSR, "-config", int_cnf, "-sha256")
    openssl_ok("x509", "-req", "-in", INT_CSR, "-CA", ROOT_CRT, "-CAkey", ROOT_KEY,
               "-CAcreateserial", "-out", INT_CRT, "-days", "1825",
               "-extensions", "v3_intermediate_ca", "-extfile", int_cnf, "-sha256")

    with open(BUNDLE_CRT, "w") as f:
        f.write(open(INT_CRT).read())
        f.write(open(ROOT_CRT).read())

    os.chmod(ROOT_KEY, 0o600)
    os.chmod(INT_KEY, 0o600)


def get_lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.0.0.1", 80))
        return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"
    finally:
        s.close()


def get_lan_cidr():
    """Return the LAN subnet in CIDR form (e.g. '10.0.0.0/24').

    Used by the install script to exempt the home network from macOS 15.5+'s
    per-app Local Network privacy check, so Chrome and other third-party
    apps can reach the portal/poker without a manual prompt.
    """
    ip = get_lan_ip()
    iface = None
    try:
        for line in subprocess.check_output(["route", "-n", "get", "default"]).decode().splitlines():
            line = line.strip()
            if line.startswith("interface:"):
                iface = line.split(":", 1)[1].strip()
                break
    except Exception:
        iface = None
    mask = None
    if iface:
        try:
            out = subprocess.check_output(["ifconfig", iface]).decode()
            m = re.search(r"inet\s+[\d.]+\s+netmask\s+(0x[0-9a-fA-F]+)", out)
            if m:
                mask = int(m.group(1), 16)
        except Exception:
            mask = None
    if mask is None:
        # Home networks are almost always /24; fall back if the mask is unreadable.
        mask = 0xFFFFFF00
    prefix = 32 - (mask ^ 0xFFFFFFFF).bit_length()
    return str(ipaddress.IPv4Network((ip, prefix), strict=False))


def ensure_server_cert():
    if os.path.exists(SERVER_KEY) and os.path.exists(SERVER_CRT) and os.path.exists(SERVER_FULLCHAIN):
        return
    hostname = socket.gethostname()
    lan_ip = get_lan_ip()
    cn = hostname
    sans = [hostname + ".local", "localhost", "127.0.0.1", lan_ip]

    tmp = os.path.join(CA_DIR, "work")
    os.makedirs(tmp, exist_ok=True)
    cnf = os.path.join(tmp, "server.cnf")
    write_cnf(cnf, leaf_cnf(cn, sans))

    openssl_ok("req", "-new", "-newkey", "rsa:2048", "-nodes",
               "-keyout", SERVER_KEY, "-out", os.path.join(tmp, "server.csr"),
               "-config", cnf, "-sha256")
    openssl_ok("x509", "-req", "-in", os.path.join(tmp, "server.csr"),
               "-CA", INT_CRT, "-CAkey", INT_KEY, "-CAcreateserial",
               "-out", SERVER_CRT, "-days", "825",
               "-extensions", "v3_server", "-extfile", cnf, "-sha256")

    with open(SERVER_FULLCHAIN, "w") as f:
        f.write(open(SERVER_CRT).read())
        f.write(open(INT_CRT).read())

    os.chmod(SERVER_KEY, 0o600)


# --------------------------------------------------------------------------
# Certificate issuance
# --------------------------------------------------------------------------

def issue_certificate(cn, sans, days, key_password):
    cn = re.sub(r"[^A-Za-z0-9.\-]", "_", cn).strip("._")
    if not cn:
        cn = "device"
    days = max(1, min(int(days), 825))

    stamp = int(time.time())
    slug = re.sub(r"[^A-Za-z0-9.\-]", "_", cn)
    out_dir = os.path.join(CERTS_DIR, "%s_%d" % (slug, stamp))
    os.makedirs(out_dir, exist_ok=True)

    key_path = os.path.join(out_dir, cn + ".key")
    csr_path = os.path.join(out_dir, cn + ".csr")
    crt_path = os.path.join(out_dir, cn + ".crt")
    fullchain_path = os.path.join(out_dir, cn + "-fullchain.crt")
    cnf_path = os.path.join(out_dir, cn + ".cnf")
    p12_path = os.path.join(out_dir, cn + ".p12")

    write_cnf(cnf_path, leaf_cnf(cn, sans))
    openssl_ok("req", "-new", "-newkey", "rsa:2048", "-nodes",
               "-keyout", key_path, "-out", csr_path, "-config", cnf_path, "-sha256")
    openssl_ok("x509", "-req", "-in", csr_path, "-CA", INT_CRT, "-CAkey", INT_KEY,
               "-CAcreateserial", "-out", crt_path, "-days", str(days),
               "-extensions", "v3_server", "-extfile", cnf_path, "-sha256")

    with open(fullchain_path, "w") as f:
        f.write(open(crt_path).read())
        f.write(open(INT_CRT).read())

    if key_password:
        openssl_ok("pkcs12", "-export", "-out", p12_path,
                   "-inkey", key_path, "-in", crt_path, "-certfile", INT_CRT,
                   "-passout", "pass:" + key_password, "-name", cn)

    os.chmod(key_path, 0o600)

    vcode, vout, verr = openssl("verify", "-CAfile", BUNDLE_CRT, crt_path)
    if vcode != 0:
        raise RuntimeError("verification failed: " + (verr or vout).strip())

    start, end, serial = cert_dates(crt_path)

    idx = load_json(INDEX_FILE, [])
    idx.append({
        "cn": cn,
        "sans": [n.strip() for n in (sans or []) if n.strip()],
        "days": days,
        "serial": serial,
        "not_before": start,
        "not_after": end,
        "issued_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "dir": os.path.basename(out_dir),
    })
    save_json(INDEX_FILE, idx)

    return out_dir, cn


# --------------------------------------------------------------------------
# DNS: records, reservations, resolver, server
# --------------------------------------------------------------------------

TYPE_A, TYPE_NS, TYPE_CNAME, TYPE_SOA, TYPE_PTR, TYPE_TXT, TYPE_AAAA, TYPE_ANY = 1, 2, 5, 6, 12, 16, 28, 255
TYPE_NAMES = {"A": TYPE_A, "AAAA": TYPE_AAAA, "CNAME": TYPE_CNAME, "TXT": TYPE_TXT, "NS": TYPE_NS, "PTR": TYPE_PTR, "SOA": TYPE_SOA}


def is_valid_ip(v):
    try:
        ipaddress.ip_address(v)
        return True
    except ValueError:
        return False


def normalize_name(name, zone_abs):
    name = name.strip().lower()
    if name in ("", "@"):
        return zone_abs
    if name.endswith("."):
        return name
    if name == zone_abs.rstrip(".") or name.endswith("." + zone_abs.rstrip(".")):
        return name + "."
    return name + "." + zone_abs


def reverse_ip4(ip):
    parts = ip.split(".")
    return ".".join(reversed(parts))


def name_to_wire(name):
    name = name.rstrip(".")
    if not name:
        return b"\x00"
    out = b""
    for p in name.split("."):
        b = p.encode("ascii", "ignore")
        out += bytes([len(b)]) + b
    return out + b"\x00"


def txt_wire(s):
    b = s.encode("utf-8")
    out = b""
    for i in range(0, len(b), 255):
        chunk = b[i:i + 255]
        out += bytes([len(chunk)]) + chunk
    return out


def encode_rdata(typ, val):
    if typ == TYPE_A:
        return socket.inet_aton(val)
    if typ == TYPE_AAAA:
        return socket.inet_pton(socket.AF_INET6, val)
    if typ in (TYPE_CNAME, TYPE_NS, TYPE_PTR):
        return name_to_wire(val)
    if typ == TYPE_TXT:
        return txt_wire(val)
    return b""


def get_maps():
    dns = load_dns()
    zone_abs = dns["zone"].rstrip(".").lower() + "."
    records_map, ptr_map = {}, {}

    def add(name, typ, ttl, val):
        records_map.setdefault(name, []).append((typ, ttl, val))
        if typ == TYPE_A:
            ptr_map["%s.in-addr.arpa." % reverse_ip4(val)] = name

    for r in dns.get("records", []):
        typ = TYPE_NAMES.get(str(r.get("type", "")).upper())
        if typ is None:
            continue
        name = normalize_name(str(r.get("name", "")), zone_abs)
        val = r.get("value", "")
        ttl = int(r.get("ttl", 3600))
        if typ in (TYPE_CNAME, TYPE_NS, TYPE_PTR):
            val = normalize_name(str(val), zone_abs)
        if typ == TYPE_A and not is_valid_ip(val):
            continue
        add(name, typ, ttl, val)

    for res in load_reservations():
        name = normalize_name(str(res.get("name", "")), zone_abs)
        ip = str(res.get("ip", ""))
        if is_valid_ip(ip):
            add(name, TYPE_A, 3600, ip)

    return zone_abs, records_map, ptr_map


def soa_rdata(zone_abs):
    return (name_to_wire("ns." + zone_abs) + name_to_wire("hostmaster." + zone_abs)
            + struct.pack(">IIIII", int(time.time()), 3600, 600, 86400, 300))


def resolve(name, qtype, zone_abs, records_map, ptr_map):
    if name == zone_abs:
        if qtype == TYPE_SOA:
            return [(name, TYPE_SOA, 300, soa_rdata(zone_abs))]
        if qtype == TYPE_NS:
            return [(name, TYPE_NS, 3600, name_to_wire("ns." + zone_abs))]

    if qtype == TYPE_PTR:
        fqdn = ptr_map.get(name)
        if fqdn:
            return [(name, TYPE_PTR, 3600, name_to_wire(fqdn))]
        return None

    entries = records_map.get(name)
    if not entries:
        return None

    matched = [e for e in entries if qtype == TYPE_ANY or e[0] == qtype]
    if matched:
        return [(name, t, ttl, encode_rdata(t, v)) for t, ttl, v in matched]

    cname = [e for e in entries if e[0] == TYPE_CNAME]
    if cname:
        t, ttl, target = cname[0]
        answers = [(name, t, ttl, name_to_wire(target))]
        if target in records_map:
            for e2 in [e for e in records_map[target] if e[0] == qtype]:
                answers.append((target, e2[0], e2[1], encode_rdata(e2[0], e2[2])))
        return answers

    return []


def parse_query(data):
    if len(data) < 12:
        return None
    txid = data[:2]
    qdcount = struct.unpack(">H", data[4:6])[0]
    qs, off = [], 12
    for _ in range(qdcount):
        labels, jumped, orig = [], False, off
        while True:
            if off >= len(data):
                return None
            l = data[off]
            if l & 0xC0 == 0xC0:
                if not jumped:
                    orig = off + 2
                ptr = struct.unpack(">H", data[off:off + 2])[0] & 0x3FFF
                off = ptr
                jumped = True
                continue
            off += 1
            if l == 0:
                break
            labels.append(data[off:off + l].decode("ascii", "ignore"))
            off += l
        if off + 4 > len(data):
            return None
        qtype, qclass = struct.unpack(">HH", data[off:off + 4])
        off += 4
        name = ".".join(labels).lower() + "."
        qs.append((name, qtype, qclass))
        if not jumped:
            orig = off
    return txid, qs, orig


def forward(data, upstream):
    s = None
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.settimeout(3)
        s.sendto(data, (upstream, 53))
        resp, _ = s.recvfrom(4096)
        return resp
    except Exception:
        return None
    finally:
        if s:
            s.close()


class DNSServer:
    def __init__(self, port, upstream):
        self.port = port
        self.upstream = upstream

    def build_response(self, data):
        parsed = parse_query(data)
        if not parsed:
            return None
        txid, qs, qend = parsed
        zone_abs, records_map, ptr_map = get_maps()

        for qname, qtype, _qclass in qs:
            in_zone = (qname == zone_abs or qname.endswith("." + zone_abs)
                       or qname in records_map or qname in ptr_map)
            if not in_zone:
                return forward(data, self.upstream)

        answers, rcode = [], 0
        for qname, qtype, _qclass in qs:
            res = resolve(qname, qtype, zone_abs, records_map, ptr_map)
            if res is None:
                rcode = 3
            elif res:
                answers.extend(res)

        flags = 0x8000 | 0x0400 | rcode
        header = txid + struct.pack(">HHHHH", flags, len(qs), len(answers), 0, 0)
        out = header + data[12:qend]
        for owner, typ, ttl, rdata in answers:
            out += name_to_wire(owner) + struct.pack(">HHIH", typ, 1, ttl, len(rdata)) + rdata
        return out

    def _log_query(self, src_ip, data):
        try:
            parsed = parse_query(data)
            if parsed:
                _, qs, _ = parsed
                names = ",".join(q[0] for q in qs)
                with open(DNS_QUERY_LOG, "a") as f:
                    f.write("%s %s %s\n" % (time.strftime("%Y-%m-%d %H:%M:%S"), src_ip, names))
        except Exception:
            pass

    def _udp(self, sock):
        while True:
            try:
                data, addr = sock.recvfrom(4096)
                self._log_query(addr[0], data)
                resp = self.build_response(data)
                if resp:
                    sock.sendto(resp, addr)
            except Exception:
                continue

    def _tcp(self, sock):
        while True:
            try:
                conn, addr = sock.accept()
            except Exception:
                continue
            try:
                conn.settimeout(3)
                ln = conn.recv(2)
                if len(ln) < 2:
                    continue
                (length,) = struct.unpack(">H", ln)
                data = b""
                while len(data) < length:
                    chunk = conn.recv(length - len(data))
                    if not chunk:
                        break
                    data += chunk
                self._log_query(addr[0], data)
                resp = self.build_response(data)
                if resp:
                    conn.sendall(struct.pack(">H", len(resp)) + resp)
            except Exception:
                pass
            finally:
                conn.close()

    def start(self):
        self.udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        for s in (self.udp, self.tcp):
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.udp.bind((HOST, self.port))
        self.tcp.bind((HOST, self.port))
        self.tcp.listen(16)
        threading.Thread(target=self._udp, args=(self.udp,), daemon=True).start()
        threading.Thread(target=self._tcp, args=(self.tcp,), daemon=True).start()
        return self.port


# --------------------------------------------------------------------------
# Sessions (in-memory)
# --------------------------------------------------------------------------

SESSIONS = {}
SESSION_TTL = 12 * 3600
SESSION_COOKIE = "hnp_session"


def create_session(username):
    token = secrets.token_urlsafe(32)
    SESSIONS[token] = {"username": username, "expires": time.time() + SESSION_TTL}
    return token


def get_session(token):
    if not token:
        return None
    s = SESSIONS.get(token)
    if not s:
        return None
    if s["expires"] < time.time():
        SESSIONS.pop(token, None)
        return None
    return s


# --------------------------------------------------------------------------
# HTML rendering
# --------------------------------------------------------------------------

def esc(s):
    return (str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
            .replace('"', "&quot;"))


CSS = """
:root { --bg:#0e1116; --panel:#171c24; --panel2:#1d2430; --fg:#e6e9ef; --muted:#98a2b3;
        --accent:#4f8cff; --accent2:#2f6fe0; --ok:#34d399; --warn:#fbbf24; --err:#f87171;
        --border:#2a3342; }
* { box-sizing:border-box; }
body { margin:0; font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
       background:var(--bg); color:var(--fg); line-height:1.5; }
a { color:var(--accent); text-decoration:none; }
a:hover { text-decoration:underline; }
.wrap { max-width:1000px; margin:0 auto; padding:0 20px 60px; }
header { border-bottom:1px solid var(--border); margin-bottom:24px; }
header .bar { display:flex; align-items:center; justify-content:space-between; padding:16px 0; }
.brand { font-size:18px; font-weight:700; }
.brand .dot { color:var(--accent); }
.user { color:var(--muted); font-size:14px; }
.user form { display:inline; }
.btn { display:inline-block; background:var(--accent2); color:#fff; border:1px solid var(--accent);
       padding:8px 14px; border-radius:8px; cursor:pointer; font-size:14px; }
.btn:hover { background:var(--accent); text-decoration:none; }
.btn.ghost { background:transparent; color:var(--accent); }
.btn.danger { background:transparent; color:var(--err); border-color:var(--err); }
h1 { font-size:22px; margin:0 0 4px; }
h2 { font-size:16px; margin:28px 0 10px; border-bottom:1px solid var(--border); padding-bottom:6px; }
.sub { color:var(--muted); font-size:14px; margin:0 0 16px; }
.grid { display:grid; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); gap:16px; }
.card { background:var(--panel); border:1px solid var(--border); border-radius:12px; padding:16px; }
.card h3 { margin:0 0 8px; font-size:13px; color:var(--muted); text-transform:uppercase; letter-spacing:.04em; }
.kv { font-size:14px; }
.kv .row { display:flex; justify-content:space-between; padding:5px 0; border-bottom:1px solid var(--border); }
.kv .row:last-child { border-bottom:none; }
.kv .k { color:var(--muted); }
.kv .v { font-family:ui-monospace,SFMono-Regular,Menlo,monospace; word-break:break-all; text-align:right; }
table { width:100%; border-collapse:collapse; font-size:13.5px; }
th,td { text-align:left; padding:8px 10px; border-bottom:1px solid var(--border); }
th { color:var(--muted); font-weight:600; }
.mono { font-family:ui-monospace,SFMono-Regular,Menlo,monospace; }
.badge { display:inline-block; padding:2px 8px; border-radius:999px; font-size:12px; font-weight:600; }
.badge.ok { background:rgba(52,211,153,.15); color:var(--ok); }
.badge.warn { background:rgba(251,191,36,.15); color:var(--warn); }
form.field { background:var(--panel); border:1px solid var(--border); border-radius:12px; padding:18px; }
form.field label { display:block; margin:10px 0 4px; font-size:13px; color:var(--muted); }
form.field input, form.field select { width:100%; padding:9px 10px; border-radius:8px; border:1px solid var(--border);
                   background:var(--panel2); color:var(--fg); font-size:14px; }
form.field .hint { font-size:12px; color:var(--muted); margin-top:3px; }
form.field .actions { margin-top:16px; }
.inline-form { display:inline; }
.login { max-width:380px; margin:60px auto; }
.login .card { padding:28px; }
.login h1 { font-size:20px; }
.flash { padding:10px 14px; border-radius:8px; margin:12px 0; font-size:14px; }
.flash.err { background:rgba(248,113,113,.12); color:var(--err); border:1px solid rgba(248,113,113,.4); }
.flash.ok { background:rgba(52,211,153,.12); color:var(--ok); border:1px solid rgba(52,211,153,.4); }
.notice { padding:12px 14px; border-radius:8px; margin:0 0 16px; font-size:14px;
          background:rgba(79,140,255,.10); color:var(--fg); border:1px solid rgba(79,140,255,.35); }
pre.code { background:var(--panel2); border:1px solid var(--border); padding:12px; border-radius:8px;
           overflow-x:auto; font-family:ui-monospace,SFMono-Regular,Menlo,monospace; font-size:13px; }
.foot { color:var(--muted); font-size:12px; margin-top:30px; text-align:center; }
"""


def render_page(title, body, user=None, flash=None):
    flash_html = ""
    if flash:
        cls = "ok" if flash[0] == "ok" else "err"
        flash_html = '<div class="flash %s">%s</div>' % (cls, esc(flash[1]))

    user_html = ""
    if user:
        user_html = ('<div class="user">signed in as <b>%s</b> '
                     '<form method="post" action="/logout"><button class="btn ghost" type="submit">sign out</button></form></div>'
                     % esc(user))

    return """<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>%s</title><style>%s</style></head><body>
<header><div class="wrap"><div class="bar">
<div class="brand">Home Network<span class="dot">.</span></div>%s</div></div></header>
<div class="wrap">%s%s</div>
<div class="foot">Home Network Portal &mdash; self-hosted &mdash; %s</div>
</body></html>""" % (esc(title), CSS, user_html, flash_html, body, esc(socket.gethostname()))


def login_page(flash=None):
    state = load_state()
    is_setup = "user" not in state
    title = "Set up your login" if is_setup else "Sign in"
    heading = "Set your password" if is_setup else "Welcome back"

    if is_setup:
        notice = ('<div class="notice">No password has been set yet. '
                  'You will sign in as <b>%s</b>. Enter the password you want to use '
                  '&mdash; it becomes your login password from now on.</div>' % esc(DEFAULT_USERNAME))
        username_field = ('<input type="text" id="username" name="username" value="%s" readonly>'
                          '<div class="hint">Username is fixed to <span class="mono">%s</span>.</div>'
                          % (esc(DEFAULT_USERNAME), esc(DEFAULT_USERNAME)))
        confirm = ('<label for="confirm">Confirm password</label>'
                   '<input type="password" id="confirm" name="confirm" autocomplete="new-password" required>')
        submit = "Set password"
        pwd_autocomplete = "new-password"
    else:
        notice = ""
        username_field = '<input type="text" id="username" name="username" autocomplete="username" required>'
        confirm = ""
        submit = "Sign in"
        pwd_autocomplete = "current-password"

    body = """
<div class="login"><div class="card">
<h1>%s</h1>
%s
<form class="field" method="post" action="/auth">
<label for="username">Username</label>
%s
<label for="password">Password</label>
<input type="password" id="password" name="password" autocomplete="%s" required>
%s
<div class="actions"><button class="btn" type="submit">%s</button></div>
</form>
</div></div>""" % (heading, notice, username_field, pwd_autocomplete, confirm, submit)

    return render_page(title, body, flash=flash)


def ca_status():
    root_fp = fingerprint(ROOT_CRT)
    int_fp = fingerprint(INT_CRT)
    _r_start, r_end, r_serial = cert_dates(ROOT_CRT)
    _i_start, i_end, i_serial = cert_dates(INT_CRT)
    idx = load_json(INDEX_FILE, [])
    return {
        "root_fp": root_fp, "int_fp": int_fp,
        "root_valid": r_end, "int_valid": i_end,
        "issued_count": len(idx),
    }


def pem_der_b64(path):
    lines = open(path).read().splitlines()
    body = "".join(l for l in lines if "-----" not in l)
    return base64.b64encode(base64.b64decode(body)).decode()


def generate_qr(text, out_path):
    script = os.path.join(BASE_DIR, "qrcode.swift")
    if not os.path.exists(script):
        return False
    p = subprocess.run(["swift", script, text, out_path], capture_output=True, text=True)
    return p.returncode == 0 and os.path.exists(out_path)


def ensure_setup_qr():
    path = os.path.join(DATA_DIR, "setup-qr.png")
    if not os.path.exists(path):
        try:
            generate_qr(enroll_url("/setup"), path)
        except Exception:
            pass
    return path


def build_mobileconfig(zone, dns_ip):
    root_b64 = pem_der_b64(ROOT_CRT)
    int_b64 = pem_der_b64(INT_CRT)
    u = [str(uuid.uuid4()).upper() for _ in range(4)]
    zone_clean = zone.rstrip(".")
    return '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>PayloadContent</key><array>
<dict>
<key>PayloadContent</key><data>%s</data>
<key>PayloadCertificateFileName</key><string>home-network-root.crt</string>
<key>PayloadDisplayName</key><string>Home Network Root CA</string>
<key>PayloadIdentifier</key><string>local.home-network.root</string>
<key>PayloadType</key><string>com.apple.security.root</string>
<key>PayloadUUID</key><string>%s</string>
<key>PayloadVersion</key><integer>1</integer>
</dict>
<dict>
<key>PayloadContent</key><data>%s</data>
<key>PayloadCertificateFileName</key><string>home-network-intermediate.crt</string>
<key>PayloadDisplayName</key><string>Home Network Intermediate CA</string>
<key>PayloadIdentifier</key><string>local.home-network.intermediate</string>
<key>PayloadType</key><string>com.apple.security.pem</string>
<key>PayloadUUID</key><string>%s</string>
<key>PayloadVersion</key><integer>1</integer>
</dict>
<dict>
<key>DNSSettings</key><dict>
<key>ServerAddresses</key><array><string>%s</string></array>
<key>SupplementalMatchDomains</key><array><string>%s</string></array>
</dict>
<key>PayloadDisplayName</key><string>Local DNS</string>
<key>PayloadIdentifier</key><string>local.home-network.dns</string>
<key>PayloadType</key><string>com.apple.dnsSettings.managed</string>
<key>PayloadUUID</key><string>%s</string>
<key>PayloadVersion</key><integer>1</integer>
</dict>
</array>
<key>PayloadDisplayName</key><string>Home Network (CA + DNS)</string>
<key>PayloadIdentifier</key><string>local.home-network</string>
<key>PayloadRemovalDisallowed</key><false/>
<key>PayloadType</key><string>Configuration</string>
<key>PayloadUUID</key><string>%s</string>
<key>PayloadVersion</key><integer>1</integer>
</dict></plist>
''' % (root_b64, u[0], int_b64, u[1], dns_ip, zone_clean, u[2], u[3])


def build_install_script(host, dns_ip, zone, lan_cidr):
    return '''#!/bin/bash
# Adopt this device: install the Home Network CA, route *.ZONE to the local DNS,
# disable Chrome's Secure DNS so local names resolve in Chrome, and exempt this
# LAN from macOS's per-app Local Network privacy check (otherwise Chrome fails
# with ERR_ADDRESS_UNREACHABLE while Safari works).
set -e
HOST="${HNP_HOST:-%s}"
DNS_IP="${HNP_DNS:-%s}"
ZONE="${HNP_ZONE:-%s}"
LAN_CIDR="${HNP_CIDR:-%s}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "Downloading CA certificates from http://$HOST ..."
curl -s "http://$HOST/ca-root" -o "$TMP/root.crt"
curl -s "http://$HOST/ca-int"  -o "$TMP/int.crt"

disable_chrome_secure_dns() {
  local state=""
  for p in "$HOME/Library/Application Support/Google/Chrome/Local State" \
           "$HOME/.config/google-chrome/Local State" \
           "$HOME/.config/chromium/Local State"; do
    [ -f "$p" ] && state="$p" && break
  done
  if [ -z "$state" ]; then
    echo "Chrome profile not found; skipping the Secure DNS step."
    return 0
  fi
  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found; set Chrome manually: chrome://settings/security -> Secure DNS -> off."
    return 0
  fi
  # Quit Chrome so it does not overwrite the edit when it exits.
  if [[ "$(uname -s)" == "Darwin" ]]; then
    osascript -e 'quit app "Google Chrome"' 2>/dev/null || true
  else
    pkill -x google-chrome 2>/dev/null || pkill -x chrome 2>/dev/null || true
  fi
  sleep 2
  python3 - "$state" <<'PY'
import json, sys
p = sys.argv[1]
try:
    d = json.load(open(p))
except Exception:
    sys.exit(0)
doh = d.get("dns_over_https", {})
if isinstance(doh, dict):
    doh["mode"] = "off"
    d["dns_over_https"] = doh
    json.dump(d, open(p, "w"))
    print("Chrome Secure DNS disabled.")
else:
    print("Chrome Secure DNS setting not found; skipped.")
PY
  echo "Reopen Chrome - .$ZONE names will now resolve there too."
}

# macOS 15.5+: exempt the LAN from the per-app Local Network privacy check.
# Chrome (unlike Safari/WKWebView) is a third-party app, so without this it
# needs the user to manually grant "Local Network" access in System Settings.
allow_local_network() {
  local cidr="$1"
  local key
  for key in AllowedWiFiLocalNetworkAddresses AllowedEthernetLocalNetworkAddresses; do
    if ! sudo defaults read com.apple.network.local-network "$key" 2>/dev/null | grep -qF "$cidr"; then
      if sudo defaults read com.apple.network.local-network "$key" >/dev/null 2>&1; then
        sudo defaults write com.apple.network.local-network "$key" -array-add "$cidr"
      else
        sudo defaults write com.apple.network.local-network "$key" -array "$cidr"
      fi
    fi
  done
}

if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "Installing CA into the macOS system keychain..."
  sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$TMP/root.crt"
  sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$TMP/int.crt"
  echo "Configuring split DNS for .$ZONE -> $DNS_IP ..."
  sudo mkdir -p /etc/resolver
  echo "nameserver $DNS_IP" | sudo tee "/etc/resolver/$ZONE" >/dev/null
  disable_chrome_secure_dns
  OSVER="$(sw_vers -productVersion 2>/dev/null || echo 0)"
  OSMAJOR="$(echo "$OSVER" | cut -d. -f1)"; OSMAJOR="${OSMAJOR:-0}"
  OSMINOR="$(echo "$OSVER" | cut -d. -f2)"; OSMINOR="${OSMINOR:-0}"
  if [ "$OSMAJOR" -gt 15 ] || { [ "$OSMAJOR" -eq 15 ] && [ "$OSMINOR" -ge 5 ]; }; then
    allow_local_network "$LAN_CIDR"
    echo "NOTE: reboot to apply the Local Network exemption (lets Chrome & other apps reach .$ZONE without a prompt)."
  fi
  echo "Done."
else
  echo "Installing into the Linux system trust store..."
  sudo mkdir -p /usr/local/share/ca-certificates
  sudo cp "$TMP/root.crt" /usr/local/share/ca-certificates/home-network-root.crt
  sudo cp "$TMP/int.crt"  /usr/local/share/ca-certificates/home-network-intermediate.crt
  sudo update-ca-certificates
  disable_chrome_secure_dns
  echo "Done. To resolve .$ZONE names, point your DNS at $DNS_IP (e.g. systemd-resolved)."
fi
''' % (host, dns_ip, zone, lan_cidr)


def setup_page():
    dns = load_dns()
    zone = dns["zone"]
    ip = get_lan_ip()
    host = "%s:%d" % (ip, PORT_HTTP)
    install_cmd = "curl -s http://%s/install.sh | sudo bash" % host
    body = """
<h1>Set up this device</h1>
<p class="sub">Install the Home Network CA and use the local <span class="mono">.%s</span> domain.</p>

<h2>iPhone / iPad / Mac</h2>
<p><a class="btn" href="/ca/mobileconfig">Download profile (.mobileconfig)</a></p>
<p class="sub">Open the file and install it in Settings. Then enable full trust under Settings &rarr; General &rarr; About &rarr; Certificate Trust Settings. The profile also routes <span class="mono">.%s</span> lookups to the local DNS server automatically.</p>

<h2>Android</h2>
<p><a class="btn" href="/ca-bundle" download>Download CA bundle (.crt)</a></p>
<p class="sub">Install via Settings &rarr; Security &rarr; Encryption &amp; credentials &rarr; Install a certificate &rarr; CA certificate. Then set the Wi-Fi DNS to <span class="mono">%s</span>.</p>

<h2>macOS / Linux terminal</h2>
<pre class="code">%s</pre>
<p class="sub">Downloads the CA and installs it into the system trust store.</p>

<h2>DNS</h2>
<p class="sub">For <span class="mono">.%s</span> names to resolve, this device must use <span class="mono">%s</span> as its DNS server. The Apple profile above does this automatically; on other devices set it in the Wi-Fi network settings.</p>
""" % (esc(zone), esc(zone), esc(ip), esc(install_cmd), esc(zone), esc(ip))
    return render_page("Device setup", body)


def android_enroll_page():
    ip = get_lan_ip()
    body = """
<h1>Android setup</h1>
<div class="notice">Three steps.</div>
<p><a class="btn" href="/ca-root" download>1. Download the root CA (.crt)</a></p>
<p class="sub">2. Install it (in Settings &mdash; you don't open the file):</p>
<p class="sub mono">Settings &rarr; Security &amp; privacy &rarr; More security settings &rarr; Encryption &amp; credentials &rarr; Install a certificate &rarr; CA certificate &rarr; Install anyway &rarr; select the downloaded file.</p>
<p class="sub">A screen lock PIN/password may be required before this option appears. The exact path varies a little by manufacturer (Samsung: Settings &rarr; Security &rarr; Install certificate).</p>
<p class="sub">3. Set Wi-Fi DNS to <span class="mono">%s</span>: Wi-Fi &rarr; tap the network &rarr; Modify &rarr; Advanced &rarr; IP settings &rarr; Static &rarr; DNS 1 = <span class="mono">%s</span>.</p>
<p class="sub">Android blocks apps from setting DNS, so step 3 is manual &mdash; it's required for <span class="mono">*.allen</span> names to resolve.</p>
""" % (esc(ip), esc(ip))
    return render_page("Android setup", body)


def live_devices():
    try:
        out = subprocess.run(["arp", "-a"], capture_output=True, text=True).stdout
    except Exception:
        return []
    devices = []
    for line in out.splitlines():
        m = re.search(r"\((\d+\.\d+\.\d+\.\d+)\)\s+at\s+([0-9a-f:]{17})", line, re.I)
        if m:
            devices.append({"ip": m.group(1), "mac": m.group(2)})
    return devices


def dashboard(user):
    ca = ca_status()
    devices = live_devices()
    idx = load_json(INDEX_FILE, [])
    dns = load_dns()
    reservations = load_reservations()
    zone = dns["zone"]

    dev_rows = ""
    if devices:
        for d in devices:
            label = "gateway" if d["ip"] == "10.0.0.1" else ""
            dev_rows += ("<tr><td class='mono'>%s</td><td class='mono'>%s</td><td>%s</td></tr>"
                         % (esc(d["ip"]), esc(d["mac"]), esc(label)))
    else:
        dev_rows = "<tr><td colspan='3'>No ARP entries right now.</td></tr>"

    dns_rows = ""
    if dns["records"]:
        for r in dns["records"]:
            dns_rows += ("<tr><td class='mono'>%s</td><td class='mono'>%s</td><td class='mono'>%s</td>"
                         "<td class='mono'>%s</td><td><form class='inline-form' method='post' action='/dns/delete'>"
                         "<input type='hidden' name='name' value='%s'><input type='hidden' name='type' value='%s'>"
                         "<input type='hidden' name='value' value='%s'>"
                         "<button class='btn danger' type='submit'>delete</button></form></td></tr>"
                         % (esc(r["name"]), esc(r["type"]), esc(r["value"]), esc(r.get("ttl", 3600)),
                            esc(r["name"]), esc(r["type"]), esc(r["value"])))
    else:
        dns_rows = "<tr><td colspan='5'>No records yet. Add one below.</td></tr>"

    res_rows = ""
    if reservations:
        for r in reservations:
            res_rows += ("<tr><td class='mono'>%s</td><td class='mono'>%s</td><td class='mono'>%s</td>"
                         "<td><form class='inline-form' method='post' action='/reservation/delete'>"
                         "<input type='hidden' name='name' value='%s'>"
                         "<button class='btn danger' type='submit'>delete</button></form></td></tr>"
                         % (esc(r.get("name", "")), esc(r.get("mac", "")), esc(r.get("ip", "")), esc(r.get("name", ""))))
    else:
        res_rows = "<tr><td colspan='4'>No reservations yet. Add one below.</td></tr>"

    cert_rows = ""
    for c in reversed(idx):
        cert_rows += ("<tr><td class='mono'>%s</td><td>%s</td><td class='mono'>%s</td><td>%s</td></tr>"
                      % (esc(c["cn"]), esc(c.get("issued_at", "")), esc(c.get("serial", "")), esc(c.get("not_after", ""))))

    body = """
<h1>Our network</h1>
<p class="sub">What is on the network and what it can do &mdash; documented, live, and managed from one place.</p>

<h2>Overview</h2>
<div class="grid">
<div class="card"><h3>Connectivity</h3><div class="kv">
<div class="row"><span class="k">ISP</span><span class="v">Rogers (AS812), Toronto</span></div>
<div class="row"><span class="k">Gateway</span><span class="v">Rogers Xfinity &mdash; Technicolor CGM4981</span></div>
<div class="row"><span class="k">WAN IPv4</span><span class="v">99.239.157.211</span></div>
<div class="row"><span class="k">WAN IPv6</span><span class="v">2607:fea8:869e:d900::/56</span></div>
<div class="row"><span class="k">WAN mode</span><span class="v">DOCSIS</span></div>
</div></div>
<div class="card"><h3>LAN</h3><div class="kv">
<div class="row"><span class="k">Subnet</span><span class="v">10.0.0.0/24</span></div>
<div class="row"><span class="k">Gateway</span><span class="v">10.0.0.1</span></div>
<div class="row"><span class="k">DHCP pool</span><span class="v">10.0.0.2 &ndash; 10.0.0.253</span></div>
<div class="row"><span class="k">DHCP lease</span><span class="v">2 days</span></div>
<div class="row"><span class="k">Wi-Fi</span><span class="v">Rogers889 (WPA3)</span></div>
</div></div>
</div>

<h2>What is on it</h2>
<table><thead><tr><th>IP</th><th>MAC</th><th>Role</th></tr></thead>
<tbody>%s</tbody></table>
<p class="sub" style="margin-top:8px">Live view from the current ARP table. Static devices get fixed addresses from the reserved range (<span class="mono">10.0.0.2&ndash;99</span>).</p>

<h2>DNS records</h2>
<p class="sub">Zone <span class="mono">%s</span> &mdash; served by this portal's built-in DNS on <span class="mono">%s:%d</span>. Point devices at this machine's IP for DNS.</p>
<form class="field" method="post" action="/dns/add">
<label for="dn">Name</label>
<input type="text" id="dn" name="name" placeholder="plex" required>
<div class="hint">Relative to the zone (e.g. <span class="mono">plex</span> &rarr; <span class="mono">plex.%s</span>), or an absolute name ending in a dot.</div>
<label for="dt">Type</label>
<select id="dt" name="type"><option>A</option><option>AAAA</option><option>CNAME</option><option>TXT</option></select>
<label for="dv">Value</label>
<input type="text" id="dv" name="value" placeholder="10.0.0.30">
<label for="dttl">TTL (seconds)</label>
<input type="number" id="dttl" name="ttl" value="3600" min="1">
<div class="actions"><button class="btn" type="submit">Add record</button></div>
</form>
<table><thead><tr><th>Name</th><th>Type</th><th>Value</th><th>TTL</th><th></th></tr></thead>
<tbody>%s</tbody></table>

<h2>Static reservations</h2>
<p class="sub">The Rogers gateway can't do DHCP reservations, so each entry maps a name + MAC to a fixed IP and is published to DNS automatically. Apply the IP as a static address on the device itself.</p>
<form class="field" method="post" action="/reservation/add">
<label for="rn">Name</label>
<input type="text" id="rn" name="name" placeholder="nas" required>
<label for="rm">MAC address</label>
<input type="text" id="rm" name="mac" placeholder="aa:bb:cc:dd:ee:ff">
<label for="rip">IP address</label>
<input type="text" id="rip" name="ip" placeholder="10.0.0.30" required>
<div class="actions"><button class="btn" type="submit">Add reservation</button></div>
</form>
<table><thead><tr><th>Name</th><th>MAC</th><th>IP</th><th></th></tr></thead>
<tbody>%s</tbody></table>

<h2>What it can do</h2>
<table><thead><tr><th>Capability</th><th>Where</th><th>Status</th></tr></thead><tbody>
<tr><td>DNS records (A / AAAA / CNAME / TXT)</td><td>this portal</td><td><span class="badge ok">live</span></td></tr>
<tr><td>Static reservations (name &rarr; MAC &rarr; IP)</td><td>this portal</td><td><span class="badge ok">live</span></td></tr>
<tr><td>Private certificate authority</td><td>this portal</td><td><span class="badge ok">live</span></td></tr>
<tr><td>Issue CA bundles &amp; leaf certs</td><td>this portal</td><td><span class="badge ok">live</span></td></tr>
<tr><td>Reverse proxy (HTTPS for services)</td><td>own box</td><td><span class="badge warn">planned</span></td></tr>
<tr><td>Port forwarding / DMZ / firewall</td><td>gateway UI</td><td><span class="badge ok">available</span></td></tr>
</tbody></table>

<h2>Private CA</h2>
<div class="grid">
<div class="card"><h3>Root CA</h3><div class="kv">
<div class="row"><span class="k">Subject</span><span class="v">Home Network Root CA</span></div>
<div class="row"><span class="k">SHA-256</span><span class="v mono">%s</span></div>
<div class="row"><span class="k">Valid until</span><span class="v">%s</span></div>
</div></div>
<div class="card"><h3>Intermediate CA</h3><div class="kv">
<div class="row"><span class="k">Subject</span><span class="v">Home Network Intermediate CA</span></div>
<div class="row"><span class="k">SHA-256</span><span class="v mono">%s</span></div>
<div class="row"><span class="k">Valid until</span><span class="v">%s</span></div>
</div></div>
</div>
<div class="card" style="margin-top:16px">
<h3>Install the CA</h3>
<p class="sub">Install the root + intermediate as trusted, then every cert this portal issues verifies cleanly &mdash; no browser warnings.</p>
<div style="display:flex; gap:24px; align-items:center; flex-wrap:wrap;">
<div style="text-align:center">
<img src="/setup-qr.png" alt="device setup QR" width="140" height="140" style="background:#fff;border-radius:8px;padding:6px">
<div class="hint">Scan to set up a phone or tablet.</div>
</div>
<div>
<p><a class="btn" href="/setup">Open device setup page</a></p>
<p><a class="btn ghost" href="/ca/mobileconfig" download>iPhone / iPad / Mac profile (.mobileconfig)</a></p>
<p><a class="btn ghost" href="/ca-bundle" download>CA bundle (.crt)</a></p>
<p><a class="btn ghost" href="/ca-root" download>Root only (.crt)</a></p>
<p class="sub" style="margin-top:10px">Terminal: <span class="mono">curl -s http://%s/install.sh | sudo bash</span></p>
<span class="badge ok">%d cert(s) issued</span>
</div>
</div>
</div>

<h2>Issue a certificate</h2>
<form class="field" method="post" action="/issue">
<label for="cn">Common Name (hostname)</label>
<input type="text" id="cn" name="cn" placeholder="plex.home.arpa" required>
<div class="hint">The primary name for the certificate.</div>
<label for="sans">Subject Alternative Names (comma-separated)</label>
<input type="text" id="sans" name="sans" placeholder="plex.home.arpa, 10.0.0.30">
<div class="hint">Optional. IP addresses are detected automatically.</div>
<label for="days">Validity (days)</label>
<input type="number" id="days" name="days" value="398" min="1" max="825">
<label for="keypass">PKCS#12 password (optional)</label>
<input type="password" id="keypass" name="keypass" autocomplete="off" placeholder="leave blank to skip .p12">
<div class="hint">If set, a .p12 keystore is included in the download.</div>
<div class="actions"><button class="btn" type="submit">Issue certificate</button></div>
</form>

<h2>Issued certificates</h2>
<table><thead><tr><th>Name</th><th>Issued</th><th>Serial</th><th>Expires</th></tr></thead>
<tbody>%s</tbody></table>
""" % (dev_rows, esc(zone), esc(get_lan_ip()), DNS_ACTUAL_PORT, esc(zone), dns_rows, res_rows,
       ca["root_fp"], esc(ca["root_valid"]), ca["int_fp"], esc(ca["int_valid"]),
       "%s:%d" % (get_lan_ip(), PORT_HTTP), ca["issued_count"], cert_rows)

    return render_page("Dashboard", body, user=user)


# --------------------------------------------------------------------------
# Request handler
# --------------------------------------------------------------------------

class Handler(BaseHTTPRequestHandler):
    server_version = "HomeNetworkPortal/1.0"

    def log_message(self, fmt, *args):
        sys.stderr.write("%s - - [%s] %s\n" % (self.client_address[0],
                                               time.strftime("%Y-%m-%d %H:%M:%S"), fmt % args))

    def get_cookie(self, name):
        raw = self.headers.get("Cookie", "")
        for part in raw.split(";"):
            if "=" in part:
                k, v = part.strip().split("=", 1)
                if k == name:
                    return v
        return None

    def set_cookie(self, name, value):
        self.send_header("Set-Cookie", "%s=%s; HttpOnly; Secure; Path=/; Max-Age=%d; SameSite=Lax"
                         % (name, value, SESSION_TTL))

    def clear_cookie(self, name):
        self.send_header("Set-Cookie", "%s=; HttpOnly; Secure; Path=/; Max-Age=0; SameSite=Lax" % name)

    def current_user(self):
        return get_session(self.get_cookie(SESSION_COOKIE))

    def send_redirect(self, location):
        self.send_response(302)
        self.send_header("Location", location)
        self.end_headers()

    def send_text(self, code, body, ctype="text/html; charset=utf-8"):
        data = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def send_file(self, path, download_name, ctype):
        with open(path, "rb") as f:
            data = f.read()
        self.send_data(200, data, ctype, download_name)

    def send_data(self, code, data, ctype, download=None):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        if download:
            self.send_header("Content-Disposition", 'attachment; filename="%s"' % download)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def send_json(self, code, obj):
        data = json.dumps(obj).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def api_user(self):
        u = self.current_user()
        if u:
            return u
        auth = self.headers.get("Authorization", "")
        if auth.startswith("Bearer "):
            return get_session(auth[7:].strip())
        return None

    def api_get(self, path):
        if path == "/api/status":
            return self.send_json(200, {
                "host": socket.gethostname(),
                "lan_ip": get_lan_ip(),
                "web_port": PORT,
                "dns_port": DNS_ACTUAL_PORT,
                "dns_upstream": UPSTREAM_DNS,
                "ca": ca_status(),
                "dns_records": len(load_dns()["records"]),
                "reservations": len(load_reservations()),
                "certs": len(load_json(INDEX_FILE, [])),
            })

        user = self.api_user()
        if not user:
            return self.send_json(401, {"error": "unauthorized"})

        if path == "/api/dns":
            d = load_dns()
            return self.send_json(200, {"zone": d["zone"], "records": d["records"]})
        if path == "/api/reservations":
            return self.send_json(200, load_reservations())
        if path == "/api/ca":
            return self.send_json(200, ca_status())
        if path == "/api/ca/bundle":
            return self.send_text(200, open(BUNDLE_CRT).read(), "application/x-pem-file")
        if path == "/api/certs":
            return self.send_json(200, load_json(INDEX_FILE, []))
        return self.send_json(404, {"error": "not found"})

    def api_post(self, path, body):
        try:
            data = json.loads(body) if body.strip() else {}
        except Exception:
            return self.send_json(400, {"error": "invalid json"})
        if data is None:
            data = {}

        if path == "/api/setup":
            state = load_state()
            if "user" in state:
                return self.send_json(409, {"error": "account already exists"})
            username = (data.get("username") or "").strip() or DEFAULT_USERNAME
            password = data.get("password") or ""
            if len(password) < 8:
                return self.send_json(400, {"error": "password must be at least 8 characters"})
            salt, dk = hash_password(password)
            state["user"] = {"username": username, "salt": salt, "hash": dk}
            save_state(state)
            return self.send_json(201, {"token": create_session(username), "username": username})

        if path == "/api/login":
            state = load_state()
            u = state.get("user")
            if not u:
                return self.send_json(400, {"error": "no account; run /api/setup first"})
            username = (data.get("username") or "").strip() or DEFAULT_USERNAME
            password = data.get("password") or ""
            if username != u["username"] or not verify_password(password, u["salt"], u["hash"]):
                return self.send_json(401, {"error": "invalid credentials"})
            return self.send_json(200, {"token": create_session(username), "username": username})

        user = self.api_user()
        if not user:
            return self.send_json(401, {"error": "unauthorized"})

        if path == "/api/dns":
            name = (data.get("name") or "").strip()
            typ = (data.get("type") or "").strip().upper()
            value = (data.get("value") or "").strip()
            ttl = data.get("ttl", 3600)
            if not name or not value or typ not in TYPE_NAMES:
                return self.send_json(400, {"error": "name, type (A/AAAA/CNAME/TXT) and value are required"})
            try:
                ttl = int(ttl)
            except (TypeError, ValueError):
                ttl = 3600
            d = load_dns()
            rec = {"name": name, "type": typ, "value": value, "ttl": ttl}
            d["records"].append(rec)
            save_dns(d)
            return self.send_json(201, rec)

        if path == "/api/reservations":
            name = (data.get("name") or "").strip()
            mac = (data.get("mac") or "").strip()
            ip = (data.get("ip") or "").strip()
            if not name or not is_valid_ip(ip):
                return self.send_json(400, {"error": "name and a valid ip are required"})
            res = load_reservations()
            res = [r for r in res if r["name"] != name]
            rec = {"name": name, "mac": mac, "ip": ip}
            res.append(rec)
            save_reservations(res)
            return self.send_json(201, rec)

        if path == "/api/certs/issue":
            cn = (data.get("cn") or "").strip()
            sans = data.get("sans", [])
            if isinstance(sans, str):
                sans = [s for s in sans.split(",") if s.strip()]
            days = data.get("days", 398)
            keypass = data.get("keypass") or ""
            if not cn:
                return self.send_json(400, {"error": "cn is required"})
            try:
                days = int(days)
            except (TypeError, ValueError):
                days = 398
            try:
                out_dir, cn = issue_certificate(cn, sans, days, keypass)
            except Exception as e:
                return self.send_json(500, {"error": str(e)})
            zip_path = os.path.join(out_dir, cn + ".zip")
            with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
                z.write(os.path.join(out_dir, cn + ".key"), cn + ".key")
                z.write(os.path.join(out_dir, cn + ".crt"), cn + ".crt")
                z.write(os.path.join(out_dir, cn + "-fullchain.crt"), cn + "-fullchain.crt")
                z.write(BUNDLE_CRT, "ca-bundle.crt")
                if keypass:
                    z.write(os.path.join(out_dir, cn + ".p12"), cn + ".p12")
            self.send_file(zip_path, cn + "-certs.zip", "application/zip")
            return

        return self.send_json(404, {"error": "not found"})

    def do_DELETE(self):
        path = urlparse(self.path).path
        user = self.api_user()
        if not user:
            return self.send_json(401, {"error": "unauthorized"})
        length = int(self.headers.get("Content-Length", 0) or 0)
        raw = self.rfile.read(length) if length else b""
        try:
            data = json.loads(raw) if raw else {}
        except Exception:
            data = {}
        if path == "/api/dns":
            d = load_dns()
            name, typ, value = data.get("name"), data.get("type"), data.get("value")
            before = len(d["records"])
            d["records"] = [r for r in d["records"]
                            if not (r["name"] == name and r["type"] == typ and r["value"] == value)]
            save_dns(d)
            return self.send_json(200, {"deleted": before - len(d["records"])})
        if path == "/api/reservations":
            res = load_reservations()
            name = data.get("name")
            before = len(res)
            res = [r for r in res if r["name"] != name]
            save_reservations(res)
            return self.send_json(200, {"deleted": before - len(res)})
        return self.send_json(404, {"error": "not found"})

    def do_GET(self):
        path = urlparse(self.path).path
        if getattr(self.server, "plain", False) and path not in PUBLIC_ENROLL_PATHS:
            return self.send_redirect("https://%s:%d%s" % (get_lan_ip(), PORT, self.path))
        if path.startswith("/api/"):
            return self.api_get(path)

        # Public CA / device-adoption endpoints (the CA public cert is not secret).
        if path == "/ca-bundle":
            return self.send_file(BUNDLE_CRT, "home-network-ca-bundle.crt", "application/x-pem-file")
        if path == "/ca-root":
            return self.send_file(ROOT_CRT, "home-network-root-ca.crt", "application/x-pem-file")
        if path == "/ca-int":
            return self.send_file(INT_CRT, "home-network-intermediate-ca.crt", "application/x-pem-file")
        if path == "/install.sh":
            dns = load_dns()
            script = build_install_script("%s:%d" % (get_lan_ip(), PORT_HTTP), get_lan_ip(), dns["zone"], get_lan_cidr()).encode("utf-8")
            self.send_data(200, script, "text/x-shellscript", "adopt-device.sh")
            return
        if path == "/ca/mobileconfig":
            dns = load_dns()
            cfg = build_mobileconfig(dns["zone"], get_lan_ip()).encode("utf-8")
            self.send_data(200, cfg, "application/x-apple-aspen-config", "home-network-ca.mobileconfig")
            return
        if path == "/setup":
            ua = self.headers.get("User-Agent", "")
            if re.search(r"iPhone|iPad|iPod", ua):
                return self.send_redirect("/ca/mobileconfig")
            if "Android" in ua:
                return self.send_text(200, android_enroll_page())
            return self.send_text(200, setup_page())
        if path == "/setup-qr.png":
            qr = ensure_setup_qr()
            if os.path.exists(qr):
                self.send_file(qr, "setup-qr.png", "image/png")
                return
            self.send_response(404)
            self.end_headers()
            return

        user = self.current_user()

        if path in ("/", "/index.html"):
            if not user:
                self.send_text(200, login_page())
            else:
                self.send_text(200, dashboard(user["username"]))
            return

        if path == "/favicon.ico":
            self.send_response(204)
            self.end_headers()
            return

        self.send_response(404)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_POST(self):
        if getattr(self.server, "plain", False):
            return self.send_redirect("https://%s:%d%s" % (get_lan_ip(), PORT, self.path))
        path = urlparse(self.path).path
        length = int(self.headers.get("Content-Length", 0) or 0)
        body = self.rfile.read(length).decode("utf-8", "ignore") if length else ""
        if path.startswith("/api/"):
            return self.api_post(path, body)
        form = parse_qs(body)

        def field(name):
            v = form.get(name, [""])
            return v[0] if v else ""

        if path == "/auth":
            state = load_state()
            username = field("username").strip() or DEFAULT_USERNAME
            password = field("password")

            if "user" not in state:
                confirm = field("confirm")
                if len(password) < 8:
                    return self.send_text(200, login_page(("err", "Password must be at least 8 characters.")))
                if password != confirm:
                    return self.send_text(200, login_page(("err", "Passwords do not match.")))
                salt, dk = hash_password(password)
                state["user"] = {"username": username, "salt": salt, "hash": dk}
                save_state(state)
            else:
                u = state["user"]
                if username != u["username"] or not verify_password(password, u["salt"], u["hash"]):
                    return self.send_text(200, login_page(("err", "Invalid username or password.")))

            token = create_session(username)
            self.send_response(302)
            self.set_cookie(SESSION_COOKIE, token)
            self.send_header("Location", "/")
            self.end_headers()
            return

        if path == "/logout":
            self.send_response(302)
            self.clear_cookie(SESSION_COOKIE)
            self.send_header("Location", "/")
            self.end_headers()
            return

        user = self.current_user()
        if not user:
            return self.send_redirect("/")

        if path == "/issue":
            cn = field("cn").strip()
            sans = [s for s in field("sans").split(",") if s.strip()]
            try:
                days = int(field("days") or "398")
            except ValueError:
                days = 398
            keypass = field("keypass")
            if not cn:
                return self.send_redirect("/")
            try:
                out_dir, cn = issue_certificate(cn, sans, days, keypass)
            except Exception as e:
                return self.send_text(200, dashboard(user["username"]).replace(
                    "<h1>Our network</h1>",
                    '<div class="flash err">Issue failed: %s</div><h1>Our network</h1>' % esc(str(e))))

            zip_path = os.path.join(out_dir, cn + ".zip")
            with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
                z.write(os.path.join(out_dir, cn + ".key"), cn + ".key")
                z.write(os.path.join(out_dir, cn + ".crt"), cn + ".crt")
                z.write(os.path.join(out_dir, cn + "-fullchain.crt"), cn + "-fullchain.crt")
                z.write(BUNDLE_CRT, "ca-bundle.crt")
                if keypass:
                    z.write(os.path.join(out_dir, cn + ".p12"), cn + ".p12")
            self.send_file(zip_path, cn + "-certs.zip", "application/zip")
            return

        if path == "/dns/add":
            dns = load_dns()
            name = field("name").strip()
            typ = field("type").strip().upper()
            value = field("value").strip()
            ttl = field("ttl").strip()
            if not name or not value or typ not in TYPE_NAMES:
                return self.send_redirect("/")
            try:
                ttl = int(ttl or 3600)
            except ValueError:
                ttl = 3600
            dns["records"].append({"name": name, "type": typ, "value": value, "ttl": ttl})
            save_dns(dns)
            return self.send_redirect("/")

        if path == "/dns/delete":
            dns = load_dns()
            name, typ, value = field("name"), field("type"), field("value")
            dns["records"] = [r for r in dns["records"]
                              if not (r["name"] == name and r["type"] == typ and r["value"] == value)]
            save_dns(dns)
            return self.send_redirect("/")

        if path == "/reservation/add":
            res = load_reservations()
            name = field("name").strip()
            mac = field("mac").strip()
            ip = field("ip").strip()
            if not name or not is_valid_ip(ip):
                return self.send_redirect("/")
            res = [r for r in res if r["name"] != name]
            res.append({"name": name, "mac": mac, "ip": ip})
            save_reservations(res)
            return self.send_redirect("/")

        if path == "/reservation/delete":
            res = load_reservations()
            name = field("name")
            res = [r for r in res if r["name"] != name]
            save_reservations(res)
            return self.send_redirect("/")

        return self.send_redirect("/")


# --------------------------------------------------------------------------
# Main
# --------------------------------------------------------------------------

class MultiprotocolHTTPServer(ThreadingHTTPServer):
    tls_context = None

    def get_request(self):
        sock, addr = super().get_request()
        ctx = getattr(self, "tls_context", None)
        if ctx is not None:
            try:
                for _ in range(10):
                    first = sock.recv(3, socket.MSG_PEEK)
                    if first[:1] == b"\x16":  # TLS ClientHello
                        return ctx.wrap_socket(sock, server_side=True), addr
                    if first:
                        break
                    time.sleep(0.02)
            except Exception:
                pass
        return sock, addr


def main():
    global DNS_ACTUAL_PORT
    try:
        sys.stdout.reconfigure(line_buffering=True)
    except Exception:
        pass
    ensure_dirs()
    bootstrap_ca()
    ensure_server_cert()
    ensure_setup_qr()

    dns_server = DNSServer(DNS_PORT, UPSTREAM_DNS)
    try:
        dns_server.start()
    except PermissionError:
        dns_server = DNSServer(DNS_FALLBACK_PORT, UPSTREAM_DNS)
        try:
            dns_server.start()
            DNS_ACTUAL_PORT = DNS_FALLBACK_PORT
            print("WARNING: could not bind DNS port %d (need root); using %d."
                  % (DNS_PORT, DNS_FALLBACK_PORT))
        except OSError as e:
            print("WARNING: DNS server failed to start: %s" % e)
    except OSError as e:
        print("WARNING: DNS server failed to start: %s" % e)
    else:
        DNS_ACTUAL_PORT = dns_server.port

    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(certfile=SERVER_FULLCHAIN, keyfile=SERVER_KEY)
    ctx.minimum_version = ssl.TLSVersion.TLSv1_2

    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)

    try:
        plain = MultiprotocolHTTPServer((HOST, PORT_HTTP), Handler)
        plain.plain = True
        plain.tls_context = ctx
        threading.Thread(target=plain.serve_forever, daemon=True).start()
    except OSError as e:
        print("WARNING: HTTP enrollment server failed: %s" % e)

    print("Home Network Portal running.")
    print("  web  : https://localhost:%d" % PORT)
    print("  lan  : https://%s:%d" % (get_lan_ip(), PORT))
    print("  enroll: %s" % enroll_url("/setup"))
    print("  dns  : %s:%d (zone served + forwarding to %s)" % (HOST, DNS_ACTUAL_PORT, UPSTREAM_DNS))
    print("Ctrl-C to stop.")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nStopping.")


if __name__ == "__main__":
    main()
