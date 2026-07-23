# Plan: Idempotent package CREATE3 + **full greenfield** BattleChain redeploy

**Date:** 2026-07-23 (revised)  
**Constraint (operator):** **No diamondCut on BattleChain.** Do **not** upgrade the live Wave A Create3Factory in place.  
**Intent:** Fix the factory bug in code, then **redeploy everything from scratch** on BC testnet under a **new** factory root (and new Safe Harbor agreement).

---

## 0. Decision summary

| Choice | Decision |
|--------|----------|
| Factory bug | Fix in source so packages match facets (idempotent `_create3WithArgs`) |
| Ship fix to BC | **New deploy only** — no diamondCut of existing factory |
| Prior Wave A / Wave B addresses | **Abandoned.** Do not reuse. Update docs/`BC_TESTNET` only after greenfield success |
| BC-provided contracts | **Still use, never redeploy** (WETH, Uni V3, mocks, BC infrastructure) |
| Crane-owned stack | **Full redeploy:** Create3Factory, diamond factory, ERC20Permit surface, Uni V2/V4, Permit2, then Balancer V3 vault/router/pool packages |

---

## 1. Root cause (unchanged)

| Entry | Idempotent? |
|-------|-------------|
| `create3` / `deployFacet` (no args) | **Yes** — early-return if predicted address has code |
| `create3WithArgs` / `deployPackageWithArgs` / `deployFacetWithArgs` | **No** — hits `TargetAlreadyExists()` |

### Fix in code (required before greenfield broadcast)

**`Create3FactoryService._create3WithArgs`** — mirror `_create3`:

```solidity
function _create3WithArgs(bytes memory initCode, bytes memory initData_, bytes32 salt)
    internal
    returns (address proxy)
{
    address predictedTarget = Creation._create3AddressOf(salt);
    if (predictedTarget.isContract()) {
        return predictedTarget;
    }
    return Creation.create3WithArgs(initCode, initData_, salt);
}
```

Same pattern for **`Create3Factory._create3WithArgs`** if that path remains.

NatSpec: returning existing code does **not** re-run constructors; new immutables require a new salt.

Also verify `_registerPackage` / `_registerFacet` on double-call do not corrupt registries (idempotent by address or skip if already registered).

### Tests

- Double `deployPackageWithArgs` same salt → no revert, same address  
- Double `create3WithArgs` / `deployFacetWithArgs` → same  
- Existing package/facet no-args tests still pass  

```bash
forge test --match-contract Create3Factory -vv
```

---

## 2. Greenfield BC redeploy (no diamondCut)

### 2.1 What stays (do not redeploy)

From BattleChain docs / prior policy:

- SafeHarborRegistry, AgreementFactory, AttackRegistry, BattleChainDeployer, CreateX  
- **WETH**, USDC/DAI/… mocks  
- **Uniswap V3** factory / router / NPM  
- Chainlink mocks, etc.

Bind only. Never replace.

### 2.2 What is deployed fresh (Crane-owned)

**Wave A surface (new factory root):**

1. **Create3Factory** via `InitBcService.initEnvBc` → BattleChainDeployer lineage  
2. **DiamondPackageCallBackFactory** (wired to new Create3Factory)  
3. ERC20 / ERC5267 / ERC2612 facets + **ERC20PermitDFPkg** + sample token (optional)  
4. **Uni V2** factory + router (create3)  
5. **Uni V4** PoolManager (create3)  
6. **BetterPermit2** (create3)  
7. **New Safe Harbor agreement** scoped to **new** Create3Factory + `ChildContractScope.All`  
8. `requestAttackMode` on **that new agreement only** (not the old Wave A agreement)

**Wave B surface (same new factory):**

1. Balancer vault facets + `BalancerV3VaultDFPkg` + authorizer + vault + ProtocolFeeController  
2. Router facets + `BalancerV3RouterDFPkg` + router  
3. Shared + type pool facets + Weighted / Stable / ConstProd packages  

All CREATE3 salts under the **new** factory are naturally fresh (new deployer address ⇒ different CREATE3 addresses even with same salt strings). Prefer still using a clear salt generation tag (e.g. `crane-bc-fresh-2026-07`) for readability and future re-runs.

### 2.3 Scripts

| Script | Role |
|--------|------|
| `Script_Promo_BC_Launch.s.sol` | Greenfield Wave A (factories + Uni stubs + Permit2 + agreement + attack mode) |
| `Script_Promo_BC_BalancerV3.s.sol` | Wave B Balancer — **must bind addresses from the new Wave A run**, not hard-coded old `BC_TESTNET` |

**Required script change for Balancer:** stop hardcoding only old `BC_TESTNET.CREATE3_FACTORY`. Prefer:

- Env vars / JSON written by Wave A launch (`docs/deployment/addresses/battlechain-sepolia.json`), or  
- Single combined “full stack” script that does Wave A then Wave B in one broadcast session, or  
- Pass factory/diamond/permit2/weth as constructor/env after Wave A completes  

Hardcoding the abandoned factory will redeploy Balancer onto the **old** root again.

### 2.4 Broadcast order

