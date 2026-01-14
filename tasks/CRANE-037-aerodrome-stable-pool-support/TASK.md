# Task CRANE-037: Add Aerodrome Stable Pool Support

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-010
**Worktree:** `feature/aerodrome-stable-pool`
**Origin:** Code review suggestion from CRANE-010 (Suggestion 1)

---

## Description

Extend `AerodromService` to support stable pools by parameterizing the `stable` flag. Currently the service hardcodes `stable: false`, making it incompatible with stable pools despite stubs supporting both pool types.

Stable pools use the `x³y + xy³ = k` curve (as opposed to volatile pools which use `xy = k`).

(Created from code review of CRANE-010)

## Dependencies

- CRANE-010: Aerodrome V1 Utilities Review (parent task - completed)

## User Stories

### US-CRANE-037.1: Stable Pool Support

As a developer, I want AerodromService to support stable pools so that I can integrate with Aerodrome's full pool ecosystem.

**Acceptance Criteria:**
- [ ] `AerodromService` accepts a `stable` parameter instead of hardcoding `false`
- [ ] Swap functions correctly route to stable vs volatile pools
- [ ] Quote functions account for stable pool curve math
- [ ] Existing volatile pool tests continue to pass
- [ ] New tests for stable pool swaps
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/aerodrome/v1/services/AerodromService.sol`

**New Files:**
- `test/foundry/spec/protocols/dexes/aerodrome/v1/AerodromService_StablePools.t.sol`

**Reference Files:**
- Aerodrome stable pool stub
- CRANE-010 PROGRESS.md (documents stable pool curve)

## Inventory Check

Before starting, verify:
- [x] CRANE-010 is complete
- [x] AerodromService.sol exists
- [x] Stable pool stubs exist

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass (`forge test --match-path test/foundry/spec/protocols/dexes/aerodrome/`)
- [ ] Build succeeds (`forge build`)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
