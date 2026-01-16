# Task CRANE-035: Document Uniswap V4 Dynamic Fee Pool Limitations

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-009
**Worktree:** `fix/v4-dynamic-fee-docs`
**Origin:** Code review suggestion from CRANE-009 (Suggestion 3)

---

## Description

Add user-facing documentation noting that quotes for pools with `FEE_DYNAMIC` flag may differ from actual swap results since hooks can modify fees dynamically.

(Created from code review of CRANE-009)

## Dependencies

- CRANE-009: Uniswap V4 Utilities Review (parent task - completed)

## User Stories

### US-CRANE-035.1: Dynamic Fee Documentation

As a developer using the V4 quoter, I want clear documentation about dynamic fee limitations so that I understand when quotes may differ from actual execution.

**Acceptance Criteria:**
- [ ] NatSpec `@notice` on `UniswapV4Quoter.sol` main functions noting dynamic fee limitation
- [ ] NatSpec `@dev` explaining that FEE_DYNAMIC flag means hooks can modify fees
- [ ] Similar documentation on `UniswapV4ZapQuoter.sol`
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/uniswap/v4/utils/UniswapV4Quoter.sol`
- `contracts/protocols/dexes/uniswap/v4/utils/UniswapV4ZapQuoter.sol`

**Reference Files:**
- CRANE-009 PROGRESS.md Section 3.2 (contains dynamic fee discussion)

## Inventory Check

Before starting, verify:
- [x] CRANE-009 is complete
- [x] UniswapV4Quoter.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
