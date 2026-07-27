---
project: BattleChain greenfield — operator commands
version: 1.1
status: scripts-compile-target
created: 2026-07-23
last_updated: 2026-07-26
---

# BC greenfield — deploy commands (operator)

**Rule:** Scripts have **no interactive product options**. All salts/params are hardcoded.

**Do not live-broadcast until** master plan §0 / gap report GATE-5–6 is complete.

**Agent guide (what each phase deploys, local verify, manifests, pitfalls):**  
[`BC_GREENFIELD_SCRIPT_GUIDE.md`](./BC_GREENFIELD_SCRIPT_GUIDE.md)

This file is the **frozen one-liner list**. Prefer the script guide for intent and DoD.

---

## Shared setup

```bash
cd /Users/cyotee/Development/projects-defi/daosys/lib/indexedex/lib/crane

export DEPLOYER=$(cast wallet address --account deployer)
echo "DEPLOYER=$DEPLOYER"
```

Common flags:

```text
--rpc-url battlechain-sepolia --broadcast --skip-simulation --account deployer --sender "$DEPLOYER" -g 400
```

---

## Phase 0 — local only

```bash
forge test --match-contract Create3Factory_Test --match-test idempotent -vv
```

---

## Phase 1 — Factories

```bash
forge script scripts/foundry/bc/Script_BC_Phase1_Factories.s.sol:Script_BC_Phase1_Factories \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

## Phase 2 — Balancer V3

```bash
forge script scripts/foundry/bc/Script_BC_Phase2_BalancerV3.s.sol:Script_BC_Phase2_BalancerV3 \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

## FullStack (Phase 1 then 2)

```bash
forge script scripts/foundry/bc/Script_BC_FullStack.s.sol:Script_BC_FullStack \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

## Phase 3 — Aave

Path A: use Safe Singleton `0x914d…` if code exists.  
Path B: if empty, deploy Safe Singleton **runtime** via `IBattleChainDeployer.deployCreate2` (CreateX-compatible salt). **Do not use `vm.etch`.** See script guide § Phase 3.

```bash
# Optional: library-only precompile (prints FOUNDRY_LIBRARIES Crane path)
forge script scripts/foundry/bc/Script_BC_Phase3b_AaveV4_LibraryPreCompile.s.sol:Script_BC_Phase3b_AaveV4_LibraryPreCompile \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400

# Combined: V3 market (initReserves WETH/USDC/DAI) + V4 core + configure
forge script scripts/foundry/bc/Script_BC_Phase3_Aave.s.sol:Script_BC_Phase3_Aave \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400

# Optional: V4 core+configure only
forge script scripts/foundry/bc/Script_BC_Phase3b_AaveV4_Configure.s.sol:Script_BC_Phase3b_AaveV4_Configure \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

### Local verify (no live broadcast)

```bash
# createSelectFork of BC testnet — preferred Phase 3 smoke (6/6 Path B real factory)
forge test --match-path test/foundry/spec/scripts/bc/BC_Phase3_Aave_Fork.t.sol -vv
```

## Phase 4 — Euler (bind)

```bash
forge script scripts/foundry/bc/Script_BC_Phase4_Euler.s.sol:Script_BC_Phase4_Euler \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

## Phase 5 — Venus / Compound-style (bind)

```bash
forge script scripts/foundry/bc/Script_BC_Phase5_Compound.s.sol:Script_BC_Phase5_Compound \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

## Phase 6 — Aerodrome + Slipstream

```bash
forge script scripts/foundry/bc/Script_BC_Phase6_Aerodrome.s.sol:Script_BC_Phase6_Aerodrome \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

## Phase 7 — Uniswap extras

```bash
forge script scripts/foundry/bc/Script_BC_Phase7_Uniswap.s.sol:Script_BC_Phase7_Uniswap \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

## Phase 8 — Camelot

```bash
forge script scripts/foundry/bc/Script_BC_Phase8_Camelot.s.sol:Script_BC_Phase8_Camelot \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

## Phase 9 — Liquity / BOLD

**Local verify (required before live):**

```bash
# Always-on hermetic: real BcLiquityPhase9Deploy + openTrove
forge test --match-path test/foundry/spec/scripts/bc/BC_Phase9_Liquity_Hermetic.t.sol -vv

# Optional BC fork (when RPC reachable)
BC_FORK_RPC=https://testnet.battlechain.com \
  forge test --match-path test/foundry/spec/scripts/bc/BC_Phase9_Liquity_Fork.t.sol -vv
```

**Open-trove constraints:** `MIN_DEBT = 2000e18` BOLD; also `ETH_GAS_COMPENSATION = 0.0375e18` WETH to gas pool.

```bash
forge script scripts/foundry/bc/Script_BC_Phase9_Liquity.s.sol:Script_BC_Phase9_Liquity \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

## Phase 10 — Sky

```bash
forge script scripts/foundry/bc/Script_BC_Phase10_Sky.s.sol:Script_BC_Phase10_Sky \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

## Phase 11 — Resupply

**Dropped** (not ported). No command.

## Phase 12 — Reliquary

```bash
forge script scripts/foundry/bc/Script_BC_Phase12_Reliquary.s.sol:Script_BC_Phase12_Reliquary \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

## Phase 13a — Pendle

```bash
forge script scripts/foundry/bc/Script_BC_Phase13a_Pendle.s.sol:Script_BC_Phase13a_Pendle \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

## Phase 13b — Frax

```bash
forge script scripts/foundry/bc/Script_BC_Phase13b_Frax.s.sol:Script_BC_Phase13b_Frax \
  --rpc-url battlechain-sepolia --broadcast --skip-simulation \
  --account deployer --sender "$DEPLOYER" -g 400
```

---

## Compile check (implementation DoD)

```bash
forge build --contracts scripts/foundry/bc/
```
