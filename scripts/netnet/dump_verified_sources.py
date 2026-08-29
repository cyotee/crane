#!/usr/bin/env python3
"""Resumable dump of NetNet verified sources on Robinhood Chain (4663).

Tries Sourcify, then the authenticated Blockscout PRO API when
BLOCKSCOUT_API_KEY or BLOCKSCOUT_PRO_API_KEY is set (same data as the
Robinhood instance, without the public Cloudflare wall). Public instance
APIs are only used when no key is present. Last resort: eth-bytecode-db.

Throttle on one backend switches to the next. If every backend is cooling,
exit 2; re-run to resume.
"""

from __future__ import annotations

import argparse
import json
import os
import ssl
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
CATALOG_PATH = HERE / "contracts.json"
DUMP_DIR = HERE / "dump"
STATE_PATH = DUMP_DIR / "state.json"
BY_ADDRESS_DIR = DUMP_DIR / "by-address"
TREE_DIR = DUMP_DIR / "tree"
CONFLICTS_DIR = DUMP_DIR / "conflicts"

CHAIN_ID = 4663
USER_AGENT = "crane-netnet-dump/1.0 (+https://docs.netnet.capital/official-channels)"
DEFAULT_DELAY = 1.25
REQUEST_TIMEOUT = 45
COOL_INITIAL = 45
COOL_MAX = 900

THROTTLE_STATUS = {429, 502, 503, 504}
CF_MARKERS = ("just a moment", "cf-ray", "challenge-platform", "attention required")

BACKEND_ORDER_WITH_KEY = (
    "sourcify",
    "blockscout_pro",
    "eth_bytecode_db",
)
BACKEND_ORDER_NO_KEY = (
    "sourcify",
    "blockscout_v2",
    "blockscout_legacy",
    "eth_bytecode_db",
)


def pro_api_key() -> str:
    return (
        os.environ.get("BLOCKSCOUT_API_KEY", "").strip()
        or os.environ.get("BLOCKSCOUT_PRO_API_KEY", "").strip()
    )


def backend_order() -> tuple[str, ...]:
    return BACKEND_ORDER_WITH_KEY if pro_api_key() else BACKEND_ORDER_NO_KEY


class ThrottleError(Exception):
    """This backend should cool down; try the next one."""


class UnverifiedError(Exception):
    """This backend has no source for the address; try the next one."""


@dataclass
class Dump:
    files: dict[str, str]
    contract_name: str
    compiler: str
    backend: str
    extra: dict[str, Any]


def checksum_key(addr: str) -> str:
    return addr.lower()


def atomic_write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    tmp.replace(path)


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def is_cf_challenge(body: str) -> bool:
    low = body.lower()
    return any(m in low for m in CF_MARKERS)


def http_json(
    url: str,
    *,
    method: str = "GET",
    headers: dict[str, str] | None = None,
    data: bytes | None = None,
    timeout: int = REQUEST_TIMEOUT,
) -> tuple[int, Any, str]:
    hdrs = {"User-Agent": USER_AGENT, "Accept": "application/json"}
    if headers:
        hdrs.update(headers)
    req = urllib.request.Request(url, data=data, headers=hdrs, method=method)
    ctx = ssl.create_default_context()
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=ctx) as resp:
            raw = resp.read()
            text = raw.decode("utf-8", errors="replace")
            try:
                return resp.status, json.loads(text), text
            except json.JSONDecodeError as exc:
                if is_cf_challenge(text):
                    raise ThrottleError(f"cloudflare challenge on {url}") from exc
                raise UnverifiedError(f"non-json response from {url}") from exc
    except urllib.error.HTTPError as exc:
        raw = exc.read()
        text = raw.decode("utf-8", errors="replace")
        if exc.code in THROTTLE_STATUS or is_cf_challenge(text):
            raise ThrottleError(f"HTTP {exc.code} {url}") from exc
        if exc.code in {404, 400}:
            raise UnverifiedError(f"HTTP {exc.code} {url}") from exc
        if exc.code == 403 and is_cf_challenge(text):
            raise ThrottleError(f"HTTP 403 cloudflare {url}") from exc
        if exc.code == 403:
            raise ThrottleError(f"HTTP 403 {url}") from exc
        raise RuntimeError(f"HTTP {exc.code} {url}: {text[:240]}") from exc
    except urllib.error.URLError as exc:
        raise ThrottleError(f"connect error {url}: {exc}") from exc
    except TimeoutError as exc:
        raise ThrottleError(f"timeout {url}") from exc


