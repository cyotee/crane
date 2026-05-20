#!/usr/bin/env python3
"""Normalize all pragmas under frax port to ^0.8.35."""

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "contracts/protocols/tokens/stable/frax"
PRAGMA_LINE = re.compile(r"^\s*pragma\s+solidity[^;]*;", re.MULTILINE)
REPLACEMENTS = [
    ("@crane/contracts/external/openzeppelin-contracts/security/ReentrancyGuard.sol", "@crane/contracts/external/openzeppelin-contracts/utils/ReentrancyGuard.sol"),
]


def main() -> None:
    for path in ROOT.rglob("*.sol"):
        text = path.read_text(encoding="utf-8", errors="replace")
        orig = text
        text = PRAGMA_LINE.sub("pragma solidity ^0.8.35;", text)
        for old, new in REPLACEMENTS:
            text = text.replace(old, new)
        if text != orig:
            path.write_text(text, encoding="utf-8")
    print("pragma/import fixes applied under", ROOT)


if __name__ == "__main__":
    main()