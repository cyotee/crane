#!/usr/bin/env bash
# Wave B — Balancer V3 on BattleChain (resume-safe script)
# Copy the forge block from WAVE_B_BALANCER_V3_COMMANDS.md, or run this file.

set -euo pipefail

cd /Users/cyotee/Development/projects-defi/daosys/lib/indexedex/lib/crane

export DEPLOYER=$(cast wallet address --account deployer)
echo "DEPLOYER=$DEPLOYER"

if [[ -z "${DEPLOYER}" ]]; then
  echo "ERROR: DEPLOYER empty. Unlock cast account 'deployer' and retry."
  exit 1
fi

# Optional: SKIP_AGREEMENT=1 if Safe Harbor salt already adopted
forge script scripts/foundry/Script_Promo_BC_BalancerV3.s.sol:Script_Promo_BC_BalancerV3 \
  --rpc-url battlechain-sepolia \
  --broadcast \
  --skip-simulation \
  --account deployer \
  --sender "$DEPLOYER" \
  -g 400 \
  -vvvv

echo "Done. Check docs/deployment/addresses/battlechain-sepolia-balancer-v3.json"
