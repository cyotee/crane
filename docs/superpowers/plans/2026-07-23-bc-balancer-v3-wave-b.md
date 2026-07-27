# Plan: BattleChain Wave B — Balancer V3 (Crane DFPkg port)

**Date:** 2026-07-23  
**Target:** BattleChain Testnet (chain `627`)  
**Port tree:** `contracts/protocols/dexes/balancer/v3/`  
**Script:** `scripts/foundry/Script_Promo_BC_BalancerV3.s.sol`  
**Depends on:** Wave A (`Script_Promo_BC_Launch`) — factories, WETH, Permit2 live in `BC_TESTNET`

---

## Goal

Deploy the Crane **package-based Balancer V3 fork** (Vault diamond, Router diamond, and pool DFPkgs) on BattleChain so **other contracts can depend on Balancer V3** for swaps, LP, and pool creation — under Safe Harbor / attack-mode practice before promotion.

Downstream consumers (IndexedEx DETFs, rate-provider products, hooks, Gyro/ReClamm experiments) must be able to:

1. Call a live **Vault** (unlock / settle / swap / add-remove liquidity / register pools).
2. Call a live **Router** (Permit2 + BC WETH) for user-facing ops.
3. Call **pool packages** (`deployPool`) for Weighted, Stable, and Constant Product without redeploying vault/router facets.

---

## Principles (non-negotiable)

| Rule | Detail |
|------|--------|
| **Use, do not replace** | Bind Wave A + BC-provided: `CREATE3_FACTORY`, `DIAMOND_PACKAGE_CALLBACK_FACTORY`, `WETH`, `BETTER_PERMIT2`, mock stables. Never redeploy WETH or replace factories. |
| **Package path only** | Vault / Router / Pools via `*DFPkg` + `DiamondPackageCallBackFactory`, not one-off upstream constructors. |
| **Facets via Create3** | `ICreate3Factory.deployFacet` + `deployPackageWithArgs` (same pattern as Wave A ERC20Permit and pool integration tests). |
| **Determinism** | Fixed facet/package salts (`keccak256("bc-balv3-…-v1")`) so re-broadcast is idempotent where CREATE3 allows; diamond proxies remain calcAddress-stable. |
| **Gold path tests** | Script mirrors: `BalancerV3RouterVaultIntegration.t.sol`, `BalancerV3VaultDFPkg.t.sol`, `BalancerV3*PoolDFPkg_Integration.t.sol`. |
| **Attack surface** | Prefer reusing Wave A agreement (Create3Factory + `ChildContractScope.All`). Optional Wave B agreement salt for clearer docs. |

---

## Architecture (what ships)

```
Wave A (existing)
  CREATE3_FACTORY ──► deployFacet / deployPackageWithArgs
  DIAMOND_FACTORY ──► deploy(pkg, args)  [proxies]
  WETH (BC) · BETTER_PERMIT2 (Crane)

Wave B (this plan)
  ┌─ Vault facets (9) → BalancerV3VaultDFPkg → Vault diamond
  │     + NullAuthorizer (promo) / Timelock later
  │     + ProtocolFeeController (two-step: vault first, then set)
  ├─ Router facets (9) → BalancerV3RouterDFPkg → Router diamond
  │     vault + WETH + Permit2 + version string
  ├─ Shared pool facets (VaultAware, PoolToken, Auth, Pool info)
  └─ Pool packages (bound to live Vault):
        Weighted · Stable · ConstantProduct
        (Phase 2+: Gyro 2-CLP / E-CLP, LBP, CoW, ReClamm, rate-provider pkg)
```

### Why packages matter for dependents

Dependents should hold addresses for:

| Surface | Role for integrators |
|---------|----------------------|
| `vault` | `IVault` singleton — register pools, settle, query |
| `router` | `IRouter` / batch / buffer / composite entrypoints |
| `weightedPoolPkg` | `deployPool(tokenConfigs, weights, hooks)` |
| `stablePoolPkg` | `deployPool(tokenConfigs, amp, hooks)` |
| `constProdPoolPkg` | `deployPool(tokenConfigs, hooks)` |

Facets/packages are infrastructure; **instances** (vault, router, optional demo pool) are what apps wire.

---

## Phases

### Phase 0 — Preconditions (no broadcast)

- [ ] Wave A addresses present on chain 627 (`cast code` on `BC_TESTNET.CREATE3_FACTORY`, `WETH`, `BETTER_PERMIT2`).
- [ ] Local hermetic green (subset):
  - `BalancerV3VaultDFPkg.t.sol`
  - `BalancerV3RouterDFPkg.t.sol` / `BalancerV3RouterVaultIntegration.t.sol`
  - Weighted / Stable / ConstProd DFPkg unit or integration tests
