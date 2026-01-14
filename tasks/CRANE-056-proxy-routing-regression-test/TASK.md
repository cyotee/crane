# Task CRANE-056: Add Proxy-Level Routing Regression Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-14
**Dependencies:** CRANE-014
**Worktree:** `test/proxy-routing-regression`
**Origin:** Code review suggestion from CRANE-014

---

## Description

Add a test that exercises `MinimalDiamondCallBackProxy` fallback behavior after selector removal, expecting revert `Proxy.NoTargetFor(selector)`. This directly covers the acceptance criterion that removed selectors are unroutable at the proxy layer.

Current tests validate `facetAddress(selector) == address(0)` after removal, which is necessary but doesn't exercise the full proxy routing path.

(Created from code review of CRANE-014)

## Dependencies

- CRANE-014: Fix ERC2535 Remove/Replace Correctness (parent task)

## User Stories

### US-CRANE-056.1: Verify proxy routing after selector removal

As a developer, I want a test that verifies calls to removed selectors revert at the proxy layer so that I can be confident the full routing path is tested.

**Acceptance Criteria:**
- [ ] Test removes a facet's selector via diamondCut
- [ ] Test calls the removed selector through the proxy
- [ ] Test expects revert with `Proxy.NoTargetFor(selector)` error
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**New/Modified Test Files:**
- test/foundry/spec/introspection/ERC2535/DiamondCut.t.sol (or new proxy-focused test)

**Reference Files:**
- contracts/proxies/Proxy.sol (for expected error selector)

## Inventory Check

Before starting, verify:
- [ ] CRANE-014 is complete
- [ ] MinimalDiamondCallBackProxy exists
- [ ] Proxy.NoTargetFor error is defined

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Proxy routing test added
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
