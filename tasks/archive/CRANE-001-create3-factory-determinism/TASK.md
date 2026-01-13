# Task CRANE-001: Review — CREATE3 Factory and Deterministic Deployment Correctness

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-create3-factory-and-determinism`

---

## Description

Review Crane's CREATE3 factory stack and deterministic deployment helpers for correctness and adequate coverage. The goal is to raise confidence in the deployment guarantees that IndexedEx depends on.

## Dependencies

- None

## User Stories

### US-CRANE-001.1: Produce a Determinism Review Memo

As a maintainer, I want a clear description of determinism invariants and failure modes so that downstream deployments are trustworthy.

**Acceptance Criteria:**
- [ ] Memo explains salt derivation/normalization rules
- [ ] Memo identifies replay/idempotency assumptions
- [ ] Memo lists collision/address reuse behaviors

### US-CRANE-001.2: Add at Least One Missing Negative Test

As a maintainer, I want at least one concrete test that fails when determinism invariants are violated so that regressions are caught.

**Acceptance Criteria:**
- [ ] Add at least one negative test (revert/edge case) related to deployment determinism
- [ ] `forge test` passes

## Technical Details

Focus areas:
- Salt derivation from type names: `abi.encode(type(X).name)._hash()`
- CREATE3 address calculation and cross-chain consistency
- Facet and package registry behavior
- Replay protection and idempotency

## Files to Create/Modify

**New Files:**
- `docs/review/create3-and-determinism.md` - Review memo + test gap list

**Potentially Modified Files:**
- `test/foundry/**` - Add/strengthen tests around CREATE3 deployment

**Tests:**
- Add at least one negative test for determinism violation

## Inventory Check

Before starting, verify:
- [ ] Identify CREATE3 factory entrypoints under `contracts/factories/create3/**`
- [ ] Identify any helper libraries used by downstream scripts

## Completion Criteria

- [ ] Memo exists at `docs/review/create3-and-determinism.md`
- [ ] At least one meaningful test improvement included
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
