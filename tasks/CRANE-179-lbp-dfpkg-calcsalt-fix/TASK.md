# Task CRANE-179: Fix LBP DFPkg calcSalt Address Collisions

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-143
**Worktree:** `fix/lbp-dfpkg-calcsalt`
**Origin:** Code review second opinion finding from CRANE-143

---

## Description

**PRIORITY: HIGH**

Fix the `calcSalt()` function in `BalancerV3LBPoolDFPkg` to include all configuration parameters that affect pool behavior. Currently, the salt only includes:
- token0, token1
- projectTokenStartWeight, projectTokenEndWeight
- startTime, endTime

Missing from salt (causes address collisions):
- hooksContract
- blockProjectTokenSwapsIn
- reserveTokenVirtualBalance

This means deployments that differ only by these omitted fields will deterministically collide to the same address.

(Created from code review of CRANE-143 - Second Opinion Finding 1)

## Dependencies

- CRANE-143: Refactor Balancer V3 Weighted Pool Package (parent task)

## User Stories

### US-CRANE-179.1: Fix calcSalt Function

As a deployer, I want LBP addresses to be unique per configuration so that I can deploy multiple LBPs with different settings.

**Acceptance Criteria:**
- [ ] Add `hooksContract` to salt calculation
- [ ] Add `blockProjectTokenSwapsIn` to salt calculation
- [ ] Add `reserveTokenVirtualBalance` to salt calculation
- [ ] Add test verifying different configs produce different addresses
- [ ] Add test verifying same configs produce same address
- [ ] Tests pass
- [ ] Build succeeds

### US-CRANE-179.2: Additional Validation (Optional)

Address other findings from second opinion review:

**Acceptance Criteria:**
- [ ] Validate `decimals <= 18` in initAccount (or handle >18 decimals)
- [ ] Remove or use `InvalidTokenCount` and `InvalidWeights` errors
- [ ] Fix or document `WeightedTokenConfigUtils` mutation behavior

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/pool-weighted/lbp/BalancerV3LBPoolDFPkg.sol`
- `test/foundry/spec/protocols/dexes/balancer/v3/pool-weighted/lbp/BalancerV3LBPoolDFPkg.t.sol`

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
