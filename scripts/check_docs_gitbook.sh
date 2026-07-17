#!/usr/bin/env bash
# Verify GitBook publish readiness for Crane docs/ (SUMMARY uniqueness + path existence).
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

# Extract markdown link targets ending in .md (path only, no anchors)
paths_file="$(mktemp)"
grep -oE '\([^)#]+\.md' docs/SUMMARY.md | sed 's/^(//' | sort > "$paths_file"

if [[ ! -s "$paths_file" ]]; then
  echo "FAIL: no .md links in SUMMARY.md"
  rm -f "$paths_file"
  exit 1
fi

count="$(wc -l < "$paths_file" | tr -d ' ')"

# Uniqueness
dupes="$(uniq -c "$paths_file" | awk '$1 > 1 {print}')"
if [[ -n "$dupes" ]]; then
  echo "FAIL: duplicate SUMMARY paths:"
  echo "$dupes"
  fail=1
else
  echo "OK: every SUMMARY path appears exactly once ($count entries)"
fi

# Existence
while IFS= read -r f; do
  if [[ ! -f "docs/$f" ]]; then
    echo "FAIL: missing docs/$f"
    fail=1
  fi
done < "$paths_file"
echo "OK: all SUMMARY targets exist under docs/"
rm -f "$paths_file"

# Bulk pollution at docs top-level
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

# Required public pages for LR-2
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

if [[ "$fail" -ne 0 ]]; then
  echo "GitBook docs check FAILED"
  exit 1
fi
echo "GitBook docs check PASSED"
exit 0
