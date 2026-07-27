---
project: BattleChain Aave V4 deploy steps
version: 1.0
status: active
created: 2026-07-23
last_updated: 2026-07-23
related:
  - docs/deployment/BC_GREENFIELD_DEPLOYMENT_PRD.md
  - docs/deployment/BC_GREENFIELD_DEPLOY_RESEARCH.md
  - contracts/protocols/lending/aave/v4/deployments/README.md
  - docs/protocols/lending/aave/v4/VENDOR_PROVENANCE.md
---

# Aave V4 on BattleChain — complete deploy steps

Authoritative procedure for Phase **3b** (and the V4 portion of Phase 3).  
All product options are **hardcoded in Foundry scripts** — the operator only runs fixed commands.

**Code is present** in Crane. This doc records *how* to deploy it on BC testnet (chain `627`).

---

## 0. What “deploy complete” means for BC greenfield

| Layer | Required? | Notes |
|-------|-----------|--------|
| **Core stack** | Yes | AccessManager, configurators, TreasurySpoke, ≥1 Hub, ≥1 Spoke + AaveOracle, roles |
| **Gateways** | Yes (default) | NativeTokenGateway + SignatureGateway |
| **Position managers** | Yes (default) | Giver / Taker / Config |
| **At least one listed market** | Yes | Hub asset + spoke reserve for BC WETH (and preferably USDC/DAI) with BC Chainlink feeds |
| **TokenizationSpoke** | Optional | Only after asset listed; one per asset if needed |
| **BC-provided deps** | Bind only | WETH, USDC, DAI, Chainlink mocks — never redeploy |

---

## 1. Prerequisites (blocking)

### 1.1 Safe Singleton Factory (CREATE2)

Aave V4 orchestration deploys **only** via:

