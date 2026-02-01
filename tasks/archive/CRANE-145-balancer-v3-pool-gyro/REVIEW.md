# Code Review: CRANE-145

**Reviewer:** OpenCode
**Review Started:** 2026-01-31
**Status:** In Progress

---

## Clarifying Questions

Questions asked to understand review criteria:

(Questions and answers will be recorded here during review)

---

## Review Findings

### Finding 1: ECLP init does not enforce upstream param validation
**File:** `contracts/protocols/dexes/balancer/v3/pool-gyro/eclp/BalancerV3GyroECLPPoolDFPkg.sol`
**Severity:** High
**Description:** `initAccount()` stores `eclpParams` and `derivedEclpParams` via `BalancerV3GyroECLPPoolRepo._initialize(...)` without calling the upstream validations (`GyroECLPMath.validateParams` + `GyroECLPMath.validateDerivedParamsLimits`). `calcSalt()` only does a partial check (`alpha > 0` and `beta > alpha`). This can allow deployment of a pool with inconsistent derived parameters (or invalid `c/s/lambda` constraints), which may later break math assumptions, revert unexpectedly, or create unsafe pricing.
**Status:** Resolved
**Resolution:** Enforced upstream validations in both `calcSalt()` (early deterministic-address revert) and `initAccount()` (deployment-time parity).

### Finding 2: Placeholder interface ids left in Gyro interfaces
**File:** `contracts/interfaces/protocols/dexes/balancer/v3/gyro/IBalancerV3GyroECLPPool.sol`
**Severity:** Low
**Description:** `@custom:interfaceid` is left as `0x00000000 (TBD after implementation)`.
**Status:** Resolved
**Resolution:** Updated to `@custom:interfaceid 0x41c5e491`.

### Finding 3: Placeholder interface ids left in Gyro interfaces
**File:** `contracts/interfaces/protocols/dexes/balancer/v3/gyro/IBalancerV3Gyro2CLPPool.sol`
**Severity:** Low
**Description:** `@custom:interfaceid` is left as `0x00000000 (TBD after implementation)`.
**Status:** Resolved
**Resolution:** Updated to `@custom:interfaceid 0xc9a772b7`.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Add a token-order independence test for Gyro pools
**Priority:** Medium
**Description:** Mirror the existing constant-product pool coverage by asserting that `deployPool(tokenA, tokenB, ...)` and `deployPool(tokenB, tokenA, ...)` resolve to the same `calcAddress` / deployed proxy address (since both `calcSalt()` and `processArgs()` sort token configs). This catches regressions if sorting is removed/changed.
**Affected Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/pool-gyro/eclp/BalancerV3GyroECLPPoolDFPkg_Integration.t.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/pool-gyro/2clp/BalancerV3Gyro2CLPPoolDFPkg_Integration.t.sol`
**User Response:** (pending)
**Notes:** Current tests validate deployment + vault registration, but do not explicitly validate ordering determinism.

### Suggestion 2: Record test + size evidence in this review
**Priority:** Low
**Description:** Keep the exact `forge test` and `forge build --sizes` outputs summarized here so reviewers do not need to re-run locally to confirm acceptance criteria.
**Affected Files:**
- `tasks/CRANE-145-balancer-v3-pool-gyro/REVIEW.md`
**User Response:** (pending)
**Notes:** Added below in Review Summary.

---

## Review Summary

**Findings:** 3 (resolved)
**Suggestions:** 2
**Recommendation:** Approve.

**Evidence:**
- Tests: `forge test --match-path 'test/foundry/spec/protocols/dexes/balancer/v3/pool-gyro/**/*.t.sol'` -> 21 passed, 0 failed
- Sizes: `forge build --sizes`
  - `BalancerV3GyroECLPPoolFacet`: 11,147 B
  - `BalancerV3GyroECLPPoolDFPkg`: 16,258 B
  - `BalancerV3Gyro2CLPPoolFacet`: 5,439 B
  - `BalancerV3Gyro2CLPPoolDFPkg`: 12,568 B

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
