#!/bin/bash
# Locate forge artifact JSON for a contract name (basename match).
for ROOT in ./out_olympus_port ./out ./out_olympus; do
  [ -d "$ROOT" ] || continue
  while IFS= read -r -d '' FILE; do
    NAME=$(basename "$FILE")
    if [ "$NAME" = "$1" ]; then
      cast abi-encode "result(string)" "$FILE"
      exit 0
    fi
  done < <(find "$ROOT" -type f -name "$1" -print0 2>/dev/null)
done
# empty result if not found
exit 0