def unwrap_blockscout_source(source_code: str) -> dict[str, str]:
    text = (source_code or "").strip()
    if not text:
        return {}
    if text.startswith("{{") and text.endswith("}}"):
        text = text[1:-1]
    if text.startswith("{"):
        try:
            blob = json.loads(text)
        except json.JSONDecodeError:
            return {"Contract.sol": source_code}
        sources = blob.get("sources") if isinstance(blob, dict) else None
        if isinstance(sources, dict):
            out: dict[str, str] = {}
            for path, spec in sources.items():
                if isinstance(spec, dict) and "content" in spec:
                    out[path] = spec["content"]
                elif isinstance(spec, str):
                    out[path] = spec
            if out:
                return out
    return {"Contract.sol": source_code}


def fetch_sourcify(addr: str, _rpc: str) -> Dump:
    url = f"https://sourcify.dev/server/v2/contract/{CHAIN_ID}/{addr}?fields=all"
    _status, data, _text = http_json(url)
    if not isinstance(data, dict) or data.get("match") not in {"exact_match", "match", "partial_match"}:
        raise UnverifiedError("sourcify: no match")
    sources = data.get("sources") or {}
    files: dict[str, str] = {}
    for path, spec in sources.items():
        if isinstance(spec, dict) and spec.get("content"):
            files[path] = spec["content"]
    if not files:
        sji = data.get("stdJsonInput") or {}
        for path, spec in (sji.get("sources") or {}).items():
            if isinstance(spec, dict) and spec.get("content"):
                files[path] = spec["content"]
    if not files:
        raise UnverifiedError("sourcify: empty sources")
    compilation = data.get("compilation") or {}
    return Dump(
        files=files,
        contract_name=str(compilation.get("name") or "Unknown"),
        compiler=str(compilation.get("compilerVersion") or ""),
        backend="sourcify",
        extra={
            "match": data.get("match"),
            "fullyQualifiedName": compilation.get("fullyQualifiedName"),
            "verifiedAt": data.get("verifiedAt"),
        },
    )


def fetch_blockscout_v2(addr: str, _rpc: str) -> Dump:
    url = f"https://robinhoodchain.blockscout.com/api/v2/smart-contracts/{addr}"
    _status, data, _text = http_json(url)
    if not isinstance(data, dict) or not data.get("is_verified"):
        raise UnverifiedError("blockscout_v2: not verified")
    files: dict[str, str] = {}
    main = data.get("file_path") or "Contract.sol"
    if data.get("source_code"):
        files[main] = data["source_code"]
    for extra in data.get("additional_sources") or []:
        path = extra.get("file_path") or extra.get("fileName")
        content = extra.get("source_code") or extra.get("SourceCode")
        if path and content:
            files[path] = content
    if not files:
        raise UnverifiedError("blockscout_v2: empty source")
    return Dump(
        files=files,
        contract_name=str(data.get("name") or "Unknown"),
        compiler=str(data.get("compiler_version") or ""),
        backend="blockscout_v2",
        extra={"optimization_runs": data.get("optimization_runs"), "evm_version": data.get("evm_version")},
    )


def fetch_blockscout_legacy(addr: str, _rpc: str) -> Dump:
    url = (
        "https://robinhoodchain.blockscout.com/api"
        f"?module=contract&action=getsourcecode&address={addr}"
    )
    _status, data, _text = http_json(url)
    results = (data or {}).get("result") if isinstance(data, dict) else None
    if not results:
        raise UnverifiedError("blockscout_legacy: empty result")
    row = results[0]
    name = row.get("ContractName") or ""
    compiler = row.get("CompilerVersion") or ""
    if not name and not row.get("SourceCode"):
        raise UnverifiedError("blockscout_legacy: not verified")
    files = unwrap_blockscout_source(row.get("SourceCode") or "")
    for extra in row.get("AdditionalSources") or []:
        path = extra.get("Filename") or extra.get("file_path")
        content = extra.get("SourceCode") or extra.get("source_code")
        if path and content:
            files[path] = content
    if not files:
        raise UnverifiedError("blockscout_legacy: empty source")
    if name and "Contract.sol" in files and len(files) == 1:
        files = {f"src/{name}.sol": files["Contract.sol"]}
    return Dump(
        files=files,
        contract_name=str(name or "Unknown"),
        compiler=str(compiler),
        backend="blockscout_legacy",
        extra={"evm": row.get("EVMVersion"), "runs": row.get("OptimizationRuns") or row.get("Runs")},
    )


