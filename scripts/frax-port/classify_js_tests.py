#!/usr/bin/env python3
"""Classify frax-solidity Hardhat JS tests for Phase 6 porting."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
TEST_DIR = ROOT / "lib/frax-solidity/src/hardhat/test"

CHAIN_PREFIXES = {
    "__ARBITRUM": "arbitrum",
    "__AURORA": "aurora",
    "__AVALANCHE": "avalanche",
    "__BSC": "bsc",
    "__FANTOM": "fantom",
    "__HARMONY": "harmony",
    "__MOONBEAM": "moonbeam",
    "__MOONRIVER": "moonriver",
    "__OPTIMISM": "optimism",
    "__POLYGON": "polygon",
}

FIXTURE_NAMES = {
    "truffle-fixture.js",
    "truffle-fixture-Ethereum.js",
    "truffle-fixture-Aurora.js",
    "truffle-fixture-Avalanche.js",
    "truffle-fixture-BSC.js",
    "truffle-fixture-Fantom.js",
    "truffle-fixture-Harmony.js",
    "truffle-fixture-Moonbeam.js",
    "truffle-fixture-Moonriver.js",
    "truffle-fixture-Optimism.js",
    "truffle-fixture-Polygon.js",
    "truffle-fixture-old.js",
}


def classify(rel: str) -> dict:
    name = Path(rel).name
    if name in FIXTURE_NAMES or name.startswith("truffle-fixture"):
        return {
            "category": "fixture",
            "target": "setUp() in chain fork/spec tests",
        }
    if rel.startswith("old_tests/"):
        return {
            "category": "old_tests",
            "target": "test/foundry/spec/protocols/tokens/stable/frax/old_tests/",
        }
    for prefix, chain in CHAIN_PREFIXES.items():
        if rel.startswith(prefix + "/"):
            return {
                "category": "fork",
                "chain": chain,
                "target": f"test/foundry/fork/{chain}/protocols/tokens/stable/frax/",
            }
    parts = rel.split("/")
    if len(parts) > 1:
        bucket = parts[0]
        return {
            "category": "spec_bucket",
            "bucket": bucket,
            "target": f"test/foundry/spec/protocols/tokens/stable/frax/{bucket}/",
        }
    return {
        "category": "spec",
        "target": "test/foundry/spec/protocols/tokens/stable/frax/",
    }


def main() -> None:
    entries = []
    for path in sorted(TEST_DIR.rglob("*.js")):
        rel = path.relative_to(TEST_DIR).as_posix()
        info = classify(rel)
        entries.append({"path": rel, **info})

    out = {
        "total": len(entries),
        "by_category": {},
        "entries": entries,
    }
    for e in entries:
        cat = e["category"]
        out["by_category"].setdefault(cat, 0)
        out["by_category"][cat] += 1

    out_path = Path(__file__).parent / "js-test-inventory.json"
    out_path.write_text(json.dumps(out, indent=2) + "\n")
    print(json.dumps(out["by_category"], indent=2))
    print(f"wrote {out_path}")


if __name__ == "__main__":
    main()