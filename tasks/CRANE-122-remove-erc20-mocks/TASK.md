# Task CRANE-122: Remove Unnecessary ERC20 Metadata Mocks

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-062
**Worktree:** `feature/remove-erc20-mocks`
**Origin:** Code review suggestion from CRANE-062 (Suggestion 2)

---

## Description

Remove `vm.mockCall(... IERC20Metadata.name ...)` in the heterogeneous fuzz tests. These mocks appear unnecessary for `calcSalt`/`processArgs` since those paths do not call token metadata. Removing them would slightly simplify the tests.

Note: If future implementations start reading metadata in these functions, keeping the mocks would be harmless.

(Created from code review of CRANE-062)

## Dependencies

- CRANE-062: Add Heterogeneous TokenConfig Order-Independence Tests (parent task)

## User Stories

### US-CRANE-122.1: Remove unused mock calls

As a developer, I want tests to only mock what's necessary so that test code is cleaner and more maintainable.

**Acceptance Criteria:**
- [ ] Remove unnecessary ERC20 metadata mocks from heterogeneous fuzz tests
- [ ] Verify tests still pass without the mocks
- [ ] Tests pass

## Files to Create/Modify

**Modified Test Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-062 is complete
- [ ] ERC20 metadata mocks exist in fuzz tests

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
