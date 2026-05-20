#!/usr/bin/env python3
"""Remove SafeMath using/import lines; basic .add/.sub/.mul/.div -> native ops."""

import re
from pathlib import Path

ROOTS = [
    Path(__file__).resolve().parents[2] / "contracts/external/uniswap",
    Path(__file__).resolve().parents[2] / "contracts/protocols/tokens/stable/frax",
]

USING_SAFE = re.compile(r"^\s*using\s+SafeMath\s+for\s+[^;]+;\s*\n", re.MULTILINE)
IMPORT_SAFE = re.compile(
    r'^\s*import\s+[^;]*SafeMath[^;]*;\s*\n',
    re.MULTILINE,
)
METHOD_OPS = [
    (re.compile(r"\.add\("), "("),  # wrong - need .add(x) -> + 
]

# Simple token replacers for uint256 style
REPLS = [
    (re.compile(r"(\w+)\.add\(([^)]+)\)"), r"(\1 + \2)"),
    (re.compile(r"(\w+)\.sub\(([^)]+)\)"), r"(\1 - \2)"),
    (re.compile(r"(\w+)\.mul\(([^)]+)\)"), r"(\1 * \2)"),
    (re.compile(r"(\w+)\.div\(([^)]+)\)"), r"(\1 / \2)"),
    (re.compile(r"(\w+)\.mod\(([^)]+)\)"), r"(\1 % \2)"),
]
NOW = re.compile(r"\bnow\b")


def process(text: str) -> str:
    text = USING_SAFE.sub("", text)
    text = IMPORT_SAFE.sub("", text)
    for pat, repl in REPLS:
        text = pat.sub(repl, text)
    text = NOW.sub("block.timestamp", text)
    return text


def main() -> None:
    changed = 0
    for root in ROOTS:
        if not root.exists():
            continue
        for path in root.rglob("*.sol"):
            orig = path.read_text(encoding="utf-8", errors="replace")
            new = process(orig)
            if new != orig:
                path.write_text(new, encoding="utf-8")
                changed += 1
    print(f"modernize_safemath: updated {changed} files")


if __name__ == "__main__":
    main()