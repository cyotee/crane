# Task CRANE-268: Add Prepaid Mode Tests for Router

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-163
**Worktree:** `test/CRANE-268-prepaid-mode-router-tests`
**Origin:** Code review suggestion from CRANE-163

---

## Description

Create dedicated prepaid mode tests that exercise the `_takeTokenIn()` prepaid branch added in CRANE-163. The fix embedded an `_isPrepaid()` check inside `_takeTokenIn()` so that in prepaid mode, `vault.settle()` is called directly instead of invoking Permit2. The existing 32 router tests validate package deployment and IFacet compliance but do not exercise the actual prepaid settle path.

(Created from code review of CRANE-163)

## Dependencies

- CRANE-163: Fix Prepaid Router Mode for Permit2-less Operations (parent task)

## User Stories

### US-CRANE-268.1: Prepaid Mode Test Coverage

As a developer, I want dedicated tests for prepaid router mode so that the `_takeTokenIn()` prepaid settle path is verified.

**Acceptance Criteria:**
- [ ] Create `PrepaidMode.t.sol` in `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/`
- [ ] Deploy router via DFPkg with `IPermit2(address(0))`
- [ ] Verify `_isPrepaid()` returns true when permit2 is address(0)
- [ ] Test `BufferRouterFacet.initializeBufferHook` -- mock vault and verify `settle()` is called
- [ ] Test `BufferRouterFacet.addLiquidityToBufferHook` -- same pattern
- [ ] Test `CompositeLiquidityERC4626Facet._processTokenInExactIn` path
- [ ] Test `CompositeLiquidityERC4626Facet._processTokenInExactOut` path with refund
- [ ] Negative test: verify no `permit2.transferFrom` call is attempted in prepaid mode
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/PrepaidMode.t.sol`

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/router/diamond/TestBase_BalancerV3Router.sol` (may need prepaid setup helper)

## Inventory Check

Before starting, verify:
- [ ] CRANE-163 is complete
- [ ] `BalancerV3RouterModifiers.sol` contains the `_isPrepaid()` check in `_takeTokenIn()`
- [ ] `TestBase_BalancerV3Router.sol` exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
