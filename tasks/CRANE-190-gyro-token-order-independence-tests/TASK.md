# Task CRANE-190: Add Gyro Pool Token-Order Independence Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-31
**Dependencies:** CRANE-145
**Worktree:** `test/gyro-token-order-tests`
**Origin:** Code review suggestion from CRANE-145

---

## Description

Add token-order independence tests for Gyro pools to verify that `deployPool(tokenA, tokenB, ...)` and `deployPool(tokenB, tokenA, ...)` resolve to the same `calcAddress` / deployed proxy address.

Both `calcSalt()` and `processArgs()` sort token configs internally. This test catches regressions if sorting is removed or changed, mirroring the coverage already present for constant-product pools.

(Created from code review of CRANE-145)

## Dependencies

- CRANE-145: Refactor Balancer V3 Gyro Pool Package (parent task, complete)

## User Stories

### US-CRANE-190.1: Token Order Independence for ECLP Pool

As a developer, I want to verify that deploying an ECLP pool with tokens in either order produces the same deterministic address so that users cannot create duplicate pools by swapping token order.

**Acceptance Criteria:**
- [ ] Test deploys ECLP pool with (tokenA, tokenB) and records the address
- [ ] Test calls calcAddress with (tokenB, tokenA) and verifies same address
- [ ] Test attempts deployment with swapped order and verifies same proxy or revert

### US-CRANE-190.2: Token Order Independence for 2CLP Pool

As a developer, I want to verify that deploying a 2CLP pool with tokens in either order produces the same deterministic address.

**Acceptance Criteria:**
- [ ] Test deploys 2CLP pool with (tokenA, tokenB) and records the address
- [ ] Test calls calcAddress with (tokenB, tokenA) and verifies same address
- [ ] Test attempts deployment with swapped order and verifies same proxy or revert

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/pool-gyro/eclp/BalancerV3GyroECLPPoolDFPkg_Integration.t.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/pool-gyro/2clp/BalancerV3Gyro2CLPPoolDFPkg_Integration.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-145 is complete
- [ ] Affected test files exist

## Implementation Notes

1. Follow the existing test pattern in constant-product pool tests
2. Use the same token pair but swap order in second deployment call
3. Assert that `calcAddress(tokenA, tokenB, params) == calcAddress(tokenB, tokenA, params)`
4. If deploying twice with swapped order, expect either:
   - Same address returned (if factory returns existing)
   - Revert with "already deployed" or similar

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass: `forge test --match-path 'test/foundry/spec/protocols/dexes/balancer/v3/pool-gyro/**/*.t.sol'`
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
