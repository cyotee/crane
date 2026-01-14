# Task CRANE-012: Review — Camelot V2 Utilities

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-camelot-v2-utils`

---

## Description

Review Crane's Camelot V2 utility surfaces for custom fee handling, directional fees, and test coverage.

## Dependencies

- None

## User Stories

### US-CRANE-012.1: Produce a Camelot V2 Correctness Memo

As a maintainer, I want a clear summary of quote correctness assumptions and edge cases for Camelot V2 integrations so that downstream vault logic can be trusted.

**Acceptance Criteria:**
- [ ] PROGRESS.md lists key invariants for Camelot V2
- [ ] PROGRESS.md documents directional fee mechanisms
- [ ] PROGRESS.md documents fee-on-transfer token handling
- [ ] PROGRESS.md lists missing tests and recommended suites (unit/spec/fuzz)

## Technical Details

**Camelot V2 Focus Areas:**
- Directional fees (different fees for buy vs sell)
- Dynamic fee calculation
- Fee-on-transfer token compatibility
- Referral system integration
- Router wrapper correctness (`CamelotV2Service`)
- Quote accuracy vs actual swap execution
- Pair factory interactions
- Stable pair support (if applicable)

## Files to Create/Modify

**Documentation:**
- Write all review findings, analysis, and recommendations directly in `PROGRESS.md`
- Do NOT create separate memo files in `docs/`

**Tests:**
- Optionally add tests if gaps are identified

## Inventory Check

Before starting, verify:
- [ ] Review `contracts/protocols/dexes/camelot/v2/`
- [ ] Review `contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol`
- [ ] Identify directional fee handling
- [ ] Identify all public entrypoints and consumers

## Completion Criteria

- [ ] Review findings documented in PROGRESS.md
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
