# Task CRANE-009: Review — Camelot V2 Utilities

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-camelot-v2-utils`

---

## Description

Review Crane's Camelot V2 utility surfaces for quote correctness, custom fee handling, and test coverage.

## Dependencies

- None

## User Stories

### US-CRANE-009.1: Produce a Camelot V2 Correctness Memo

As a maintainer, I want a clear summary of quote correctness assumptions and edge cases for Camelot V2 integrations so that downstream vault logic can be trusted.

**Acceptance Criteria:**
- [ ] Memo lists key invariants for Camelot V2
- [ ] Memo documents custom fee mechanisms
- [ ] Memo lists missing tests and recommended suites (unit/spec/fuzz)

## Technical Details

**Camelot V2:**
- Custom directional fees (different fees for buy vs sell)
- Fee-on-transfer token handling
- Referral system integration
- Router wrapper correctness
- Quote accuracy vs actual swap
- `CamelotV2Service` library patterns

## Files to Create/Modify

**New Files:**
- `docs/review/camelot-v2-utils.md` - Review memo

**Tests:**
- Optionally add tests if gaps are identified

## Inventory Check

Before starting, verify:
- [ ] Review `contracts/protocols/dexes/camelot/v2/`
- [ ] Review `contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol`
- [ ] Identify all public entrypoints and consumers

## Completion Criteria

- [ ] Memo exists at `docs/review/camelot-v2-utils.md`
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