```text
1. Fix factory code + tests (local)
2. Broadcast Script_Promo_BC_Launch  (new Create3Factory root)
   → write battlechain-sepolia.json (overwrite as new source of truth)
3. Confirm: factory code, diamond factory, WETH bind, Permit2, agreement, attack mode
4. Broadcast Script_Promo_BC_BalancerV3 against NEW factories
   → write battlechain-sepolia-balancer-v3.json
5. Full verify (below)
6. Rewrite BC_TESTNET + deployed-addresses docs for the new generation only
7. Commit/push; announce
```

Gas / BC flags (every forge script):

```bash
--rpc-url battlechain-sepolia
--broadcast
--skip-simulation
--account deployer
--sender "$DEPLOYER"
-g 400          # raise to 500/600 if OOG on large facets
```

Always:

```bash
export DEPLOYER=$(cast wallet address --account deployer)
```

### 2.5 Safe Harbor / attack mode

- **Old** agreement (`0xC0C1…`) stays linked to **old** factory — ignore for ops going forward.  
- **New** agreement scopes **new** Create3Factory only.  
- `requestUnderAttack(newAgreement)` should succeed (new root not already linked).  
- Do not call attack mode on the old agreement for the new stack.

### 2.6 Agreement contact

Replace `REPLACE_BEFORE_BROADCAST` before public attack-mode announcement.

---

## 3. Verification checklist

### Wave A (new)

- [ ] `CREATE3_FACTORY` ≠ old `0xC8E93C3c…AD3A`  
- [ ] Diamond factory has code; linked to new Create3Factory  
- [ ] WETH = BC-provided `0x4CAc…` (unchanged)  
- [ ] Permit2 / Uni V2 / Uni V4 have code under new factory  
- [ ] Agreement adopted; attack mode requested (and approved if needed)  
- [ ] Manifest JSON overwritten and committed as SoT  

### Wave B

- [ ] Vault / router packages deployed via **new** factory  
- [ ] `deployPackageWithArgs` twice (smoke) does not revert on new factory  
- [ ] Vault loupe OK; router `getVault()` = vault  
- [ ] Three pool packages have code  
- [ ] Balancer manifest complete  

### Docs

- [ ] `BC_TESTNET.sol` fully replaced for Crane-owned addresses (old constants removed or clearly archived)  
- [ ] `docs/deployment/deployed-addresses.md` describes **this** generation only  
- [ ] Note: prior gen addresses are obsolete / not supported  

---

## 4. Implementation work breakdown

### PR / commit 1 — Factory idempotency (code + tests)

1. Fix `_create3WithArgs` in service (+ Create3Factory if needed)  
2. Registration safety on re-call  
3. Unit tests for package / with-args double deploy  
4. Optional: remove script-only package short-circuit later (keep until greenfield proven)

### PR / commit 2 — Greenfield scripting

1. Ensure `Script_Promo_BC_Launch` is the clean Wave A entry (review salts if any collision risk on same deployer — new factory address already namespaces CREATE3)  
2. Wire Balancer script to **read new Wave A JSON** (or env) instead of stale `BC_TESTNET` constants  
3. Update `WAVE_B_BALANCER_V3_COMMANDS.md` with two-step: Launch → Balancer  
4. Optional: one umbrella script `Script_Promo_BC_FullStack.s.sol` that chains both for fewer mistakes  

### Ops — Broadcast

1. Fund deployer on BC  
2. Run Launch → confirm JSON  
3. Run Balancer against new factories  
4. Verify  
5. Update constants + docs + push  
6. Announce (docs link only; no hex dump in social)  

---

## 5. Explicit non-goals

- **No diamondCut** on BattleChain (operator constraint)  
- No migration of state from old factory to new  
- No “repair in place” of gen1 Balancer packages  
- No redeploy of BC-provided WETH / Uni V3  

---

## 6. Risks

| Risk | Mitigation |
|------|------------|
| Balancer script still points at old factory | Require JSON/env from latest Launch; fail if factory == abandoned address |
| Agents/docs still cite old `BC_TESTNET` | Overwrite constants + docs in same handoff |
| Gas OOG on large facets | `-g 400+`; resume-safe after factory fix |
| Two factories confuse attackers | Announce only new root; docs mark old gen deprecated |
| Attack mode bond/fee | Fund deployer for registry fees/bonds as required by BC |

---

## 7. Success criteria

- [ ] Factory bug fixed and tested in repo  
- [ ] **New** Create3Factory on BC (address ≠ abandoned Wave A)  
- [ ] Full Crane Wave A surface redeployed under it  
- [ ] Full Balancer V3 surface redeployed under it  
- [ ] Double package deploy is no-op success on new factory  
- [ ] `BC_TESTNET` + Deployed Addresses reflect **only** the new generation  
- [ ] No diamondCut used  

---

## 8. References

- `contracts/factories/create3/Create3FactoryService.sol`  
- `contracts/factories/create3/Create3Factory.sol`  
- `contracts/InitBcService.sol`  
- `scripts/foundry/Script_Promo_BC_Launch.s.sol`  
- `scripts/foundry/Script_Promo_BC_BalancerV3.s.sol`  
- `contracts/constants/networks/BC_TESTNET.sol`  
- `docs/deployment/battlechain.md`  
