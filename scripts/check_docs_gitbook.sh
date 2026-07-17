#!/usr/bin/env bash
# Verify GitBook publish readiness for Crane docs/.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0

if [[ ! -f .gitbook.yaml ]]; then
  echo "FAIL: missing .gitbook.yaml"
  fail=1
else
  if ! grep -q 'root: ./docs/' .gitbook.yaml; then
    echo "FAIL: .gitbook.yaml root is not ./docs/"
    fail=1
  else
    echo "OK: .gitbook.yaml root ./docs/"
  fi
  if ! grep -q 'summary: SUMMARY.md' .gitbook.yaml; then
    echo "FAIL: .gitbook.yaml missing summary: SUMMARY.md"
    fail=1
  fi
fi

if [[ ! -f docs/SUMMARY.md ]]; then
  echo "FAIL: missing docs/SUMMARY.md"
  exit 1
fi

paths_file="$(mktemp)"
grep -oE '\([^)#]+\.md' docs/SUMMARY.md | sed 's/^(//' | sort > "$paths_file"

if [[ ! -s "$paths_file" ]]; then
  echo "FAIL: no .md links in SUMMARY.md"
  rm -f "$paths_file"
  exit 1
fi

count="$(wc -l < "$paths_file" | tr -d ' ')"

dupes="$(uniq -c "$paths_file" | awk '$1 > 1 {print}')"
if [[ -n "$dupes" ]]; then
  echo "FAIL: duplicate SUMMARY paths:"
  echo "$dupes"
  fail=1
else
  echo "OK: every SUMMARY path appears exactly once ($count entries)"
fi

while IFS= read -r f; do
  if [[ ! -f "docs/$f" ]]; then
    echo "FAIL: missing docs/$f"
    fail=1
  fi
done < "$paths_file"
echo "OK: all SUMMARY targets exist under docs/"
rm -f "$paths_file"

for name in reports audits; do
  if [[ -e "docs/$name" ]]; then
    echo "FAIL: docs/$name should be under docs/archive/"
    fail=1
  else
    echo "OK: docs/$name not at publish root"
  fi
done

if ls docs 2>/dev/null | grep -q 'Balancer Hack'; then
  echo "FAIL: Balancer Hack scrapes still under docs/"
  fail=1
else
  echo "OK: no Balancer Hack scrapes at docs top-level"
fi

for f in \
  docs/getting-started.md \
  docs/deployment/create3.md \
  docs/concepts/registries.md \
  docs/concepts/dfpkg.md \
  docs/utilities/sets.md \
  docs/utilities/math-const-prod.md \
  docs/utilities/overview.md \
  docs/protocols/dexes.md \
  docs/protocols/lending.md \
  docs/development/testing.md \
  docs/funding/bankr-launch.md
do
  if [[ ! -f "$f" ]]; then
    echo "FAIL: required page missing: $f"
    fail=1
  fi
done
echo "OK: required LR-2 public pages present"

# Stale pre-archive path in public product docs (exclude archive + superpowers)
stale_file="$(mktemp)"
find docs -name '*.md' \
  ! -path 'docs/archive/*' \
  ! -path 'docs/superpowers/*' \
  -exec grep -Hn 'docs/reports/gap' {} + > "$stale_file" 2>/dev/null || true
if [[ -s "$stale_file" ]]; then
  echo "FAIL: public docs still reference archived path docs/reports/gap:"
  cat "$stale_file"
  fail=1
else
  echo "OK: no public docs reference stale docs/reports/gap"
fi
rm -f "$stale_file"

# Relative .md links must resolve (public product docs only)
link_out="$(mktemp)"
python3 - "$ROOT" <<'PY' > "$link_out"
import os, re, sys
root = sys.argv[1]
pat = re.compile(r"\]\(([^)]+)\)")
broken = []
for dirpath, dirnames, filenames in os.walk(os.path.join(root, "docs")):
    # prune archive and superpowers
    parts = os.path.relpath(dirpath, root).split(os.sep)
    if "archive" in parts or "superpowers" in parts:
        dirnames[:] = []
        continue
    for name in filenames:
        if not name.endswith(".md"):
            continue
        path = os.path.join(dirpath, name)
        try:
            text = open(path, encoding="utf-8", errors="replace").read()
        except OSError as e:
            broken.append(f"{path}: unreadable ({e})")
            continue
        for m in pat.finditer(text):
            target = m.group(1).strip()
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            # strip optional title
            if " " in target and (target.endswith('"') or '"' in target):
                target = target.split(" ")[0]
            path_part = target.split("#", 1)[0]
            if not path_part.endswith(".md"):
                continue
            if path_part.startswith("/"):
                resolved = os.path.normpath(root + path_part)
            else:
                resolved = os.path.normpath(os.path.join(dirpath, path_part))
            if not os.path.isfile(resolved):
                rel = os.path.relpath(path, root)
                broken.append(f"{rel} -> {target}")
if broken:
    print("FAIL: broken relative .md links in public docs:")
    for b in sorted(set(broken)):
        print(b)
    sys.exit(1)
print("OK: all relative .md links in public docs resolve")
sys.exit(0)
PY
link_rc=$?
cat "$link_out"
rm -f "$link_out"
if [[ "$link_rc" -ne 0 ]]; then
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "GitBook docs check FAILED"
  exit 1
fi
echo "GitBook docs check PASSED"
exit 0
