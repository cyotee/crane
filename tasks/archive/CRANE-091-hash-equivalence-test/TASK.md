# Task CRANE-091: Add BetterEfficientHashLib Hash Equivalence Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-16
**Dependencies:** CRANE-036
**Worktree:** `test/hash-equivalence`
**Origin:** Code review suggestion from CRANE-036 (Suggestion 1)

---

## Description

Add a small unit test that asserts `BetterEfficientHashLib._hash()` produces identical output to `keccak256(abi.encode(...))` for representative values including negative numbers. This makes the "identical output" claim locally provable without relying solely on fork-based integration coverage.

(Created from code review of CRANE-036)

## Dependencies

- CRANE-036: Optimize StateLibrary Hashing (parent task - completed)

## User Stories

### US-CRANE-091.1: Hash Equivalence Unit Test

As a developer, I want a unit test that proves BetterEfficientHashLib produces identical hashes to keccak256(abi.encode()) so that the optimization is verified locally and protected against future refactors.

**Acceptance Criteria:**
- [x] Test covers negative int values (e.g., wordPos = -1, tick = -1)
- [x] Test covers positive int values
- [x] Test covers bytes32 values
- [x] Test asserts `._hash()` == `keccak256(abi.encode(...))` for all cases
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/utils/math/BetterEfficientHashLib_equivalence.t.sol` (or similar)

**Reference Files:**
- `contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol` (StateLibrary usage)
- `contracts/utils/BetterEfficientHashLib.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-036 is complete
- [x] BetterEfficientHashLib.sol exists

## Completion Criteria

- [x] All acceptance criteria met
- [x] Tests pass (`forge test`)
- [x] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
