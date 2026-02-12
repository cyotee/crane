# Code Review: CRANE-054

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-16
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

- None. Task scope and acceptance criteria are clear.

---

## Review Findings

### Finding 1: Zero-filled selector slots could cause collisions (Resolved)
**File:** contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolFacet.sol
**Severity:** High
**Description:** `facetInterfaces()` and `facetFuncs()` previously over-allocated their `bytes4[]` arrays, leaving trailing zero values (`0x00000000`). When aggregated into a package's facet cuts, these zero selectors can appear multiple times and trigger selector-collision failures.
**Status:** Resolved
**Resolution:** Arrays were resized to match the number of populated entries (1 interface, 3 selectors).

### Finding 2: “Deployment test” does not deploy a proxy (Open)
**File:** test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_RealFacets.t.sol
**Severity:** Low
**Description:** The new spec validates selector uniqueness using real facet contracts but does not execute the full Diamond deployment path via `IDiamondPackageCallBackFactory.deploy(...)` (and therefore does not validate runtime initialization / postDeploy behavior, if any).
**Status:** Open
**Resolution:** (Suggested follow-up below)

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Assert selectors are non-zero
**Priority:** Medium
**Description:** In addition to checking duplicates, add a guard that no selector equals `bytes4(0)` (this catches “partially initialized array” issues even if they don’t produce duplicates).
**Affected Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_RealFacets.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-110

### Suggestion 2: Add an integration-style deployment test via factory
**Priority:** Medium
**Description:** Add a separate test that uses the canonical factory bootstrap (`InitDevService.initEnv(...)`) to deploy the DFPkg + proxy via `DiamondPackageCallBackFactory`, and then asserts initialization results (e.g., vault-aware storage set, token configs sorted/recorded, etc.).
**Affected Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/...
**User Response:** Accepted
**Notes:** Converted to task CRANE-111

### Suggestion 3: Don’t reuse `MockPoolInfoFacet` for unrelated init fields
**Priority:** Low
**Description:** In `_deployPkgWithRealFacets()`, the `standardSwapFeePercentageBoundsFacet` and `unbalancedLiquidityInvariantRatioBoundsFacet` are populated with the pool-info mock. If/when those fields begin affecting `facetCuts()`, the test could become misleading. Prefer dedicated mocks or explicit assertions that those fields are currently unused.
**Affected Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_RealFacets.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-112

---

## Review Summary

**Findings:** 1 resolved (high), 1 open (low)
**Suggestions:** 3 follow-ups (2 medium, 1 low)
**Recommendation:** Approve. The core collision risk is fixed and the real-facets selector-collision spec passes.

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
