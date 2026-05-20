#!/usr/bin/env python3
"""Build Frax JS → Foundry port coverage matrix from inventory + known status."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
INVENTORY = Path(__file__).parent / "js-test-inventory.json"
SPEC_ROOT = ROOT / "test/foundry/spec/protocols/tokens/stable/frax"
FORK_ROOT = ROOT / "test/foundry/fork"

# Exact path → status (complete | partial | fork-only | deferred | not-started)
PATH_STATUS: dict[str, str] = {
    "BAMM/BAMM.js": "complete",
    "BAMM/BAMM-Fuzz.js": "complete",
    "BAMM/BAMMHelper.js": "complete",
    "BAMM/FraxswapOracle.js": "complete",
    "Fraxbonds/SlippageAuction.js": "complete",
    "LeveragePool-test.js": "complete",
    "FPI-FPIS-Tests.js": "complete",
    "CrossChainCanonical-Tests.js": "complete",
    "Fraxswap-FraxswapRange-test.js": "complete",
    "Fraxswap-UniswapV2-test.js": "complete",
    "Fraxswap/fraxswap-uniV2-test.js": "complete",
    "Fraxswap/fraxswap-twamm-test.js": "complete",
    "Fraxswap/fraxswap-twamm-test-unbalanced.js": "complete",
    "Fraxswap/fraxswap-router-test.js": "partial",
    "Fraxferry/Fraxferry-test.js": "complete",
    "FraxferryV2/FerryV2-test.js": "partial",
    "Fraxoracle/Fraxoracle-test.js": "partial",
    "Fraxoracle/StateProver-test.js": "complete",
    "Fraxoracle/StateRootOracle.js": "partial",
    "veFXSYieldDistributorV4-Tests.js": "complete",
    "FraxGaugeFXSRewardsDistributor-Tests.js": "complete",
    "CPITrackerOracle-Tests.js": "complete",
    "ComboOracle_SLP_UniV2_UniV3-Tests.js": "complete",
    "UniV3TWAPOracle-Tests.js": "complete",
    "FPIControllerPool-Tests.js": "complete",
    "Governance_Slap_2.js": "complete",
    "TWAMM_AMO-Tests.js": "complete",
    "FrxETH/FrxETHMiniRouter-Tests.js": "complete",
}

# Bucket-level default when path not listed
BUCKET_STATUS: dict[str, str] = {
    "BAMM": "complete",
    "Fraxbonds": "complete",
    "Fraxswap": "partial",
    "Fraxferry": "complete",
    "FraxferryV2": "partial",
    "Fraxoracle": "partial",
    "FrxETH": "partial",
    "Lending_AMOs": "not-started",
}

# Top-level spec files with Foundry equivalents (basename patterns)
SPEC_FILE_HINTS: dict[str, str] = {
    "LeveragePool-test.js": "LeveragePool/LeveragePool_test.t.sol",
    "FPI-FPIS-Tests.js": "FPI/FPI_FPIS_Tests.t.sol",
    "CrossChainCanonical-Tests.js": "ERC20/__CROSSCHAIN/CrossChainCanonical_Tests.t.sol",
    "veFXSYieldDistributorV4-Tests.js": "Staking/veFXSYieldDistributorV4_Test.t.sol",
    "FraxGaugeFXSRewardsDistributor-Tests.js": "Staking/FraxGaugeFXSRewardsDistributor_Test.t.sol",
}


def foundry_exists(rel_hint: str) -> bool:
    return (SPEC_ROOT / rel_hint).exists()


def status_for(entry: dict) -> str:
    path = entry["path"]
    if path in PATH_STATUS:
        return PATH_STATUS[path]

    cat = entry.get("category", "")
    if cat == "fixture":
        return "fixture"
    if cat == "old_tests":
        return "deferred"
    if cat == "fork":
        return "not-started"

    bucket = entry.get("bucket")
    if bucket and bucket in BUCKET_STATUS:
        base = BUCKET_STATUS[bucket]
        if base == "complete":
            return "complete"
        bucket_dir = SPEC_ROOT / bucket
        if bucket_dir.exists() and any(bucket_dir.rglob("*.t.sol")):
            return "partial" if base == "not-started" else base
        return base

    if path in SPEC_FILE_HINTS and foundry_exists(SPEC_FILE_HINTS[path]):
        return "complete"

    name = Path(path).stem.lower()
    for t in SPEC_ROOT.rglob("*.t.sol"):
        if name.replace("-", "").replace("_", "") in t.stem.lower().replace("_", ""):
            return "partial"

    if cat == "spec":
        return "not-started"
    return "not-started"


def main() -> None:
    inv = json.loads(INVENTORY.read_text())
    entries = []
    counts: dict[str, int] = {}

    for e in inv["entries"]:
        st = status_for(e)
        counts[st] = counts.get(st, 0) + 1
        entries.append(
            {
                "path": e["path"],
                "category": e.get("category"),
                "bucket": e.get("bucket"),
                "chain": e.get("chain"),
                "target": e.get("target"),
                "portStatus": st,
                "foundryHint": SPEC_FILE_HINTS.get(e["path"]),
            }
        )

    out = {
        "updated": "2026-06-04",
        "summary": {
            "total": len(entries),
            "byStatus": counts,
            "specTestsPassing": "run: forge test --match-path test/foundry/spec/protocols/tokens/stable/frax/**",
        },
        "bucketsClosed": ["BAMM", "Fraxbonds"],
        "stakingPartial": [
            "veFXSYieldDistributorV4-Tests.js",
            "FraxGaugeFXSRewardsDistributor-Tests.js"
        ],
        "nextRecommended": [
            "Staking/gauges (veFXS, FraxGaugeController, UnifiedFarm) — partial",
            "Top-level spec: CPITrackerOracle, ComboOracle, FPIControllerPool",
            "Phase 7.1 document partial/fork-only gaps (Fraxoracle proofs, FerryV2 L1→L2)",
        ],
        "entries": entries,
    }

    out_path = Path(__file__).parent / "coverage-matrix.json"
    out_path.write_text(json.dumps(out, indent=2) + "\n")
    print(f"Wrote {out_path} ({len(entries)} entries)")
    print(json.dumps(counts, indent=2))


if __name__ == "__main__":
    main()