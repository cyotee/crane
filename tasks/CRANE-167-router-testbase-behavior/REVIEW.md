# Code Review: CRANE-167

**Reviewer:** OpenCode (automated)
**Review Started:** 2026-01-30
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

- None

---

## Review Findings

### Finding 1: Missing validation for getWeth/getPermit2
**File:** `contracts/protocols/dexes/balancer/v3/router/diamond/Behavior_IRouter.sol`
**Severity:** Medium
**Description:** Tests and `Behavior_IRouter` validate `IRouterCommon.getVault()` but do not validate `IRouterCommon.getWeth()` or `IRouterCommon.getPermit2()`. This leaves part of the router's common configuration unverified even though `TestBase_BalancerV3Router` deploys mocks for WETH + Permit2.
**Status:** Open
**Resolution:** Add `expect_*/hasValid_*` + `isValid_*` helpers for `getWeth()` and `getPermit2()`, and extend `BalancerV3RouterDFPkg.t.sol` with tests mirroring the `getVault()` checks.

### Finding 2: Expectation helper without corresponding hasValid
**File:** `contracts/protocols/dexes/balancer/v3/router/diamond/Behavior_IRouter.sol`
**Severity:** Low
**Description:** `expect_IRouter_interfaces()` records expected interfaces, but there is no `hasValid_IRouter_interfaces()` that consumes those stored expectations (only direct `areValid_IRouter_interfaces(...)` exists). This is slightly inconsistent with the repo's Behavior pattern (expect/hasValid pairing).
**Status:** Open
**Resolution:** Either add `hasValid_IRouter_interfaces(address subject, bytes4[] memory actual)` (or `hasValid_*` that reads the stored set) or remove `expect_IRouter_interfaces()` if not used.

### Finding 3: Unused imports
**File:** `contracts/protocols/dexes/balancer/v3/router/diamond/Behavior_IRouter.sol`
**Severity:** Low
**Description:** Several imports are currently unused (e.g., `IVault`, `IRouter`, `IBatchRouter`, `IBufferRouter`, `ICompositeLiquidityRouter`, `AddressSetComparator*`). This may emit warnings and adds noise.
**Status:** Open
**Resolution:** Remove unused imports or add the corresponding validations that use them.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Round out IRouterCommon storage validation
**Priority:** High
**Description:** Add Behavior helpers + tests for `IRouterCommon.getWeth()` and `IRouterCommon.getPermit2()` to match the existing `getVault()` pattern.
**Affected Files:**
- `contracts/protocols/dexes/balancer/v3/router/diamond/Behavior_IRouter.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterDFPkg.t.sol`
**User Response:** (pending)
**Notes:** Keeps the TestBase/Behavior adoption consistent and improves coverage of router initialization.

### Suggestion 2: Consider using Behavior_IRouter for facet size checks everywhere
**Priority:** Low
**Description:** `TestBase_BalancerV3Router` has an internal `_validateFacetSizes()` that duplicates Behavior logic (`Behavior_IRouter.isValid_facetSize/areValid_facetSizes`). Consider removing duplication or routing TestBase checks through the Behavior library for a single source of truth.
**Affected Files:**
- `contracts/protocols/dexes/balancer/v3/router/diamond/TestBase_BalancerV3Router.sol`
- `contracts/protocols/dexes/balancer/v3/router/diamond/Behavior_IRouter.sol`
**User Response:** (pending)
**Notes:** Pure refactor; not required for correctness.

---

## Review Summary

**Findings:** 3 (1 medium, 2 low)
**Suggestions:** 2
**Recommendation:** Approve with follow-ups (add missing getWeth/getPermit2 coverage)

**Local verification:**
- `forge test --match-contract BalancerV3RouterDFPkgTest` -> PASS (17/17)

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
