# Task CRANE-044: Add Camelot V2 Asymmetric Fee Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-012
**Worktree:** `test/camelot-asymmetric-fees`
**Origin:** Code review suggestion from CRANE-012

---

## Description

Add tests that verify Camelot V2 behavior when `token0FeePercent != token1FeePercent`. This is Camelot's distinguishing feature (directional fees) and currently has no dedicated test coverage.

(Created from code review of CRANE-012)

## Dependencies

- CRANE-012: Camelot V2 Utilities Review (parent task - complete)

## User Stories

### US-CRANE-044.1: Asymmetric Fee Swap Tests

As a developer, I want tests verifying swap behavior with asymmetric fees so that directional fee logic is proven correct.

**Acceptance Criteria:**
- [ ] Fuzz test for asymmetric fees with varying token0Fee and token1Fee
- [ ] Test both swap directions produce correct outputs
- [ ] Test fee selection based on input token
- [ ] Verify `_sortReservesStruct()` correctly selects fee by direction
- [ ] Tests pass

## Technical Details

**Recommended Fuzz Test:**
```solidity
function testFuzz_asymmetricFees_swapDirection(
    uint16 token0Fee,
    uint16 token1Fee,
    uint256 amountIn
) public {
    vm.assume(token0Fee > 0 && token0Fee <= 2000);
    vm.assume(token1Fee > 0 && token1Fee <= 2000);
    vm.assume(token0Fee != token1Fee);  // Ensure asymmetry
    // Test both swap directions produce correct outputs
}
```

**Test Suite:** Unit + Fuzz

## Files to Create/Modify

**New Files:**
- `test/foundry/protocols/dexes/camelot/v2/CamelotV2_asymmetricFees.t.sol`

**Reference Files:**
- `contracts/protocols/dexes/camelot/v2/CamelotV2Service.sol`
- `test/foundry/protocols/dexes/camelot/v2/mocks/MockCamelotPair.sol`

## Inventory Check

Before starting, verify:
- [ ] MockCamelotPair supports setting asymmetric fees
- [ ] Existing Camelot tests in `test/foundry/protocols/dexes/camelot/v2/`

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
