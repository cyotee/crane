#!/usr/bin/env python3
"""Mechanical Frax source port: copy + pragma/import rewrite."""

from __future__ import annotations

import re
import shutil
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SRC_ROOT = REPO / "lib/frax-solidity/src/hardhat/contracts"
OLD_BAMM = REPO / "lib/frax-solidity/src/hardhat/old_contracts/BAMM"
DST_ROOT = REPO / "contracts/protocols/tokens/stable/frax"
FRAX_PREFIX = "@crane/contracts/protocols/tokens/stable/frax/"

IMPORT_RULES: list[tuple[str, str]] = [
    ("@openzeppelin/contracts/", "@crane/contracts/external/openzeppelin-contracts/"),
    ("openzeppelin-contracts/", "@crane/contracts/external/openzeppelin-contracts/"),
    ("@chainlink/contracts/", "@crane/contracts/external/chainlink/contracts/"),
    ("@uniswap/v2-core/contracts/", "@crane/contracts/external/uniswap/v2-core/contracts/"),
    ("@uniswap/v2-periphery/contracts/", "@crane/contracts/external/uniswap/v2-periphery/contracts/"),
    ("@uniswap/v3-core/contracts/", "@crane/contracts/external/uniswap/v3-core/contracts/"),
    ("@uniswap/v3-periphery/contracts/", "@crane/contracts/external/uniswap/v3-periphery/contracts/"),
    (
        "@arbitrum/nitro-contracts/src/",
        "@crane/contracts/external/arbitrum/nitro-contracts/src/",
    ),
    ("frax-std/", "@crane/contracts/external/frax-std/"),
    ('import "hardhat/console.sol"', 'import "forge-std/console.sol"'),
    ("import 'hardhat/console.sol'", "import 'forge-std/console.sol'"),
]

PRAGMA_PATTERNS = [
    (re.compile(r"pragma\s+solidity\s+0\.5\.\d+;"), "pragma solidity ^0.8.35;"),
    (re.compile(r"pragma\s+solidity\s+0\.6\.\d+;"), "pragma solidity ^0.8.35;"),
    (re.compile(r"pragma\s+solidity\s+0\.7\.\d+;"), "pragma solidity ^0.8.35;"),
    (re.compile(r"pragma\s+solidity\s+\^0\.6\.\d+;"), "pragma solidity ^0.8.35;"),
    (re.compile(r"pragma\s+solidity\s+>=0\.6\.\d+;"), "pragma solidity ^0.8.35;"),
    (re.compile(r"pragma\s+solidity\s+>=0\.7\.\d+;"), "pragma solidity ^0.8.35;"),
    (re.compile(r"pragma\s+solidity\s+0\.8\.\d+;"), "pragma solidity ^0.8.35;"),
    (re.compile(r"pragma\s+solidity\s+\^0\.8\.\d+;"), "pragma solidity ^0.8.35;"),
]

REMOVE_PRAGMAS = [
    "pragma abicoder v2;",
    "pragma experimental ABIEncoderV2;",
]


def rewrite_relative_imports(text: str, rel_path: Path) -> str:
    """Rewrite ../ and ./ imports crossing subdirs to absolute @crane paths."""

    def repl(match: re.Match[str]) -> str:
        quote = match.group(1)
        imp = match.group(2)
        if imp.startswith("@") or imp.startswith("forge-std"):
            return match.group(0)
        if imp.startswith("./"):
            return match.group(0)
        if imp.startswith("../"):
            base = (rel_path.parent / imp).resolve()
            try:
                rel_to_frax = base.relative_to(SRC_ROOT.resolve())
            except ValueError:
                return match.group(0)
            target = FRAX_PREFIX + rel_to_frax.as_posix()
            return f'import {quote}{target}{quote}'
        return match.group(0)

    return re.sub(
        r'import\s+(\'|")(\.\.?/[^\'"]+)(\'|")',
        repl,
        text,
    )


def transform(content: str, rel_path: Path) -> str:
    for old, new in PRAGMA_PATTERNS:
        content = old.sub(new, content)
    for line in REMOVE_PRAGMAS:
        content = content.replace(line + "\n", "")
        content = content.replace(line, "")
    for old, new in IMPORT_RULES:
        content = content.replace(old, new)
    content = rewrite_relative_imports(content, rel_path)
    return content


def port_tree(src: Path, dst: Path) -> int:
    count = 0
    for path in sorted(src.rglob("*.sol")):
        rel = path.relative_to(src)
        out = dst / rel
        out.parent.mkdir(parents=True, exist_ok=True)
        text = path.read_text(encoding="utf-8", errors="replace")
        out.write_text(transform(text, rel), encoding="utf-8")
        count += 1
    return count


def main() -> None:
    n = port_tree(SRC_ROOT, DST_ROOT)
    print(f"Ported {n} files from {SRC_ROOT} -> {DST_ROOT}")
    if OLD_BAMM.is_dir():
        bamm_dst = DST_ROOT / "BAMM"
        m = port_tree(OLD_BAMM, bamm_dst)
        print(f"Ported {m} BAMM files from old_contracts")


if __name__ == "__main__":
    main()