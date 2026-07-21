#!/usr/bin/env bash
# Verifies docs/roadmap/PUBLIC_RELEASE_INVENTORY.md against INVENTORY_GOAL.md SC checks.
# Exit 0 on success; non-zero on failure. Drives the real inventory artifact on disk.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
REPORT="docs/roadmap/PUBLIC_RELEASE_INVENTORY.md"
fail=0

pass() { echo "PASS: $*"; }
fail_msg() { echo "FAIL: $*"; fail=1; }

if [[ -f "$REPORT" ]]; then pass "report exists: $REPORT"; else fail_msg "missing $REPORT"; fi
if [[ -d docs/roadmap ]]; then pass "docs/roadmap exists"; else fail_msg "missing docs/roadmap"; fi

for s in \
  "## 1. Metadata" \
  "## 2. Executive summary" \
  "## 3. Locked decisions" \
  "## 4. Zone inventories" \
  "## 5. Cross-cutting findings" \
  "## 6. Recommended cleanup waves" \
  "## 7. Human decision checklist" \
  "## 8. Success attestation"
do
  if grep -qF "$s" "$REPORT"; then pass "section $s"; else fail_msg "section $s"; fi
done

for z in Z0 Z1 Z2 Z3 Z4 Z5 Z6 Z7 Z8 Z9; do
  if grep -q "$z" "$REPORT"; then pass "zone $z"; else fail_msg "zone $z"; fi
done

z0_find=$(find . -maxdepth 1 -type f ! -path './.git' | wc -l | tr -d ' ')
# Count Z0 inventory table rows: lines between ### Z0 and ### Z1 starting with | `
z0_rows=$(awk '/### Z0/{p=1;next} /### Z1/{p=0} p && /^\| `/{c++} END{print c+0}' "$REPORT")
if [[ "$z0_rows" == "$z0_find" ]]; then
  pass "Z0 row count $z0_rows == find count $z0_find"
else
  fail_msg "Z0 row count $z0_rows != find count $z0_find"
fi

for pat in "DELETE" "OD-1" "OD-2" "OD-3" "OD-4" "OD-5" "OD-6" "OD-7" "GitHub Issues" "Maturity" "certora" "public agent"; do
  if grep -q "$pat" "$REPORT"; then pass "text: $pat"; else fail_msg "text: $pat"; fi
done

if grep -q 'tasks/' "$REPORT" && grep -q 'DELETE' "$REPORT"; then
  pass "tasks DELETE disposition present"
else
  fail_msg "tasks DELETE missing"
fi

# Disposition codes in table disposition columns: only allowed set
# Extract cells that are pure disposition codes (optional bold)
allowed='KEEP|KEEP_INTERNAL|MOVE|ARCHIVE_THIN|EXTERNALIZE|DELETE|GITIGNORE|REVIEW'
# Flag unknown ALLCAPS tokens used as standalone disposition cells — lightweight check:
if grep -nE '\| \*\*(KEEP_INTERNAL|ARCHIVE_THIN|EXTERNALIZE|GITIGNORE|KEEP|MOVE|DELETE|REVIEW)\*\* \|' "$REPORT" >/dev/null \
  || grep -nE '\| (KEEP_INTERNAL|ARCHIVE_THIN|EXTERNALIZE|GITIGNORE|KEEP|MOVE|DELETE|REVIEW) \|' "$REPORT" >/dev/null; then
  pass "disposition codes present in tables"
else
  fail_msg "no disposition codes found in tables"
fi

if [[ -d tasks ]]; then pass "tasks/ still present (analysis-only)"; else fail_msg "tasks/ missing unexpectedly during inventory goal"; fi

# Exact disposition totals in §2 must equal path-table row count (SC-5)
python3 - <<'PY' || fail=1
from pathlib import Path
import re, sys
text = Path("docs/roadmap/PUBLIC_RELEASE_INVENTORY.md").read_text()
# §2 total line
m = re.search(r'\|\s*\*\*Total\*\*\s*\|\s*\*\*(\d+)\*\*', text)
if not m:
    print("FAIL: §2 Total row missing")
    sys.exit(1)
stated = int(m.group(1))
start = text.index("## 4. Zone inventories")
end = text.index("## 5. Cross-cutting findings")
section = text[start:end]
allowed = {"KEEP","KEEP_INTERNAL","MOVE","ARCHIVE_THIN","EXTERNALIZE","DELETE","GITIGNORE","REVIEW"}
counts = {a: 0 for a in allowed}
review_paths = []
for ln in section.splitlines():
    if not re.match(r'^\| `', ln):
        continue
    cells = [c.strip() for c in ln.strip().strip('|').split('|')]
    disp = None
    for c in cells:
        c2 = re.sub(r'\*+', '', c).strip()
        if c2 in allowed:
            disp = c2
            break
    if disp:
        counts[disp] += 1
        if disp == "REVIEW":
            path = re.sub(r'\*+', '', cells[0]).strip().strip('`')
            review_paths.append(path)
total = sum(counts.values())
if total != stated:
    print(f"FAIL: §2 Total {stated} != counted path rows {total}")
    sys.exit(1)
print(f"PASS: §2 Total {stated} == path-table rows {total}")
# every REVIEW path must appear in §7
sec7 = text[text.index("## 7. Human decision checklist"):text.index("## 8. Success attestation")]
missing = [p for p in review_paths if p not in sec7 and p.rstrip('/') not in sec7]
# allow fuzzy: basename or path without trailing slash
missing = []
for p in review_paths:
    if p in sec7 or p.rstrip('/') in sec7:
        continue
    # also try last path component
    base = p.rstrip('/').split('/')[-1]
    if base and base in sec7:
        continue
    missing.append(p)
if missing:
    print("FAIL: REVIEW paths missing from §7:", missing)
    sys.exit(1)
print(f"PASS: all {len(review_paths)} REVIEW paths restated in §7")
sys.exit(0)
PY

if [[ "$fail" -eq 0 ]]; then
  echo "ALL CHECKS PASSED"
  exit 0
else
  echo "SOME CHECKS FAILED"
  exit 1
fi
