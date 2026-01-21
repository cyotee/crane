# Task CRANE-133: Make Stable-vs-Volatile Comparison Apples-to-Apples

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-21
**Dependencies:** CRANE-084
**Worktree:** `test/aerodrome-apples-to-apples`
**Origin:** Code review suggestion from CRANE-084

---

## Description

Consider creating both a stable and volatile pool for the same token pair (same token contracts) in the test base, then compare outputs for identical inputs. This will keep the test focused on curve + fee behavior and avoid assumptions about token parity.

Currently the stable-vs-volatile slippage comparison uses different token contracts (stable token A/B vs balanced token A/B). While they share 18 decimals and seeded 1:1 liquidity making the numeric comparison meaningful, using the same token pair for both pool types would make the test intent clearer and reduce the chance of future changes weakening the assertion.

(Created from code review of CRANE-084)

## Dependencies

- CRANE-084: Strengthen Stable-vs-Volatile Slippage Assertion (Complete - parent task)

## User Stories

### US-CRANE-133.1: Same Token Pair for Both Pool Types

As a developer, I want the stable-vs-volatile comparison test to use identical token pairs so that the test focuses purely on curve + fee behavior differences.

**Acceptance Criteria:**
- [ ] TestBase_Aerodrome_Pools creates both stable and volatile pool for the same token pair
- [ ] Slippage comparison test updated to use same tokens for both pool types
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome_Pools.sol
- test/foundry/spec/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-084 is complete
- [ ] TestBase_Aerodrome_Pools.sol exists
- [ ] AerodromServiceStable.t.sol exists with slippage comparison test

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge test --match-path 'test/foundry/spec/protocols/dexes/aerodrome/**/*.t.sol'` passes
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