- [ ] Deployer funded on BC testnet; always pass `--sender $DEPLOYER` (never Foundry default `0x1804…`).
- [ ] Security contact set in script before public attack-mode posts.

### Phase 1 — Vault (blocking)

1. Deploy **9 vault facets** via Create3:
   - `VaultTransientFacet`, `VaultSwapFacet`, `VaultLiquidityFacet`, `VaultBufferFacet`
   - `VaultPoolTokenFacet`, `VaultQueryFacet`, `VaultRegistrationFacet`
   - `VaultAdminFacet`, `VaultRecoveryFacet`
2. Deploy `BalancerV3VaultDFPkg` via `deployPackageWithArgs`.
3. Deploy `NullAuthorizer` (promo; always allows). Production later: `TimelockAuthorizer`.
4. **Fee controller chicken-egg:**
   - Deploy Vault with `protocolFeeController = address(0)` (or temp mock).
   - Deploy real `ProtocolFeeController(vault, 0, 0)`.
   - `IVaultAdmin(vault).setProtocolFeeController(pfc)` (NullAuthorizer permits).
5. Params (match integration tests unless tuned):
   - `minimumTradeAmount = 1e6`
   - `minimumWrapAmount = 1e6`
   - `pauseWindowDuration = 365 days`
   - `bufferPeriodDuration = 90 days`

**Exit criteria:** `vault.code.length > 0`, loupe returns facets, `getAuthorizer()` / `getProtocolFeeController()` sane.

### Phase 2 — Router (blocking)

1. Deploy **9 router facets** via Create3:
   - `RouterSwapFacet`, `RouterAddLiquidityFacet`, `RouterRemoveLiquidityFacet`
   - `RouterInitializeFacet`, `RouterCommonFacet`
   - `BatchSwapFacet`, `BufferRouterFacet`
   - `CompositeLiquidityERC4626Facet`, `CompositeLiquidityNestedFacet`
2. Deploy `BalancerV3RouterDFPkg`.
3. `deployRouter(vault, WETH, Permit2, "Crane Balancer V3 Router BC v1")`.

**Exit criteria:** `router.getVault() == vault`, `getWeth() == BC WETH`.

### Phase 3 — Pool packages (blocking for dependents)

Shared facets (Create3 once):

- `BalancerV3VaultAwareFacet`
- `BetterBalancerV3PoolTokenFacet` (or `BalancerV3PoolTokenFacet` where package expects it)
- `BalancerV3AuthenticationFacet`
- Pool-info / bounds: use production pool facet surface (`BalancerV3PoolFacet` or type-specific facets per package cuts)

Packages (each `deployPackageWithArgs`, **PkgInit.vault = live vault**):

| Package | Purpose |
|---------|---------|
| `BalancerV3WeightedPoolDFPkg` | Custom weights (80/20, etc.) |
| `BalancerV3StablePoolDFPkg` | Correlated assets / stables |
| `BalancerV3ConstantProductPoolDFPkg` | 50/50 x*y=k |

`poolFeeManager` = deployer EOA for promo (or dedicated role address).

**Exit criteria:** each package has code; `packageName()` correct; `calcAddress` / dry `deployPool` succeeds for a two-token config (smoke).

### Phase 4 — Smoke instance (recommended)

Deploy **one demo pool** so dependents have a concrete pool to target:

- Tokens: BC `WETH` + `USDC` (or `DAI`)
- Type: Constant Product or Weighted 50/50
- Do **not** require mainnet-scale liquidity; optional tiny init via router if gas/funds allow

Document demo pool address in Wave B manifest.

### Phase 5 — Manifest + constants

On success, script writes:

| Path | Role |
|------|------|
| `docs/deployment/addresses/battlechain-sepolia-balancer-v3.json` | Machine source of truth (Wave B) |
| `docs/deployment/addresses/battlechain-sepolia-balancer-v3.table.md` | mdBook table |
| `script/output/battlechain-sepolia/wave-b-balancer-v3.latest.json` | Runtime copy |

Human/agent follow-up:

- Extend `BC_TESTNET.sol` with `BALANCER_V3_*` constants
- Update `docs/deployment/deployed-addresses.md` + `docs/deployment/battlechain.md`
- Optionally merge Wave B keys into main `battlechain-sepolia.json` under `"balancerV3": { … }`

### Phase 6 — Safe Harbor / attack mode