def fetch_blockscout_pro(addr: str, _rpc: str) -> Dump:
    key = pro_api_key()
    if not key:
        raise UnverifiedError("blockscout_pro: BLOCKSCOUT_API_KEY unset")
    url = f"https://api.blockscout.com/{CHAIN_ID}/api/v2/smart-contracts/{addr}"
    _status, data, _text = http_json(url, headers={"Authorization": f"Bearer {key}"})
    if not isinstance(data, dict) or not (data.get("is_verified") or data.get("source_code")):
        raise UnverifiedError("blockscout_pro: not verified")
    files: dict[str, str] = {}
    main = data.get("file_path") or "Contract.sol"
    if data.get("source_code"):
        files[main] = data["source_code"]
    for extra in data.get("additional_sources") or []:
        path = extra.get("file_path")
        content = extra.get("source_code")
        if path and content:
            files[path] = content
    if not files:
        raise UnverifiedError("blockscout_pro: empty source")
    return Dump(
        files=files,
        contract_name=str(data.get("name") or "Unknown"),
        compiler=str(data.get("compiler_version") or ""),
        backend="blockscout_pro",
        extra={},
    )


def rpc_get_code(rpc: str, addr: str) -> str:
    payload = json.dumps(
        {"jsonrpc": "2.0", "id": 1, "method": "eth_getCode", "params": [addr, "latest"]}
    ).encode()
    _status, data, _text = http_json(
        rpc,
        method="POST",
        headers={"Content-Type": "application/json"},
        data=payload,
    )
    if not isinstance(data, dict) or not data.get("result") or data["result"] == "0x":
        raise UnverifiedError("rpc: no bytecode")
    return str(data["result"])


def fetch_eth_bytecode_db(addr: str, rpc: str) -> Dump:
    code = rpc_get_code(rpc, addr)
    url = "https://eth-bytecode-db.blockscout.com/api/v2/bytecodes/sources:search"
    body = json.dumps(
        {"bytecode": code, "bytecodeType": "BYTECODE_TYPE_DEPLOYED_BYTECODE"}
    ).encode()
    _status, data, _text = http_json(
        url, method="POST", headers={"Content-Type": "application/json"}, data=body
    )
    items = data.get("sources") if isinstance(data, dict) else None
    if not items and isinstance(data, list):
        items = data
    if not items:
        raise UnverifiedError("eth_bytecode_db: no hit")
    hit = items[0]
    files: dict[str, str] = {}
    source_files = hit.get("sourceFiles") or hit.get("sources") or {}
    if isinstance(source_files, dict):
        for path, spec in source_files.items():
            if isinstance(spec, dict) and spec.get("content"):
                files[path] = spec["content"]
            elif isinstance(spec, str):
                files[path] = spec
    if not files and hit.get("source_code"):
        files = unwrap_blockscout_source(hit["source_code"])
    if not files:
        raise UnverifiedError("eth_bytecode_db: empty files")
    return Dump(
        files=files,
        contract_name=str(hit.get("contractName") or hit.get("name") or "Unknown"),
        compiler=str(hit.get("compiler") or hit.get("compilerVersion") or ""),
        backend="eth_bytecode_db",
        extra={},
    )


FETCHERS = {
    "sourcify": fetch_sourcify,
    "blockscout_v2": fetch_blockscout_v2,
    "blockscout_legacy": fetch_blockscout_legacy,
    "blockscout_pro": fetch_blockscout_pro,
    "eth_bytecode_db": fetch_eth_bytecode_db,
}


def empty_state(catalog: dict[str, Any]) -> dict[str, Any]:
    contracts: dict[str, Any] = {}
    for row in catalog["contracts"]:
        key = checksum_key(row["address"])
        contracts[key] = {
            "id": row["id"],
            "address": row["address"],
            "group": row.get("group"),
            "status": "skipped" if row.get("skip") else "pending",
            "skip_reason": row.get("skip_reason"),
            "backend": None,
            "files": [],
            "error": None,
            "attempts": 0,
        }
    return {
        "version": 1,
        "chain_id": CHAIN_ID,
        "backends": {
            name: {"cool_until": 0, "throttle_count": 0}
            for name in BACKEND_ORDER_WITH_KEY + BACKEND_ORDER_NO_KEY
        },
        "contracts": contracts,
        "stopped_on": None,
    }


