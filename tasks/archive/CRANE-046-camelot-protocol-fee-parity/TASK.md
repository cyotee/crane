# Task CRANE-046: Add Protocol Fee Mint Parity Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-012
**Worktree:** `test/camelot-protocol-fee-parity`
**Origin:** Code review suggestion from CRANE-012

---

## Description

Add edge case tests for `_calculateProtocolFee()` to ensure parity with CamelotPair's `_mintFee()`. Currently limited testing of edge cases like kLast=0, rootK==rootKLast, and ownerFeeShare boundaries.

(Created from code review of CRANE-012)

## Dependencies

- CRANE-012: Camelot V2 Utilities Review (parent task - complete)

## User Stories

### US-CRANE-046.1: Protocol Fee Edge Case Tests

As a developer, I want tests for protocol fee edge cases so that fee calculation parity is verified.

**Acceptance Criteria:**
- [ ] Test `kLast == 0` case (no protocol fee)
- [ ] Test `rootK == rootKLast` case (no fee)
- [ ] Test `ownerFeeShare` boundary values (0, 50000, 100000)
- [ ] Cross-reference with actual pair `_mintFee()` output
- [ ] Property-based tests for fee invariants
- [ ] Tests pass

## Technical Details

**Protocol Fee Formula:**
```solidity
d = (FEE_DENOMINATOR * 100 / ownerFeeShare) - 100
liquidity = totalSupply * (rootK - rootKLast) * 100 / (rootK * d + rootKLast * 100)
```

**Test Suite:** Unit + Property-Based

## Files to Create/Modify

**New Files:**
- `test/foundry/protocols/dexes/camelot/v2/CamelotV2_protocolFeeParity.t.sol`

**Reference Files:**
- `contracts/protocols/dexes/common/ConstProdUtils.sol` (lines 706-746)
- `contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol` (lines 155-189)

## Inventory Check

Before starting, verify:
- [ ] `_calculateProtocolFee()` in ConstProdUtils
- [ ] `_mintFee()` in CamelotPair stub
- [ ] Existing protocol fee tests

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
