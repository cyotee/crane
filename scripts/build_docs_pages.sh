#!/usr/bin/env bash
# Stage public docs (exclude archive/superpowers) and build mdBook for GitHub Pages.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

STAGE="${ROOT}/.mdbook-src"
OUT="${ROOT}/book"

rm -rf "$STAGE" "$OUT"
mkdir -p "$STAGE"

# Public product docs only — do not ship gap reports, scrapes, or internal plans
rsync -a \
  --exclude 'archive/' \
  --exclude 'superpowers/' \
  --exclude 'README.adoc' \
  --exclude '*.pdf' \
  docs/ "$STAGE/"

# book.toml uses src = ".mdbook-src"
mdbook build

echo "OK: mdBook output in ${OUT}"
du -sh "$OUT"
test -f "${OUT}/index.html"
test -f "${OUT}/getting-started.html"
# Guard: archive must not ship
if [[ -d "${OUT}/archive" ]]; then
  echo "FAIL: book/archive present — filter failed"
  exit 1
fi
echo "OK: archive not in book output"
