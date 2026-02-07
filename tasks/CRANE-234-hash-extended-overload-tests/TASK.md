# Task CRANE-234: Add BetterEfficientHashLib Extended Overload Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-06
**Dependencies:** CRANE-091
**Worktree:** `test/hash-extended-overloads`
**Origin:** Code review suggestion from CRANE-091 (Suggestion 2)

---

## Description

Extend BetterEfficientHashLib equivalence test coverage to include 5-14 argument overloads (both `bytes32` and `uint256`), plus utility functions: `_set`, `_malloc`, `_free`, `_eq`, slice hashing (`_hash(bytes,uint256,uint256)`), calldata hashing (`_hashCalldata`), and SHA-256 helpers (`_sha2`).

While the existing 1-4 arg tests prove the assembly pattern is correct, explicit coverage of higher-arity overloads provides stronger regression protection if the library is ever modified.

(Created from code review of CRANE-091)

## Dependencies

- CRANE-091: Add BetterEfficientHashLib Hash Equivalence Test (parent task - completed)

## User Stories

### US-CRANE-234.1: Extended Overload Equivalence Tests

As a developer, I want equivalence tests for all BetterEfficientHashLib overloads so that every function variant is regression-protected.

**Acceptance Criteria:**
- [ ] Add tests for 5-arg through 8-arg overloads (at minimum)
- [ ] Add tests for `_eq` function
- [ ] Add tests for slice hashing `_hash(bytes,uint256,uint256)`
- [ ] All new tests assert equivalence with `keccak256(abi.encode(...))`
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/utils/BetterEfficientHashLib_equivalence.t.sol`

**Reference Files:**
- `contracts/utils/BetterEfficientHashLib.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-091 is complete
- [x] BetterEfficientHashLib_equivalence.t.sol exists
- [x] BetterEfficientHashLib.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test`)
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