def merge_catalog_into_state(state: dict[str, Any], catalog: dict[str, Any]) -> None:
    existing = state.setdefault("contracts", {})
    for row in catalog["contracts"]:
        key = checksum_key(row["address"])
        if key not in existing:
            existing[key] = {
                "id": row["id"],
                "address": row["address"],
                "group": row.get("group"),
                "status": "skipped" if row.get("skip") else "pending",
                "skip_reason": row.get("skip_reason"),
                "backend": None,
                "files": [],
                "error": None,
                "attempts": 0,
            }
        else:
            existing[key]["id"] = row["id"]
            existing[key]["group"] = row.get("group")
            if row.get("skip") and existing[key]["status"] == "pending":
                existing[key]["status"] = "skipped"
                existing[key]["skip_reason"] = row.get("skip_reason")
    state.setdefault("backends", {})
    for name in BACKEND_ORDER_WITH_KEY + BACKEND_ORDER_NO_KEY:
        state["backends"].setdefault(name, {"cool_until": 0, "throttle_count": 0})


def backend_ready(state: dict[str, Any], name: str, now: float) -> bool:
    cool = float(state["backends"][name].get("cool_until") or 0)
    return now >= cool


def mark_cool(state: dict[str, Any], name: str, now: float) -> None:
    info = state["backends"][name]
    n = int(info.get("throttle_count") or 0) + 1
    info["throttle_count"] = n
    delay = min(COOL_MAX, COOL_INITIAL * (2 ** max(0, n - 1)))
    info["cool_until"] = now + delay
    print(f"  ! {name} cooling {int(delay)}s")


def write_dump(addr: str, dump: Dump) -> list[str]:
    root = BY_ADDRESS_DIR / addr.lower()
    files_dir = root / "files"
    if files_dir.exists():
        for old in files_dir.rglob("*"):
            if old.is_file():
                old.unlink()
    written: list[str] = []
    for rel, content in dump.files.items():
        rel_path = Path(rel)
        if rel_path.is_absolute() or ".." in rel_path.parts:
            rel_path = Path(rel_path.name)
        dest = files_dir / rel_path
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(content, encoding="utf-8")
        written.append(str(rel_path).replace("\\", "/"))
        merge_into_tree(rel_path, content, addr)
    meta = {
        "address": addr,
        "contract_name": dump.contract_name,
        "compiler": dump.compiler,
        "backend": dump.backend,
        "files": written,
        "extra": dump.extra,
    }
    atomic_write_json(root / "metadata.json", meta)
    return written


def merge_into_tree(rel: Path, content: str, addr: str) -> None:
    dest = TREE_DIR / rel
    if dest.exists():
        existing = dest.read_text(encoding="utf-8")
        if existing == content:
            return
        conflict = CONFLICTS_DIR / addr.lower() / rel
        conflict.parent.mkdir(parents=True, exist_ok=True)
        conflict.write_text(content, encoding="utf-8")
        print(f"  ! conflict {rel} (kept tree/, extra copy in conflicts/{addr.lower()}/)")
        return
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(content, encoding="utf-8")


def rebuild_tree(state: dict[str, Any]) -> None:
    if TREE_DIR.exists():
        for old in TREE_DIR.rglob("*"):
            if old.is_file():
                old.unlink()
    for key, rec in state["contracts"].items():
        if rec.get("status") != "done":
            continue
        files_dir = BY_ADDRESS_DIR / key / "files"
        if not files_dir.exists():
            continue
        for path in files_dir.rglob("*"):
            if path.is_file():
                rel = path.relative_to(files_dir)
                merge_into_tree(rel, path.read_text(encoding="utf-8"), rec["address"])