`Create2Utils.CREATE2_FACTORY = 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7`  
(Safe Singleton Factory — [safe-global/safe-singleton-factory](https://github.com/safe-global/safe-singleton-factory))

**Check on BC testnet (as of research 2026-07-23):**

```bash
cast code 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7 --rpc-url https://testnet.battlechain.com
# Observed: empty (0x) — factory NOT present
```

BattleChain **does** have CreateX (`BC_TESTNET.CREATEX`) and BattleChainDeployer — but **stock Aave V4 code does not use them**.

| Path | Action |
|------|--------|
| **A (preferred if possible)** | Get Safe Singleton Factory live at the canonical address on BC (same as other EVM chains). Re-check with `cast code` until non-empty. |
| **B (Crane adapter)** | If BC cannot host that address: implement a **BC-only** deploy path that uses CreateX / `bcDeployCreate2` while preserving batch order and reports. Prefer a thin wrapper over forking all of `Create2Utils` callers. **Must be fixed in script/code before broadcast** — not an operator choice. |

**Gate:** Do not run orchestration until either factory has code at `0x914d…` or Path B is implemented and tested hermetically.

### 1.2 Phase 1 Crane factory (greenfield)

- Phase 1 Create3Factory live (for manifests / lineage under Safe Harbor).  
- Aave V4 core uses Safe CREATE2, not Crane CREATE3, unless Path B remaps it.  
- Still bind under the Phase 1 Safe Harbor root in docs (agreement covers factory children; external CREATE2 roots may need explicit agreement scope if not under Create3Factory — **ops note:** if Aave contracts are deployed outside Create3Factory lineage, either (1) use Path B under Create3Factory, or (2) extend Safe Harbor scope to list Aave roots. Prefer Path B under Crane CREATE3 or document multi-root agreement.)

**Recommendation for greenfield consistency:** Path B under Phase 1 Create3Factory so all Aave V4 addresses inherit `ChildContractScope.All` from Phase 1 agreement. If keeping upstream CREATE2, add Aave top-level contracts to agreement scope in Phase 3 script (still fixed in code).

### 1.3 Bind addresses (never deploy)

| Role | Source |
|------|--------|
| `nativeWrapper` | BC WETH `0x4CAc28Fc96bb8fa0e6F94ef0E579384902142f42` |
| Oracle sources | BC Chainlink mocks (ETH/USD, USDC/USD, …) |
| Reserve underlyings | BC USDC, DAI, WBTC, WETH as listed |

### 1.4 Deployer

- Foundry account `deployer` funded on BC.  
- Scripts use `--sender $DEPLOYER` with all admins hardcoded to that address (or fixed multisig later — still in script, not CLI).

---

## 2. Hardcoded `FullDeployInputs` (BC greenfield defaults)

Freeze these in `Script_BC_Phase3_Aave` / V4 module (override `_getDeployInputs()`). **Operator cannot change them at run time.**

| Field | BC greenfield default |
|-------|------------------------|
| `accessManagerAdmin` | deployer |
| `proxyAdminOwner` | deployer |
| `hubAdmin` | deployer |
| `hubConfiguratorAdmin` | deployer |
| `treasurySpokeOwner` | deployer |
| `spokeAdmin` | deployer |
| `spokeConfiguratorAdmin` | deployer |
| `gatewayOwner` | deployer |
| `positionManagerOwner` | deployer |
| `nativeWrapper` | BC WETH |
| `deployNativeTokenGateway` | `true` |
| `deploySignatureGateway` | `true` |
| `deployPositionManagers` | `true` |
| `grantRoles` | `true` |
| `hubLabels` | `["core"]` (single hub) |
| `spokeLabels` | `["bc"]` (single spoke) |
| `spokeMaxReservesLimits` | `[16]` or empty (orchestration default if empty — set explicitly e.g. `16`) |
| `salt` | `keccak256("crane-bc-aave-v4-v1")` (fixed string) |

Reference shape: `AaveV4DeployAnvil.s.sol` + `InputUtils.FullDeployInputs`.

Chain id check: `_expectedChainId() = 627`.

---

## 3. Step-by-step deploy procedure

### Step A — Ensure CREATE2 factory (or Path B)

```bash
cast code 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7 --rpc-url https://testnet.battlechain.com
```

- Non-empty → continue with upstream Create2Utils.  
- Empty → implement/complete Path B before any Aave V4 broadcast.

### Step B — Pre-deploy LiquidationLogic (library link)

SpokeInstance links **external** `LiquidationLogic`. Foundry must recompile with the library address.

**In-tree script:**  
`test/foundry/spec/protocols/lending/aave/v4/scripts/LibraryPreCompile.s.sol`  
(uses `SpokeDeployUtils` + CREATE2 salt `bytes32(0)`).

**BC script package should include** a non-interactive twin, e.g.  
`scripts/foundry/bc/Script_BC_Phase3b_AaveV4_LibraryPreCompile.s.sol`, that:

1. Requires CREATE2 factory (or Path B) present.  
2. Deploys `LiquidationLogic` if not already at predicted address.  
3. Writes library link for **Crane path** (not upstream `src/…`):

```text
FOUNDRY_LIBRARIES=contracts/protocols/lending/aave/v4/spoke/libraries/LiquidationLogic.sol:LiquidationLogic:0x<addr>
```

**Note:** Vendored `SpokeDeployUtils.getLibraryString` still emits `src/spoke/libraries/...` — **fix for Crane remapping** in the BC script (hardcoded correct path).

**Operator commands (once scripts exist):**

```bash
cd /Users/cyotee/Development/projects-defi/daosys/lib/indexedex/lib/crane
export DEPLOYER=$(cast wallet address --account deployer)

# B1 — library
forge script scripts/foundry/bc/Script_BC_Phase3b_AaveV4_LibraryPreCompile.s.sol:Script_BC_Phase3b_AaveV4_LibraryPreCompile \
  --rpc-url battlechain-sepolia \
  --broadcast \
  --skip-simulation \
  --account deployer \
  --sender "$DEPLOYER" \
  -g 400 \
  --ffi

# B2 — force recompile with FOUNDRY_LIBRARIES (set in env or .env by script)
export FOUNDRY_LIBRARIES="contracts/protocols/lending/aave/v4/spoke/libraries/LiquidationLogic.sol:LiquidationLogic:0x..."
forge build --force
```

Idempotent: if library already has code, skip deploy.

### Step C — Core orchestration deploy

Call:

```solidity
AaveV4DeployOrchestration.deployAaveV4(
  logger,
  deployer,
  inputs,                    // hardcoded FullDeployInputs
  BytecodeHelper.getHubBytecode(),
  BytecodeHelper.getSpokeBytecode()  // must be linked with LiquidationLogic
);
```

**Orchestration order (exact):**

| # | Step | Produces |
|---|------|----------|
| C1 | Deploy Authority batch | `AccessManagerEnumerable` (admin = deployer) |
| C2 | Label all roles | AccessManager role labels |
| C3 | Deploy Configurator batch | `HubConfigurator`, `SpokeConfigurator` |
| C4 | Setup configurator target roles | selector → role mappings |
| C5 | Deploy TreasurySpoke batch | TreasurySpoke proxy + impl |
| C6 | Validate unique hub/spoke labels | revert on duplicates |
| C7 | For each hub label | HubInstance proxy + impl + InterestRateStrategy; hub roles |
| C8 | For each spoke label | **AaveOracle** + SpokeInstance proxy + impl; wire oracle↔spoke; spoke roles |
| C9 | If flags | NativeTokenGateway, SignatureGateway |
| C10 | If flag | Giver / Taker / Config PositionManagers |
| C11 | If `grantRoles` | Grant hub/spoke/configurator admins; optionally replace AccessManager default admin |

**Bytecode load paths (Crane):**

```text
HubInstance  → contracts/protocols/lending/aave/v4/hub/instances/HubInstance.sol:HubInstance
SpokeInstance → contracts/protocols/lending/aave/v4/spoke/instances/SpokeInstance.sol:SpokeInstance
```

(`BytecodeHelper` already retargeted for Crane.)

**Operator command:**

```bash
forge script scripts/foundry/bc/Script_BC_Phase3_Aave.s.sol:Script_BC_Phase3_Aave \
  --rpc-url battlechain-sepolia \
  --broadcast \
  --skip-simulation \
  --account deployer \
  --sender "$DEPLOYER" \
  -g 400
```

(Script may run V3 then V4 modules, or V4-only entry — both fixed; no flags.)

**Outputs:**

- On-chain report via Logger JSON under `output/reports/deployments/` (if enabled)  
- Crane greenfield manifest: `docs/deployment/addresses/battlechain-sepolia-aave.json` (V3 + V4 keys)  
- Console log of all batch addresses  

### Step D — Post-deploy market configuration (required for “usable”)

Orchestration **does not** list assets or add reserves. Tests do this in `Base.t.sol` via `AaveV4TestOrchestration.configureHubsAssets` / `configureHubsSpokes` / `configureSpokes`.

**Hardcode in the same Phase 3 script (or fixed follow-up `Script_BC_Phase3b_AaveV4_Configure.s.sol` with no options):**

| # | Action | Using |
|---|--------|--------|
| D1 | Grant temporary configurator roles to deployer if needed | AccessManager |
| D2 | Hub: `addAsset` for each underlying (WETH, USDC, DAI, …) | HubConfigurator / Hub |
| D3 | Hub: `addSpoke` linking hub ↔ spoke | HubConfigurator |
| D4 | Spoke: set price sources to **BC Chainlink** feeds | `updateReservePriceSource` / oracle config |
| D5 | Spoke: `addReserve` + liquidation / dynamic config for each asset | SpokeConfigurator |
| D6 | Optional: deploy TokenizationSpoke per listed asset | `AaveV4TokenizationSpokeBatch` (after listing) |
| D7 | Renounce temporary roles if script granted extras | AccessManager |

**Minimal BC market:** WETH + USDC reserves with ETH/USD and USDC/USD BC mocks.

**Config parameters** (LTV, caps, IR, liquidation bonuses): freeze numbers in script constants (copy from Aave V4 test setup defaults in `Base.t.sol` / `_getSpokeReserveParams`, adapted for BC token decimals).

### Step E — Verify

```bash
# AccessManager / Hub / Spoke have code
cast code $ACCESS_MANAGER --rpc-url battlechain-sepolia | head -c 20
cast code $HUB --rpc-url battlechain-sepolia | head -c 20
cast code $SPOKE --rpc-url battlechain-sepolia | head -c 20

# Oracle points at spoke
# Spoke ORACLE() == aaveOracle

# Optional: mint BC USDC, approve spoke, supply (script or cast)
```

### Step F — Docs + X

1. Agent updates manifests, `deployed-addresses.md`, `BC_TESTNET` Aave V4 section.  
2. Post Phase 3 X draft (covers Aave; mention V3+V4 if both shipped).

---

## 4. Script deliverables (implement once; fixed)

| Script | Role |
|--------|------|
| `Script_BC_Phase3b_AaveV4_LibraryPreCompile.s.sol` | Step B — LiquidationLogic + FOUNDRY_LIBRARIES (Crane path) |
| `Script_BC_Phase3_Aave.s.sol` | Phase 3a V3 (if any) + Step C orchestration + Step D config **or** split: |
| `Script_BC_Phase3b_AaveV4.s.sol` | Step C only |
| `Script_BC_Phase3b_AaveV4_Configure.s.sol` | Step D only |

All options hardcoded. Commands listed in [`BC_GREENFIELD_COMMANDS.md`](./BC_GREENFIELD_COMMANDS.md).

---

## 5. Address manifest keys (minimum)

```json
{
  "aaveV4": {
    "accessManager": "0x…",
    "hubConfigurator": "0x…",
    "spokeConfigurator": "0x…",
    "treasurySpoke": "0x…",
    "hubs": { "core": { "proxy": "0x…", "implementation": "0x…", "interestRateStrategy": "0x…" } },
    "spokes": { "bc": { "proxy": "0x…", "implementation": "0x…", "aaveOracle": "0x…" } },
    "nativeTokenGateway": "0x…",
    "signatureGateway": "0x…",
    "giverPositionManager": "0x…",
    "takerPositionManager": "0x…",
    "configPositionManager": "0x…",
    "liquidationLogic": "0x…",
    "salt": "0x…",
    "nativeWrapper": "0x4CAc…",
    "create2Factory": "0x914d… or CreateX if Path B"
  }
}
```

---

## 6. Failure modes

| Symptom | Cause | Fix |
|---------|--------|-----|
| `MissingCreate2Factory` | No code at `0x914d…` | Step A |
| Spoke deploy / empty bytecode / bad link | LiquidationLogic not linked | Re-run B + `forge build --force` with `FOUNDRY_LIBRARIES` |
| `ContractAlreadyDeployed` | Re-run same salt+bytecode | Expected on re-broadcast; treat as success if code correct, or new salt only if intentional new generation (change script constant) |
| OOG | Large batches | Re-run same command with `-g 500` / `-g 600` |
| Oracle / reserve reverts | Config step skipped or wrong feed decimals | Complete Step D; BC feeds are 8 decimals |

---

## 7. Relationship to Aave V3 (Phase 3a)

| | V3 | V4 |
|--|----|----|
| Code path | `aave/v3.6/deployments/procedures` | `aave/v4/deployments/orchestration` |
| Deploy style | Procedure `new` + proxies | CREATE2 batches + orchestration |
| BC oracles/tokens | Bind | Bind |
| Order in Phase 3 | 3a then 3b recommended | After or independent of 3a (no hard on-chain dependency) |

Both can share one Phase 3 command sequence (two scripts in fixed order) or one combined script with fixed internal order: **3a → 3b library → 3b core → 3b configure**.

---

## 8. Implementation checklist

- [ ] Resolve Step A (Safe Singleton on BC **or** Path B CreateX/Crane CREATE3 adapter)  
- [ ] Fix library FOUNDRY path for Crane in precompile script  
- [ ] Implement LibraryPreCompile BC script (no prompts)  
- [ ] Implement orchestration BC script with hardcoded `FullDeployInputs`  
- [ ] Implement configure script (hub assets + spoke reserves + BC feeds)  
- [ ] Hermetic test: run orchestration against Anvil with etched CREATE2 factory (existing test pattern)  
- [ ] Add commands to `BC_GREENFIELD_COMMANDS.md`  
- [ ] Manifest schema + `BC_TESTNET` constants  
- [ ] Wire Phase 3 X post after live  

---

## 9. Source map

| Concern | Location |
|---------|----------|
| Orchestration entry | `deployments/orchestration/AaveV4DeployOrchestration.sol` → `deployAaveV4` |
| Inputs | `deployments/utils/libraries/InputUtils.sol` → `FullDeployInputs` |
| CREATE2 | `deployments/utils/libraries/Create2Utils.sol` |
| Batches | `deployments/batches/*.sol` |
| Library precompile | `test/.../aave/v4/scripts/LibraryPreCompile.s.sol` |
| Example inputs | `test/.../aave/v4/scripts/deploy/examples/AaveV4DeployAnvil.s.sol` |
| Base script | `test/.../aave/v4/scripts/deploy/AaveV4DeployBatchBase.s.sol` |
| Post-config pattern | `test/.../aave/v4/setup/Base.t.sol` → `_configureHubsAndSpokes` |
| Upstream README | `contracts/protocols/lending/aave/v4/deployments/README.md` |
| Provenance | `docs/protocols/lending/aave/v4/VENDOR_PROVENANCE.md` |

---

## 10. Change log

| Date | Change |
|------|--------|
| 2026-07-23 | Full BC steps: CREATE2 gate, LiquidationLogic, orchestration order, config, manifests, Path B note |
