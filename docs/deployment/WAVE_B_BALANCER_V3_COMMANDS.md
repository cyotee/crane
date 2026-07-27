# Wave B Balancer V3 — copy these commands

Open this file in your editor. Copy each block into your terminal.

Recovery details: `WAVE_B_BALANCER_V3_RECOVERY.md`  
Script is **resume-safe** (skips CREATE3 salts that already have code — fixes `TargetAlreadyExists`).

---

## COPY THIS — resume / full deploy (recommended)

```bash
cd /Users/cyotee/Development/projects-defi/daosys/lib/indexedex/lib/crane

export DEPLOYER=$(cast wallet address --account deployer)
echo "DEPLOYER=$DEPLOYER"

forge script scripts/foundry/Script_Promo_BC_BalancerV3.s.sol:Script_Promo_BC_BalancerV3 \
  --rpc-url battlechain-sepolia \
  --broadcast \
  --skip-simulation \
  --account deployer \
  --sender "$DEPLOYER" \
  -g 400 \
  -vvvv
```

**Must include:** `--sender`, `--skip-simulation`, `-g 400`

You should see logs like `reuse facet …` / `reuse package …` for already-deployed salts, and only **missing** pieces deploy.

---

## COPY THIS — if agreement salt already exists

```bash
cd /Users/cyotee/Development/projects-defi/daosys/lib/indexedex/lib/crane

export DEPLOYER=$(cast wallet address --account deployer)
echo "DEPLOYER=$DEPLOYER"

SKIP_AGREEMENT=1 forge script scripts/foundry/Script_Promo_BC_BalancerV3.s.sol:Script_Promo_BC_BalancerV3 \
  --rpc-url battlechain-sepolia \
  --broadcast \
  --skip-simulation \
  --account deployer \
  --sender "$DEPLOYER" \
  -g 400 \
  -vvvv
```

---

## COPY THIS — if still OOG on large facets

Same as first block, but `-g 500` or `-g 600`:

```bash
cd /Users/cyotee/Development/projects-defi/daosys/lib/indexedex/lib/crane

export DEPLOYER=$(cast wallet address --account deployer)
echo "DEPLOYER=$DEPLOYER"

forge script scripts/foundry/Script_Promo_BC_BalancerV3.s.sol:Script_Promo_BC_BalancerV3 \
  --rpc-url battlechain-sepolia \
  --broadcast \
  --skip-simulation \
  --account deployer \
  --sender "$DEPLOYER" \
  -g 500 \
  -vvvv
```

---

## COPY THIS — after success

```bash
cd /Users/cyotee/Development/projects-defi/daosys/lib/indexedex/lib/crane
cat docs/deployment/addresses/battlechain-sepolia-balancer-v3.json
cat docs/deployment/addresses/battlechain-sepolia-balancer-v3.table.md
```

Then tell the agent: **Wave B Balancer V3 deployed**
