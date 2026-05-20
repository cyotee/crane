#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
forge test --match-path 'test/foundry/spec/protocols/tokens/stable/frax/**' "$@"