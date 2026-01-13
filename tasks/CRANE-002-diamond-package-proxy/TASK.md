# Task CRANE-002: Review — Diamond Package and Proxy Architecture Correctness

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-diamond-package-and-proxy-correctness`

---

## Description

Review the Diamond package factories, callback wiring, and proxy mechanisms for correctness and adequate coverage, focusing on selector registration and upgrade/initialization safety.

## Dependencies

- None

## User Stories

### US-CRANE-002.1: Produce an Architecture + Risk Memo

As a maintainer, I want a clear description of the Diamond wiring invariants so that downstream packages/proxies remain safe.

**Acceptance Criteria:**
- [ ] Memo identifies selector collision risks and protections
- [ ] Memo documents initialization/post-deploy hooks and invariants
- [ ] Memo describes the callback flow between factory and proxy

## Technical Details

Focus areas:
- `DiamondPackageCallBackFactory` deployment flow
- `MinimalDiamondCallBackProxy` callback mechanism
- Selector registration and collision detection
- `initAccount()` delegatecall safety
- `postDeploy()` hook execution order

## Files to Create/Modify

**New Files:**
- `docs/review/diamond-package-and-proxy.md` - Review memo

**Tests:**
- Optionally add tests if gaps are identified

## Inventory Check

Before starting, verify:
- [ ] Review `contracts/factories/diamondPkg/**`
- [ ] Review `contracts/proxies/**`
- [ ] Review `contracts/interfaces/IDiamondFactoryPackage.sol` for deployment flow diagram

## Completion Criteria

- [ ] Memo exists at `docs/review/diamond-package-and-proxy.md`
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
