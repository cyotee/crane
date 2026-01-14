# Task CRANE-013: Review — Balancer V3 Utilities

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-balancer-v3-utils`

---

## Description

Review Crane's Balancer V3 utility surfaces for vault integration, pool operations, and test coverage.

## Dependencies

- None

## User Stories

### US-CRANE-013.1: Produce a Balancer V3 Correctness Memo

As a maintainer, I want a clear summary of quote correctness assumptions and edge cases for Balancer V3 integrations so that downstream vault logic can be trusted.

**Acceptance Criteria:**
- [ ] PROGRESS.md lists key invariants for Balancer V3
- [ ] PROGRESS.md documents vault singleton interactions
- [ ] PROGRESS.md documents pool type differences
- [ ] PROGRESS.md lists missing tests and recommended suites (unit/spec/fuzz)

## Technical Details

**Balancer V3 Focus Areas:**
- Vault singleton pattern
- Pool registration and lifecycle
- Weighted pool math
- Composable stable pool math
- Batch swap execution
- Single swap vs multi-hop
- Flash loan integration
- Buffer and liquidity management
- Pool hooks
- Rate providers for yield-bearing tokens
- Swap fee handling

## Files to Create/Modify

**Documentation:**
- Write all review findings, analysis, and recommendations directly in `PROGRESS.md`
- Do NOT create separate memo files in `docs/`

**Tests:**
- Optionally add tests if gaps are identified

## Inventory Check

Before starting, verify:
- [ ] Review `contracts/protocols/dexes/balancer/v3/`
- [ ] Identify vault integration points
- [ ] Identify pool type implementations
- [ ] Identify all public entrypoints and consumers

## Completion Criteria

- [ ] Review findings documented in PROGRESS.md
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
