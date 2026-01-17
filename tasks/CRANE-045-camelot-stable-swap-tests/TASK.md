# Task CRANE-045: Add Camelot V2 Stable Swap Pool Tests

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-13
**Completed:** 2026-01-16
**Dependencies:** CRANE-012
**Worktree:** `test/camelot-stable-swap`
**Origin:** Code review suggestion from CRANE-012

---

## Description

Add tests for CamelotPair.stableSwap mode which uses a cubic invariant (`x^3*y + y^3*x >= k`) instead of constant product. This includes testing Newton-Raphson convergence in `_get_y()`.

(Created from code review of CRANE-012)

## Dependencies

- CRANE-012: Camelot V2 Utilities Review (parent task - complete)

## User Stories

### US-CRANE-045.1: Stable Pool Invariant Tests

As a developer, I want tests verifying the cubic invariant is preserved so that stable swap math is proven correct.

**Acceptance Criteria:**
- [x] Test cubic invariant: `x^3*y + y^3*x >= k`
- [x] Test `_k()` calculation for stable pools
- [x] Test `_get_y()` Newton-Raphson convergence
- [x] Test swap output accuracy for stable pairs
- [x] Invariant fuzz test for K preservation
- [x] Tests pass

## Technical Details

**Cubic Invariant Formula:**
```solidity
function _k(uint256 balance0, uint256 balance1) internal view returns (uint256) {
    if (stableSwap) {
        uint256 _x = balance0.mul(1e18) / precisionMultiplier0;
        uint256 _y = balance1.mul(1e18) / precisionMultiplier1;
        uint256 _a = (_x.mul(_y)) / 1e18;
        uint256 _b = (_x.mul(_x) / 1e18).add(_y.mul(_y) / 1e18);
        return _a.mul(_b) / 1e18;  // x^3*y + y^3*x
    }
    return balance0.mul(balance1);
}
```

**Test Suite:** Unit + Invariant Fuzz

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/protocols/dexes/camelot/v2/CamelotV2_stableSwap.t.sol`

**Reference Files:**
- `contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol`

## Inventory Check

Before starting, verify:
- [x] CamelotPair.stableSwap mode exists
- [x] MockCamelotPair can simulate stable pool
- [x] `_get_y()` function implementation

## Completion Criteria

- [x] All acceptance criteria met
- [x] `forge build` passes
- [x] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
