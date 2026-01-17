# Code Review: CRANE-061

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-17
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

1) Does “deploy BalancerV3ConstantProductPoolDFPkg via the factory” mean `ICreate3Factory.deployPackageWithArgs(...)`, or is `new BalancerV3ConstantProductPoolDFPkg(...)` acceptable in tests?
- Answer (self-resolved): Per CRANE-061 US-CRANE-061.1 acceptance criteria wording (“via the actual factory stack”) and existing Crane patterns, this should mean deploying the package via `Create3Factory` (and facets via `deployFacet`) rather than `new`.
- Status: Resolved

---

## Review Findings

### Finding 1: “Real factory stack” not fully exercised
**File:** test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol
**Severity:** High
**Description:**
- The test uses `CraneTest.setUp()` (good: uses `InitDevService`), and it deploys the proxy via `diamondFactory.deploy(pkg, pkgArgs)` (good).
- However, the test deploys facets and the package with `new` (`new BalancerV3VaultAwareFacet()`, `new BalancerV3ConstantProductPoolDFPkg(...)`) rather than deploying facets/packages through `ICreate3Factory`.
- This means US-CRANE-061.1 acceptance criteria “deploys BalancerV3ConstantProductPoolDFPkg via the factory” is not met, and the test does not validate the deterministic CREATE3 path for package + facets.
**Status:** Open
**Resolution:** Deploy facets via `create3Factory.deployFacet(...)` and deploy the package via `create3Factory.deployPackageWithArgs(...)` in the integration test.

### Finding 2: “Pool state initialized correctly” is not asserted
**File:** test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol
**Severity:** Medium
**Description:**
- US-CRANE-061.2 requires asserting pool state initialization.
- Current tests validate ERC20 name/symbol/decimals and EIP-712 domain/DOMAIN_SEPARATOR, but do not assert any Balancer pool state from `BalancerV3PoolRepo` (e.g., token list stored, swap fee bounds, invariant ratio bounds, etc.).
- The test uses a `MockPoolInfoFacet` that only supplies selectors for loupe inspection; it does not implement IPoolInfo calls, which prevents validating runtime behavior/state through the proxy.
**Status:** Open
**Resolution:** Use a real PoolInfo facet (or a minimal target+facet that reads from the pool repo) and add assertions for the initialized token set and relevant pool parameters.

### Finding 3: Vault-aware facet behavior is not validated (and may be uninitialized in proxy)
**File:** contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol
**Severity:** Medium
**Description:**
- The implementation fix initializes `BalancerV3VaultAwareRepo` in the package constructor so `postDeploy()` can register with the vault (good).
- But `initAccount()` does not initialize `BalancerV3VaultAwareRepo` in the proxy storage. Since `BalancerV3VaultAwareFacet` reads `BalancerV3VaultAwareRepo` from proxy storage, `IBalancerV3VaultAware(proxy).balV3Vault()` will likely return `address(0)` unless something else initializes it.
- The current integration tests only verify selector-to-facet mapping for `balV3Vault()`; they never call `balV3Vault()` or `getAuthorizer()` on the proxy.
**Status:** Open
**Resolution:** Initialize `BalancerV3VaultAwareRepo` inside `initAccount()` (delegatecalled into proxy) and add integration assertions that `balV3Vault()` returns the expected vault and `getAuthorizer()` behaves as expected.

### Finding 4: Vault registration assertions are minimal
**File:** test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol
**Severity:** Low
**Description:**
- US-CRANE-061.3 asks to assert expected calls to vault registration.
- The test asserts “registration happened” and “pool address matches,” but does not assert the token config array content, the hooks contract, swap fee, pause window end, or the caller identity (e.g., `lastPoolFactory`).
**Status:** Open
**Resolution:** Assert `lastPoolFactory` and/or decode the `PoolRegistered` event to validate the full call payload.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Make the integration test truly "factory-stack" end-to-end
**Priority:** P1
**Description:** Deploy all real facets and the DFPkg via `ICreate3Factory` (instead of `new`) so the test validates deterministic deployment + registry behavior.
**Affected Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-118

### Suggestion 2: Add proxy-state assertions for pool + vault-aware repos
**Priority:** P1
**Description:**
- Initialize `BalancerV3VaultAwareRepo` during `initAccount()` and add assertions that `IBalancerV3VaultAware(proxy).balV3Vault()` equals the configured vault.
- Add assertions that the pool's token list/state is correctly stored/accessible after deployment.
**Affected Files:**
- contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-119

### Suggestion 3: Tighten postDeploy call expectations
**Priority:** P2
**Description:** Validate the full `registerPool(...)` call payload (token configs, hooks, fee params, and caller) rather than only checking that a call happened.
**Affected Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-120

---

## Review Summary

**Findings:** 4 (1 High, 2 Medium, 1 Low)
**Suggestions:** 3 (2x P1, 1x P2)
**Recommendation:** Request changes (acceptance criteria not fully met as written)

Notes:
- `forge test --match-path test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol -vvv` passes (12/12).
- The constructor change adding `BalancerV3VaultAwareRepo._initialize(...)` appears correct for enabling `postDeploy()` registration.

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`

<promise>REVIEW_COMPLETE</promise>
