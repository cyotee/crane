# Task CRANE-008: Review — Uniswap V3 Utilities

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-uniswap-v3-utils`

---

## Description

Review Crane's Uniswap V3 utility surfaces for concentrated liquidity quote accuracy, tick math correctness, and test coverage.

## Dependencies

- None

## User Stories

### US-CRANE-008.1: Produce a Uniswap V3 Correctness Memo

As a maintainer, I want a clear summary of quote correctness assumptions and edge cases for Uniswap V3 integrations so that downstream vault logic can be trusted.

**Acceptance Criteria:**
- [ ] Memo lists key invariants for Uniswap V3
- [ ] Memo documents concentrated liquidity handling
- [ ] Memo documents tick math and sqrtPriceX96
- [ ] Memo lists missing tests and recommended suites (unit/spec/fuzz)

## Technical Details

**Uniswap V3 Focus Areas:**
- Concentrated liquidity mechanics
- Tick spacing and tick math
- sqrtPriceX96 representation and conversions
- Fee tiers (0.01%, 0.05%, 0.3%, 1%)
- Position management (mint, burn, collect)
- Price impact across tick boundaries
- Multi-hop routing through different fee tiers
- Oracle (TWAP) integration if present

## Files to Create/Modify

**New Files:**
- `docs/review/uniswap-v3-utils.md` - Review memo

**Tests:**
- Optionally add tests if gaps are identified

## Inventory Check

Before starting, verify:
- [ ] Review `contracts/protocols/dexes/uniswap/v3/`
- [ ] Identify quoter and router integrations
- [ ] Identify tick math utilities
- [ ] Identify all public entrypoints and consumers

## Completion Criteria

- [ ] Memo exists at `docs/review/uniswap-v3-utils.md`
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
