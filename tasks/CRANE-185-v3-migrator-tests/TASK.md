# Task CRANE-185: Add V3Migrator Integration Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-151
**Worktree:** `test/v3-migrator-tests`
**Origin:** Code review suggestion from CRANE-151

---

## Description

Add integration test for V3Migrator that validates migration from Uniswap V2 positions to V3 positions.

(Created from code review of CRANE-151)

## Dependencies

- CRANE-151: Port and Verify Uniswap V3 Core + Periphery (parent task)

## User Stories

### US-CRANE-185.1: Add V3Migrator Integration Test

As a developer, I want V3Migrator tested so that migration functionality is verified.

**Acceptance Criteria:**
- [ ] Set up Uniswap V2 pool with liquidity
- [ ] Test migrate() function
- [ ] Verify V3 position created correctly
- [ ] Verify V2 liquidity removed
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v3/periphery/UniswapV3PeripheryRepo.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-151 is complete
- [ ] V3Migrator.sol exists
- [ ] Uniswap V2 test infrastructure available

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
