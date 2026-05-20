#!/usr/bin/env python3
"""Patch vendored Uniswap libs for Solidity 0.8.x type rules."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
UNISWAP = ROOT / "contracts" / "external" / "uniswap"

# uint128(-1) -> type(uint128).max (all common widths)
NEG_ONE = re.compile(
    r"\buint(8|16|32|64|128|144|224|256)\(-1\)"
)


def patch_neg_one(text: str) -> str:
    def repl(m: re.Match[str]) -> str:
        w = m.group(1)
        return f"type(uint{w}).max"

    return NEG_ONE.sub(repl, text)


def patch_file(path: Path) -> bool:
    original = path.read_text()
    text = patch_neg_one(original)

    rel = path.as_posix()
    if "TickBitmap.sol" in rel:
        text = text.replace(
            "bitPos = uint8(tick % 256);",
            "bitPos = uint8(uint256(int256(tick % 256)));",
        )
        text = text.replace(
            "(compressed - int24(bitPos - BitMath.mostSignificantBit(masked))) * tickSpacing",
            "(compressed - int24(int256(uint256(bitPos) - BitMath.mostSignificantBit(masked)))) * tickSpacing",
        )
        text = text.replace(
            "(compressed - int24(bitPos)) * tickSpacing",
            "(compressed - int24(int256(uint256(bitPos)))) * tickSpacing",
        )
        text = text.replace(
            "(compressed + 1 + int24(BitMath.leastSignificantBit(masked) - bitPos)) * tickSpacing",
            "(compressed + 1 + int24(int256(uint256(BitMath.leastSignificantBit(masked)) - uint256(bitPos)))) * tickSpacing",
        )
        text = text.replace(
            "(compressed + 1 + int24(type(uint8).max - bitPos)) * tickSpacing",
            "(compressed + 1 + int24(int256(uint256(type(uint8).max) - uint256(bitPos)))) * tickSpacing",
        )

    if "Oracle.sol" in rel and "v3-core" in rel:
        text = text.replace(
            "tickCumulative: last.tickCumulative + int56(tick) * delta,",
            "tickCumulative: last.tickCumulative + int56(tick) * int56(uint256(delta)),",
        )
        old = """                beforeOrAt.tickCumulative +
                    ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / observationTimeDelta) *
                    targetDelta,"""
        new = """                beforeOrAt.tickCumulative +
                    int56(
                        (int256(atOrAfter.tickCumulative - beforeOrAt.tickCumulative) /
                            int256(uint256(observationTimeDelta))) * int256(uint256(targetDelta))
                    ),"""
        text = text.replace(old, new)

    if "FullMath.sol" in rel and "v3-core" in rel:
        text = text.replace(
            "uint256 twos = -denominator & denominator;",
            "uint256 twos = denominator & (~denominator + 1);",
        )

    if "FullMath.sol" in rel and "/lib/" in rel:
        text = text.replace("mulmod(x, y, uint256(-1))", "mulmod(x, y, type(uint256).max)")
        text = text.replace("uint256 pow2 = d & -d;", "uint256 pow2 = d & (~d + 1);")
        text = text.replace(
            "l += h * ((-pow2) / pow2 + 1);",
            "l += h * ((~pow2 + 1) / pow2 + 1);",
        )

    if "UniswapV2Library.sol" in rel:
        text = text.replace(
            "pair = address(uint(keccak256(abi.encodePacked(",
            "pair = address(uint160(uint256(keccak256(abi.encodePacked(",
        )

    if "AddressStringUtil.sol" in rel:
        text = text.replace(
            "uint256 addrNum = uint256(addr);",
            "uint256 addrNum = uint256(uint160(addr));",
        )

    if text != original:
        path.write_text(text)
        return True
    return False


def main() -> None:
    changed = 0
    for path in UNISWAP.rglob("*.sol"):
        if patch_file(path):
            changed += 1
            print(path.relative_to(ROOT))
    print(f"Patched {changed} files")


if __name__ == "__main__":
    main()