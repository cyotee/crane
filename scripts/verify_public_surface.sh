#!/usr/bin/env bash
# Structural checks for public packaging surface (docs, skills, solc alignment).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

check_file() {
  if [[ ! -f "$ROOT/$1" ]]; then
    echo "MISSING: $1"
    fail=1
  else
    echo "OK file: $1"
  fi
}

check_file "docs/protocols/status.md"
check_file "docs/reference/CENTRALLY_COMPUTED_NATSPEC_VALUES.md"
check_file "SECURITY.md"
check_file "CONTRIBUTING.md"
check_file "NOTICE.md"
check_file "CHANGELOG.md"

# solc alignment: foundry.toml pin must appear in AGENTS.md
solc=$(grep -E '^\s*solc\s*=' "$ROOT/foundry.toml" | head -1 | sed 's/.*"\([0-9.]*\)".*/\1/')
if grep -q "$solc" "$ROOT/AGENTS.md"; then
  echo "OK solc $solc in AGENTS.md"
else
  echo "FAIL solc $solc not referenced in AGENTS.md"
  fail=1
fi

if grep -q 'tasks/' "$ROOT/AGENTS.md" && grep -q 'Task management' "$ROOT/AGENTS.md"; then
  echo "FAIL AGENTS.md still documents tasks/ workflow"
  fail=1
else
  echo "OK no active tasks/ workflow in AGENTS.md"
fi

SKILLS="$ROOT/.claude/skills"
for bad in yoink megapot cattown aeon-token-pick bankr agenticbets; do
  if [[ -e "$SKILLS/$bad" ]]; then
    echo "FAIL bazaar skill still present: $bad"
    fail=1
  fi
done
echo "OK sample bazaar skills absent"

for good in crane-architecture crane-testing tevm-overview forge-testing aave-v3-architecture; do
  if [[ ! -d "$SKILLS/$good" ]]; then
    echo "FAIL product/borderline skill missing: $good"
    fail=1
  else
    echo "OK skill: $good"
  fi
done

if grep -q 'protocols/status.md' "$ROOT/docs/SUMMARY.md"; then
  echo "OK SUMMARY links maturity status"
else
  echo "FAIL SUMMARY missing protocols/status.md"
  fail=1
fi

# @ozu remapping: foundry.toml + remappings.txt must agree and not use the broken typo path
if grep -q 'openzeppelin-contracts-upgradable' "$ROOT/foundry.toml" "$ROOT/remappings.txt" 2>/dev/null; then
  echo "FAIL broken @ozu path (upgradable typo) still present"
  fail=1
else
  echo "OK no broken @ozu typo path"
fi
if grep -q '@ozu/=contracts/external/openzeppelin-upgradeable/' "$ROOT/foundry.toml" \
  && grep -q '@ozu/=contracts/external/openzeppelin-upgradeable/' "$ROOT/remappings.txt"; then
  echo "OK @ozu mapping in foundry.toml and remappings.txt"
else
  echo "FAIL @ozu good path missing from foundry.toml or remappings.txt"
  fail=1
fi
if command -v forge >/dev/null 2>&1; then
  ozu_lines=$(forge remappings 2>/dev/null | grep -i ozu || true)
  if echo "$ozu_lines" | grep -q 'openzeppelin-contracts-upgradable'; then
    echo "FAIL forge remappings still emits broken @ozu path"
    fail=1
  elif echo "$ozu_lines" | grep -q 'openzeppelin-upgradeable'; then
    echo "OK forge remappings: $ozu_lines"
  else
    echo "FAIL forge remappings missing @ozu: [$ozu_lines]"
    fail=1
  fi
fi

if [[ $fail -ne 0 ]]; then
  echo "verify_public_surface: FAILED"
  exit 1
fi
echo "verify_public_surface: PASSED"