- Wave A agreement already scopes Create3Factory + All children → new facets/packages/proxies under those factories are in scope if still adopted.
- Still: verify agreement scope covers new diamonds; re-`requestAttackMode` if process requires per wave.
- Announce attackable Balancer V3 surface only after smoke + manifest published.

### Phase 7 — Phase 2+ packages (non-blocking for “dependents can build”)

Order by demand:

1. `ERC4626RateProviderFacetDFPkg`
2. Gyro 2-CLP / E-CLP packages
3. LBP package
4. CoW pool + CoW router packages
5. ReClamm factory path
6. Example hooks (MevCapture, StableSurge) — only if needed for attack scenarios

---

## Deploy order (script implementation)

```
bind Wave A addresses
→ vault facets → vault DFPkg → authorizer → vault instance → ProtocolFeeController → setController
→ router facets → router DFPkg → router instance
→ shared pool facets → weighted/stable/constProd DFPkgs
→ (optional) demo pool
→ write manifests → log explorer links
```

Do **not** call `InitBcService.initEnvBc` again if Wave A factories already exist — **bind** `BC_TESTNET.CREATE3_FACTORY` / `DIAMOND_PACKAGE_CALLBACK_FACTORY`.

---

## Broadcast command

```bash
cd daosys/lib/indexedex/lib/crane

export DEPLOYER=$(cast wallet address --account deployer)

forge script scripts/foundry/Script_Promo_BC_BalancerV3.s.sol:Script_Promo_BC_BalancerV3 \
  --rpc-url battlechain-sepolia \
  --broadcast \
  --skip-simulation \
  --account deployer \
  --sender "$DEPLOYER" \
  -vvvv
```

**Always** `--sender $DEPLOYER`. Omitting it hits Foundry’s default `0x1804…` and reverts with the script guard.

Local dry path (no BC):

```bash
forge script scripts/foundry/Script_Promo_BC_BalancerV3.s.sol:Script_Promo_BC_BalancerV3 \
  --sender "$DEPLOYER" -vvvv
```

(Requires forked or mock factories if binding live addresses; prefer unit/integration tests for CI.)

---

## Acceptance criteria (Definition of Done)

| # | Criterion |
|---|-----------|
| 1 | Vault diamond live; loupe non-empty; admin/query selectors respond |
| 2 | Router diamond live; `getVault` / WETH / Permit2 wired to Wave A + BC |
| 3 | Weighted + Stable + ConstProd **packages** live and bound to vault |
| 4 | At least one pool instance deployable via package (demo or CI) |
| 5 | JSON + table manifests written; agent can refresh `BC_TESTNET` |
| 6 | Dependents can import addresses and call vault/router without redeploying Balancer core |
| 7 | X announcement ready (see `docs/roadmap/X_BC_BALANCER_V3.md`) |

---

## Risks / sharp edges

| Risk | Mitigation |
|------|------------|
| Stack-too-deep in script | Split helpers (`_deployVaultFacets`, `_deployRouter…`); line-oriented `vm.writeFile` |
| ProtocolFeeController ↔ vault circularity | Two-step deploy + `setProtocolFeeController` |
| NullAuthorizer too open | Promo/testnet only; TimelockAuthorizer before production promotion |
| Facet 24kb limit | Already enforced in TestBase; fail fast on deploy if oversized |
| Pool info facet mismatch | Mirror integration test PkgInit wiring; prefer shared `BalancerV3PoolFacet` |
| Gas / long broadcast | Phased broadcast if needed (vault+router first, pools second) |
| Agreement scope gaps | Confirm Wave A All-children still adopted; expand scope if diamonds use other deployers |

---

## Out of scope (this wave)

- Mainnet / Base promotion
- Full Balancer governance (veBAL, gauge)  
- Frontend / SDK packaging  
- IndexedEx product vaults consuming BPT (follow-on after addresses land)
- Fork parity vs Ethereum mainnet Balancer deployments (separate verification plan)

---

## References

- Port: `contracts/protocols/dexes/balancer/v3/`
- Vault DFPkg: `vault/diamond/BalancerV3VaultDFPkg.sol`
- Router DFPkg: `router/diamond/BalancerV3RouterDFPkg.sol`
- Integration gold path: `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterVaultIntegration.t.sol`
- Wave A: `scripts/foundry/Script_Promo_BC_Launch.s.sol`, `docs/deployment/battlechain.md`
- Constants: `contracts/constants/networks/BC_TESTNET.sol`
- Skill: `crane-balancer` / `balancer-v3-*` skill family
