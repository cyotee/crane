# Task CRANE-024: Harden Zap-Out Fee-On Input Validation

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-006
**Worktree:** `fix/zapout-fee-validation`
**Origin:** Code review suggestion from CRANE-006

---

## Description

Prevent `ownerFeeShare == 0` from causing a division-by-zero panic inside `_quoteZapOutToTargetWithFee` when `feeOn` is enabled.

The current code path at `ConstProdUtils.sol:530` computes:
```solidity
feeFactor = (args.protocolFeeDenominator / args.ownerFeeShare) - 1;
```

If `args.ownerFeeShare == 0` and `feeOn && kLast != 0`, this will panic. The input validation at lines 514-520 checks `args.ownerFeeShare > args.protocolFeeDenominator` but does not guard against `ownerFeeShare == 0`.

This is a classic "flag says enabled, params say disabled" edge case. Even if current callers never do it, defensive handling is cheap and improves library robustness.

(Created from code review of CRANE-006)

## Dependencies

- CRANE-006: Constant Product & Bonding Math Review (parent task - now archived)

## User Stories

### US-CRANE-024.1: Prevent Division-by-Zero in Zap-Out Fee Calculation

As a developer integrating ConstProdUtils, I want the library to handle `ownerFeeShare == 0` gracefully so that my code doesn't unexpectedly panic when fee parameters are misconfigured.

**Acceptance Criteria:**
- [ ] `_quoteZapOutToTargetWithFee` handles `ownerFeeShare == 0` without reverting
- [ ] When `feeOn == true` and `ownerFeeShare == 0`, treat as "fees disabled" (consistent with `_calculateProtocolFee`)
- [ ] Add unit test asserting no revert for `ownerFeeShare == 0` case
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/utils/math/ConstProdUtils.sol` (add guard in fee branch)

**New Files:**
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_ZapOutFeeValidation.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-006 is complete (archived)
- [ ] Affected file exists: `contracts/utils/math/ConstProdUtils.sol`

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
