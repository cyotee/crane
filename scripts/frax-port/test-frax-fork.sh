#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
# Optional: FRAX_HEAVY_FORK=1 for long FPI/TWAMM fork cases.
forge test --match-path 'test/foundry/fork/ethereum/protocols/tokens/stable/frax/**' --jobs 1 "$@"