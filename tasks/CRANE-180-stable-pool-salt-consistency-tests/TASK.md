# Task CRANE-180: Add Stable Pool DFPkg Salt Consistency Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-144
**Worktree:** `test/stable-pool-salt-consistency`
**Origin:** Code review suggestion from CRANE-144

---

## Description

Mirror the const-prod DFPkg coverage by adding tests for:
1. Token order-independence (including heterogeneous TokenConfig fields)
2. `calcSalt(args) == calcSalt(processArgs(args))` consistency

Current implementation sorts TokenConfig structs, so this is likely already correct; tests reduce regression risk.

(Created from code review of CRANE-144)

## Dependencies

- CRANE-144: Refactor Balancer V3 Stable Pool Package (parent task)

## User Stories

### US-CRANE-180.1: Token Order Independence

As a developer, I want to verify that stable pool deployment salt is order-independent so that pools with the same tokens get deterministic addresses regardless of input order.

**Acceptance Criteria:**
- [ ] Test that `calcSalt([tokenA, tokenB])` equals `calcSalt([tokenB, tokenA])`
- [ ] Test with heterogeneous TokenConfig fields (different rate providers, decimals, etc.)
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-180.2: ProcessArgs Salt Consistency

As a developer, I want to verify that `calcSalt(args) == calcSalt(processArgs(args))` so that salt computation is idempotent.

**Acceptance Criteria:**
- [ ] Test that raw args and processed args produce identical salts
- [ ] Test with various amplification parameter values
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolDFPkg_Salt.t.sol`

**Reference Files:**
- `contracts/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolDFPkg.sol`
- Similar tests for weighted pool DFPkg (if they exist)

## Inventory Check

Before starting, verify:
- [ ] CRANE-144 implementation is complete
- [ ] BalancerV3StablePoolDFPkg.sol exists and compiles

## Completion Criteria

- [ ] Token order-independence tests pass
- [ ] ProcessArgs salt consistency tests pass
- [ ] All existing tests still pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
