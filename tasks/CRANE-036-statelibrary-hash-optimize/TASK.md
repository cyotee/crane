# Task CRANE-036: Optimize StateLibrary Hashing with BetterEfficientHashLib

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-009
**Worktree:** `fix/statelibrary-hash-optimize`
**Origin:** Code review suggestion from CRANE-009 (Suggestion 4)

---

## Description

Replace `keccak256(abi.encodePacked(...))` with `BetterEfficientHashLib` in StateLibrary for gas savings. The existing pattern at lines 177, 182, and 188 of IPoolManager.sol can be optimized.

(Created from code review of CRANE-009)

## Dependencies

- CRANE-009: Uniswap V4 Utilities Review (parent task - completed)

## User Stories

### US-CRANE-036.1: Hash Optimization

As a developer, I want StateLibrary to use efficient hashing so that gas costs are minimized.

**Acceptance Criteria:**
- [ ] Replace `keccak256(abi.encodePacked(...))` at line 177 with BetterEfficientHashLib
- [ ] Replace `keccak256(abi.encodePacked(...))` at line 182 with BetterEfficientHashLib
- [ ] Replace `keccak256(abi.encodePacked(...))` at line 188 with BetterEfficientHashLib
- [ ] Verify output is identical (same hash values)
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol`

**Reference Files:**
- `lib/daosys/lib/crane/lib/solady/src/utils/EfficientHashLib.sol`
- Crane's BetterEfficientHashLib extension

## Inventory Check

Before starting, verify:
- [x] CRANE-009 is complete
- [x] IPoolManager.sol exists with StateLibrary

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test --match-path test/foundry/fork/ethereum_main/uniswapV4/`)
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
