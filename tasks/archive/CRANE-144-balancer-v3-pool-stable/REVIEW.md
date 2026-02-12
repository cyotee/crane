# Code Review: CRANE-144

**Reviewer:** OpenCode (gpt-5.2)
**Review Started:** 2026-01-30
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None.

---

## Review Findings

### Finding 1: Incorrect NatSpec selector + interfaceId for IBalancerV3StablePool
**File:** `contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3StablePool.sol`
**Severity:** Medium (docs/ABI metadata correctness)
**Description:** `getAmplificationState()` `@custom:selector` was incorrect (`0xde92c87e`). Correct selector is `0x21da5e19`.
This also implied the `@custom:interfaceid` value was wrong; updated to `0x4c7691e3` (XOR of the two selectors in the interface).
**Status:** Resolved
**Resolution:** Updated NatSpec tags in `contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3StablePool.sol`.

### Finding 2: Stable pool DFPkg missing VaultAwareRepo initialization (breaks postDeploy registration)
**File:** `contracts/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolDFPkg.sol`
**Severity:** High (deployment/integration)
**Description:** `postDeploy()` registers the pool via `_registerPoolWithBalV3Vault()`, which calls `BalancerV3VaultAwareRepo._balancerV3Vault().registerPool(...)`.
Unlike constant-product DFPkg, the stable DFPkg constructor did not call `BalancerV3VaultAwareRepo._initialize(pkgInit.balancerV3Vault)`, so Vault registration would target `address(0)`.
**Status:** Resolved
**Resolution:** Added `BalancerV3VaultAwareRepo._initialize(pkgInit.balancerV3Vault)` in the stable DFPkg constructor and added an integration test that deploys via `DiamondPackageCallBackFactory` and asserts vault registration.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Add stable pool DFPkg deterministic salt/processArgs consistency tests
**Priority:** Medium
**Description:** Mirror the const-prod DFPkg coverage by adding tests for:
1) token order-independence (including heterogeneous TokenConfig fields), and
2) `calcSalt(args) == calcSalt(processArgs(args))`.
**Affected Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/pool-stable/` (new test file)
**User Response:** Accepted
**Notes:** Converted to task CRANE-180

---

## Review Summary

**Findings:** 2 (both resolved)
**Suggestions:** 1
**Recommendation:** Approve (stable pool now has a vault-registration integration test and correct ABI metadata NatSpec).

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
