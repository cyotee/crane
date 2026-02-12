# Task CRANE-076: Remove Console Logs from Price Impact Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-15
**Dependencies:** CRANE-028
**Worktree:** `fix/priceimpact-remove-logs`
**Origin:** Code review suggestion from CRANE-028 (Suggestion 2)

---

## Description

Remove `console.log` output from the price impact tests to keep CI output clean and signal-dense.

Several tests emit console logs which can be helpful for debugging but add noise in CI environments. Either remove them entirely or gate them behind a debug pattern used elsewhere in the Crane test suite.

(Created from code review of CRANE-028)

## Dependencies

- CRANE-028: Add Price Impact Tests (parent task - completed)

## User Stories

### US-CRANE-076.1: Clean CI Output

As a developer, I want test output to be clean and signal-dense so that CI logs are easier to read and failures are more visible.

**Acceptance Criteria:**
- [ ] Remove console.log statements from tests, OR
- [ ] Gate logs behind a debug flag/pattern consistent with Crane conventions
- [ ] No functional regression
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_priceImpact.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-028 is complete
- [x] ConstProdUtils_priceImpact.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test --match-path test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_priceImpact.t.sol`)
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
