#!/usr/bin/env python3
"""Rewrite cross-subdir relative imports and bare contracts/ paths in frax port."""

import re
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
FRAX = REPO / "contracts/protocols/tokens/stable/frax"
PREFIX = "@crane/contracts/protocols/tokens/stable/frax/"

IMPORT_RULES = [
    ("@openzeppelin/contracts/", "@crane/contracts/external/openzeppelin-contracts/"),
    ('"contracts/external/', '"@crane/contracts/external/'),
    ("'contracts/external/", "'@crane/contracts/external/"),
    ("@uniswap/lib/contracts/", "@crane/contracts/external/uniswap/lib/contracts/"),
]


def resolve_relative(file_path: Path, imp: str) -> str | None:
    if imp.startswith("./"):
        return None
    if not imp.startswith("../"):
        return None
    base = (file_path.parent / imp).resolve()
    try:
        rel = base.relative_to(FRAX.resolve())
    except ValueError:
        return None
    return PREFIX + rel.as_posix()


def process_file(path: Path) -> bool:
    text = path.read_text(encoding="utf-8", errors="replace")
    orig = text
    for old, new in IMPORT_RULES:
        text = text.replace(old, new)

    def repl(m: re.Match[str]) -> str:
        quote = m.group(1)
        imp = m.group(2)
        if imp.startswith("@") or imp.startswith("forge-std"):
            return m.group(0)
        if imp.startswith("./"):
            return m.group(0)
        abs_path = resolve_relative(path, imp)
        if abs_path:
            return f"import {quote}{abs_path}{quote}"
        return m.group(0)

    text = re.sub(
        r'import\s+(\'|")(\.\./[^\'"]+)(\'|")',
        repl,
        text,
    )
    if text != orig:
        path.write_text(text, encoding="utf-8")
        return True
    return False


def main() -> None:
    n = sum(process_file(p) for p in FRAX.rglob("*.sol"))
    print(f"fix_frax_imports: updated {n} files")


if __name__ == "__main__":
    main()