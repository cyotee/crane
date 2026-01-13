# Task CRANE-025: Replace Fee-Denominator Heuristic with Explicit Parameter

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-006
**Worktree:** `fix/explicit-fee-denominator`
**Origin:** Code review suggestion from CRANE-006

---

## Description

`_quoteSwapDepositWithFee` infers fee denominator using a heuristic:
```solidity
feePercent <= 10 ? 1000 : 100_000
```

This is a reasonable heuristic, but it can misclassify low modern fees (e.g., 10/100000 = 0.01%) as legacy (10/1000 = 1%).

Options:
1. Add an overload that takes `feeDenominator` as an explicit parameter
2. Document the heuristic behavior and edge cases clearly
3. Make the heuristic opt-in via a flag

(Created from code review of CRANE-006)

## Dependencies

- CRANE-006: Constant Product & Bonding Math Review (parent task - now archived)

## User Stories

### US-CRANE-025.1: Explicit Fee Denominator Support

As a developer integrating with modern DEXes, I want to specify the fee denominator explicitly so that low-percentage fees (like 0.01%) are calculated correctly.

**Acceptance Criteria:**
- [ ] Add `_quoteSwapDepositWithFee` overload accepting explicit `feeDenominator`
- [ ] Existing API preserved for backward compatibility
- [ ] Document heuristic edge cases in code comments
- [ ] Add test cases for boundary conditions (feePercent = 10)
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/utils/math/ConstProdUtils.sol` (add overload)
- Any call sites currently passing feePercent without denom (audit needed)

**New Files:**
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_FeeDenominator.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-006 is complete (archived)
- [ ] Affected file exists: `contracts/utils/math/ConstProdUtils.sol`
- [ ] Identify all call sites using the heuristic

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
