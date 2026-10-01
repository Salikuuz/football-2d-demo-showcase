#!/usr/bin/env python3
"""Fetch Godot's no-threads Web templates from the official export TPZ.

Uses HTTP range requests when supported so CI doesn't need to download the full ~1.3 GB
export template archive. Falls back to a full download if range extraction is unavailable.
"""
from __future__ import annotations

import struct
import sys
import tempfile
import urllib.request
import zipfile
import zlib
from pathlib import Path

TARGETS = {
    "templates/web_nothreads_release.zip": "web_nothreads_release.zip",
    "templates/web_nothreads_debug.zip": "web_nothreads_debug.zip",
    "templates/version.txt": "version.txt",
}


def request(url: str, start: int | None = None, end: int | None = None):
    headers = {"User-Agent": "TheodoreBall-WebBuilder/1.0"}
    if start is not None:
        headers["Range"] = f"bytes={start}-{'' if end is None else end}"
    req = urllib.request.Request(url, headers=headers)
    return urllib.request.urlopen(req, timeout=120)


def total_size(url: str) -> int:
    with request(url, 0, 0) as r:
        cr = r.headers.get("Content-Range", "")
        if "/" in cr:
            return int(cr.rsplit("/", 1)[1])
        cl = r.headers.get("Content-Length")
        if cl and r.status == 200:
            return int(cl)
    raise RuntimeError("Server did not expose archive size/range support")


def read_range(url: str, start: int, end: int) -> bytes:
    with request(url, start, end) as r:
        data = r.read()
        expected = end - start + 1
        if r.status != 206 or len(data) != expected:
            raise RuntimeError(f"Range request failed ({r.status}, got {len(data)}, expected {expected})")
        return data


def central_directory(url: str, size: int):
    tail_len = min(size, 131072)
    tail_start = size - tail_len
    tail = read_range(url, tail_start, size - 1)
    idx = tail.rfind(b"PK\x05\x06")
    if idx < 0:
        raise RuntimeError("ZIP end-of-central-directory not found")
    eocd = tail[idx:idx + 22]
    if len(eocd) < 22:
        raise RuntimeError("Truncated ZIP EOCD")
    (_sig, _disk, _cd_disk, _disk_entries, _entries, cd_size, cd_offset, _comment_len) = struct.unpack("<4s4H2LH", eocd)
    if cd_size == 0xFFFFFFFF or cd_offset == 0xFFFFFFFF:
        raise RuntimeError("ZIP64 archive requires fallback full download")
    return read_range(url, cd_offset, cd_offset + cd_size - 1)


def parse_entries(cd: bytes):
    pos = 0
    result = {}
    while pos + 46 <= len(cd):
        if cd[pos:pos + 4] != b"PK\x01\x02":
            break
        fields = struct.unpack_from("<4s6H3L5H2L", cd, pos)
        method = fields[4]
        compressed_size = fields[8]
        uncompressed_size = fields[9]
        name_len = fields[10]
        extra_len = fields[11]
        comment_len = fields[12]
        local_offset = fields[16]
        name_start = pos + 46
        name = cd[name_start:name_start + name_len].decode("utf-8")
        result[name] = (method, compressed_size, uncompressed_size, local_offset)
        pos = name_start + name_len + extra_len + comment_len
    return result


def fetch_member(url: str, meta) -> bytes:
    method, compressed_size, uncompressed_size, local_offset = meta
    header = read_range(url, local_offset, local_offset + 29)
    if header[:4] != b"PK\x03\x04":
        raise RuntimeError("Bad local ZIP header")
    values = struct.unpack("<4s5H3L2H", header)
    name_len, extra_len = values[-2], values[-1]
    data_start = local_offset + 30 + name_len + extra_len
    raw = read_range(url, data_start, data_start + compressed_size - 1)
    if method == 0:
        out = raw
    elif method == 8:
        out = zlib.decompress(raw, -zlib.MAX_WBITS)
    else:
        raise RuntimeError(f"Unsupported compression method {method}")
    if len(out) != uncompressed_size:
        raise RuntimeError("Extracted member size mismatch")
    return out


def range_extract(url: str, dest: Path):
    size = total_size(url)
    cd = central_directory(url, size)
    entries = parse_entries(cd)
    missing = [n for n in TARGETS if n not in entries]
    if missing:
        raise RuntimeError(f"Required members not found: {missing}")
    for member, out_name in TARGETS.items():
        data = fetch_member(url, entries[member])
        (dest / out_name).write_bytes(data)
        print(f"Fetched {member} ({len(data) / 1024 / 1024:.1f} MiB)")


def full_extract(url: str, dest: Path):
    print("Range extraction unavailable; falling back to full official TPZ download.")
    with tempfile.NamedTemporaryFile(suffix=".tpz", delete=False) as tmp:
        tmp_path = Path(tmp.name)
        with request(url) as r:
            while True:
                chunk = r.read(8 * 1024 * 1024)
                if not chunk:
                    break
                tmp.write(chunk)
    try:
        with zipfile.ZipFile(tmp_path) as zf:
            for member, out_name in TARGETS.items():
                (dest / out_name).write_bytes(zf.read(member))
    finally:
        tmp_path.unlink(missing_ok=True)


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <export_templates_tpz_url> <destination_dir>", file=sys.stderr)
        return 2
    url = sys.argv[1]
    dest = Path(sys.argv[2])
    dest.mkdir(parents=True, exist_ok=True)
    try:
        range_extract(url, dest)
    except Exception as exc:
        print(f"Partial template fetch failed: {exc}", file=sys.stderr)
        full_extract(url, dest)
    required = [dest / "web_nothreads_release.zip", dest / "web_nothreads_debug.zip"]
    for path in required:
        if not path.is_file() or path.stat().st_size < 1_000_000:
            raise RuntimeError(f"Godot Web export template was not installed correctly: {path.name}")
    print(f"Godot Web templates ready at {dest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
