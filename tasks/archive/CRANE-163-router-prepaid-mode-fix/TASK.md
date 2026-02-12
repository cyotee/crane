# Task CRANE-163: Fix Prepaid Router Mode for Permit2-less Operations

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-29
**Dependencies:** CRANE-142
**Worktree:** `fix/router-prepaid-mode`
**Origin:** Code review finding 3 from CRANE-142

---

## Description

Fix the prepaid router mode that currently breaks for several operations due to unconditional Permit2 calls.

**Problem:**
`_takeTokenIn(...)` in `BalancerV3RouterModifiers.sol` unconditionally calls `permit2.transferFrom(...)` for non-WETH inputs. For prepaid routers where `permit2 == address(0)`, this will revert.

**Affected Functions:**
- `BufferRouterFacet.initializeBufferHook`
- `BufferRouterFacet.addLiquidityToBufferHook`
- Parts of composite ERC4626 flows

Some facets handle prepaid settlement explicitly (e.g., batch/composite settle paths), but others directly call `_takeTokenIn()`, making those functions unusable in prepaid mode.

**Solution:**
Extend `_takeTokenIn()` to check `_isPrepaid()` and use `vault.settle()` directly without Permit2 transfer when in prepaid mode.

(Created from code review of CRANE-142)

## Dependencies

- CRANE-142: Refactor Balancer V3 Router as Diamond Facets (parent task) - Complete

## User Stories

### US-CRANE-163.1: Fix _takeTokenIn for Prepaid Mode

As a developer, I want `_takeTokenIn()` to work in prepaid mode so that all router operations function correctly regardless of settlement mode.

**Acceptance Criteria:**
- [ ] `_takeTokenIn()` checks `_isPrepaid()` before calling Permit2
- [ ] In prepaid mode, uses `vault.settle()` directly
- [ ] All affected facet functions work in prepaid mode
- [ ] Tests pass for both prepaid and standard modes
- [ ] Build succeeds

### US-CRANE-163.2: Add Prepaid Mode Tests

As a developer, I want tests validating prepaid mode so that the fix is verified.

**Acceptance Criteria:**
- [ ] Test `BufferRouterFacet.initializeBufferHook` in prepaid mode
- [ ] Test `BufferRouterFacet.addLiquidityToBufferHook` in prepaid mode
- [ ] Test composite ERC4626 flows in prepaid mode
- [ ] Tests pass

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterModifiers.sol`

**New Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/PrepaidMode.t.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-142 is complete
- [ ] Understand current `_takeTokenIn()` implementation
- [ ] Understand `_isPrepaid()` check mechanism

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Prepaid mode works for all router operations
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
