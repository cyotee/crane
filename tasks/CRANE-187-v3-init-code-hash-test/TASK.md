# Task CRANE-187: Add POOL_INIT_CODE_HASH Regression Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-151
**Worktree:** `test/v3-init-code-hash-test`
**Origin:** Code review suggestion from CRANE-151 (Second Opinion)

---

## Description

Add a regression test that asserts `PoolAddress.POOL_INIT_CODE_HASH == keccak256(type(UniswapV3Pool).creationCode)`. This ensures future changes to the pool bytecode (compiler updates, source edits) fail loudly rather than silently breaking pool address computation.

(Created from code review of CRANE-151)

## Dependencies

- CRANE-151: Port and Verify Uniswap V3 Core + Periphery (parent task)

## User Stories

### US-CRANE-187.1: Add Init Code Hash Regression Test

As a developer, I want the POOL_INIT_CODE_HASH verified at test time so that bytecode drift is detected immediately.

**Acceptance Criteria:**
- [ ] Test asserts hash constant matches computed hash
- [ ] Clear error message if mismatch
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v3/periphery/UniswapV3PeripheryRepo.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-151 is complete
- [ ] PoolAddress.sol exists with POOL_INIT_CODE_HASH constant

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