def dump_one(row: dict[str, Any], state: dict[str, Any], rpc: str, delay: float) -> str:
    """Return 'done' | 'unverified' | 'error' | 'stop'."""
    addr = row["address"]
    key = checksum_key(addr)
    rec = state["contracts"][key]
    rec["attempts"] = int(rec.get("attempts") or 0) + 1
    now = time.time()
    last_unverified: list[str] = []

    def active_backends() -> list[str]:
        return list(backend_order())

    for name in active_backends():
        if not backend_ready(state, name, now):
            continue
        try:
            if delay:
                time.sleep(delay)
            dump = FETCHERS[name](addr, rpc)
        except ThrottleError as exc:
            print(f"  throttle {name}: {exc}")
            mark_cool(state, name, time.time())
            continue
        except UnverifiedError as exc:
            print(f"  miss {name}: {exc}")
            last_unverified.append(f"{name}: {exc}")
            continue
        except Exception as exc:
            print(f"  error {name}: {exc}")
            rec["error"] = f"{name}: {exc}"
            rec["status"] = "error"
            return "error"

        files = write_dump(addr, dump)
        rec["status"] = "done"
        rec["backend"] = dump.backend
        rec["files"] = files
        rec["error"] = None
        rec["contract_name"] = dump.contract_name
        rec["compiler"] = dump.compiler
        state["backends"][name]["throttle_count"] = 0
        print(f"  ok {name} -> {dump.contract_name} ({len(files)} files)")
        return "done"

    still_cooling = any(not backend_ready(state, name, time.time()) for name in active_backends())
    if still_cooling or not last_unverified:
        rec["status"] = "pending"
        rec["error"] = "backends throttled or cooling; resume later"
        state["stopped_on"] = addr
        return "stop"

    rec["status"] = "unverified"
    rec["error"] = "; ".join(last_unverified)
    print(f"  unverified: {rec['error']}")
    return "unverified"


def summarize(state: dict[str, Any]) -> None:
    counts: dict[str, int] = {}
    for rec in state["contracts"].values():
        st = rec.get("status") or "pending"
        counts[st] = counts.get(st, 0) + 1
    print("summary:", ", ".join(f"{k}={v}" for k, v in sorted(counts.items())))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--group", help="Only this catalog group (core, futures, arcade, ...)")
    parser.add_argument("--only", action="append", default=[], help="Catalog id (repeatable)")
    parser.add_argument("--delay", type=float, default=DEFAULT_DELAY, help="Seconds between HTTP calls")
    parser.add_argument("--retry-errors", action="store_true", help="Retry status=error rows")
    parser.add_argument("--retry-unverified", action="store_true", help="Retry status=unverified rows")
    parser.add_argument("--merge-only", action="store_true", help="Rebuild tree/ from by-address/")
    parser.add_argument("--rpc", default=os.environ.get("RH_RPC_URL", ""))
    args = parser.parse_args()

    catalog = load_json(CATALOG_PATH)
    if not catalog.get("contracts"):
        print("missing catalog", CATALOG_PATH, file=sys.stderr)
        return 1

    DUMP_DIR.mkdir(parents=True, exist_ok=True)
    state = load_json(STATE_PATH)
    if not state:
        state = empty_state(catalog)
    else:
        merge_catalog_into_state(state, catalog)

    if args.merge_only:
        rebuild_tree(state)
        print("rebuilt", TREE_DIR)
        return 0

    rpc = args.rpc or catalog.get("rpc_url") or "https://rpc.mainnet.chain.robinhood.com"
    only = {x.strip() for x in args.only if x.strip()}
    wanted: list[dict[str, Any]] = []
    for row in catalog["contracts"]:
        if row.get("skip"):
            continue
        if args.group and row.get("group") != args.group:
            continue
        if only and row["id"] not in only:
            continue
        key = checksum_key(row["address"])
        st = state["contracts"][key]["status"]
        if st == "done":
            continue
        if st == "unverified" and not args.retry_unverified:
            continue
        if st == "error" and not args.retry_errors:
            continue
        if st == "skipped":
            continue
        wanted.append(row)

    if not wanted:
        print("nothing to do (all matching rows done/skipped/unverified)")
        summarize(state)
        return 0

    order = backend_order()
    keyed = "yes" if pro_api_key() else "no"
    print(f"queue {len(wanted)} contracts; PRO key={keyed}; backends {', '.join(order)}")
    for row in wanted:
        key = checksum_key(row["address"])
        print(f"{row['id']} {row['address']}")
        result = dump_one(row, state, rpc, args.delay)
        atomic_write_json(STATE_PATH, state)
        if result == "stop":
            print(
                f"stopped: all backends throttled at {row['id']} {row['address']}\n"
                "re-run the same command later to resume from this contract"
            )
            summarize(state)
            return 2

    state["stopped_on"] = None
    atomic_write_json(STATE_PATH, state)
    summarize(state)
    return 0


if __name__ == "__main__":
    sys.exit(main())
