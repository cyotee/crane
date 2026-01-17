# Task CRANE-047: Add Fee-on-Transfer Token Integration Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-012
**Worktree:** `test/camelot-fot-integration`
**Origin:** Code review suggestion from CRANE-012

---

## Description

Add tests with actual fee-on-transfer token stubs to verify quote accuracy and router behavior. Current quote functions assume standard ERC20 behavior and will overestimate output for FoT tokens.

(Created from code review of CRANE-012)

## Dependencies

- CRANE-012: Camelot V2 Utilities Review (parent task - complete)

## User Stories

### US-CRANE-047.1: Fee-on-Transfer Integration Tests

As a developer, I want tests with FoT token stubs so that quote deviation is documented and router compatibility is verified.

**Acceptance Criteria:**
- [ ] Create FeeOnTransferToken mock with configurable transfer tax
- [ ] Test `_saleQuote()` overestimation with FoT tokens
- [ ] Test `_purchaseQuote()` underestimation with FoT tokens
- [ ] Test `swapExactTokensForTokensSupportingFeeOnTransferTokens()` behavior
- [ ] Document expected quote deviation for various tax rates
- [ ] Tests pass

## Technical Details

**Fee-on-Transfer Mock:**
```solidity
contract FeeOnTransferToken is ERC20 {
    uint256 public transferTax = 500; // 5%

    function _transfer(address from, address to, uint256 amount) internal override {
        uint256 tax = amount * transferTax / 10000;
        super._transfer(from, to, amount - tax);
    }
}
```

**Test Suite:** Integration + Fuzz

## Files to Create/Modify

**New Files:**
- `test/foundry/protocols/dexes/camelot/v2/mocks/FeeOnTransferToken.sol`
- `test/foundry/protocols/dexes/camelot/v2/CamelotV2_feeOnTransfer.t.sol`

**Reference Files:**
- `contracts/protocols/dexes/camelot/v2/CamelotV2Service.sol`
- `contracts/protocols/dexes/common/ConstProdUtils.sol`

## Inventory Check

Before starting, verify:
- [ ] Router `swapExactTokensForTokensSupportingFeeOnTransferTokens` exists
- [ ] Existing FoT handling patterns

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
