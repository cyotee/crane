# Task CRANE-011: Review — Slipstream Utilities

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-slipstream-utils`

---

## Description

Review Crane's Slipstream (Aerodrome's concentrated liquidity product) utility surfaces for tick-based liquidity handling, quote accuracy, and test coverage.

## Dependencies

- None

## User Stories

### US-CRANE-011.1: Produce a Slipstream Correctness Memo

As a maintainer, I want a clear summary of quote correctness assumptions and edge cases for Slipstream integrations so that downstream vault logic can be trusted.

**Acceptance Criteria:**
- [ ] Memo lists key invariants for Slipstream
- [ ] Memo documents concentrated liquidity mechanics
- [ ] Memo documents differences from Uniswap V3
- [ ] Memo lists missing tests and recommended suites (unit/spec/fuzz)

## Technical Details

**Slipstream Focus Areas:**
- Concentrated liquidity (similar to Uniswap V3)
- Tick spacing configurations
- sqrtPriceX96 handling
- Position management (mint, burn, collect)
- Fee tier structure
- Gauge integration for emissions
- Price range handling
- Differences from upstream Uniswap V3 implementation
- NFT position manager integration

## Files to Create/Modify

**New Files:**
- `docs/review/slipstream-utils.md` - Review memo

**Tests:**
- Optionally add tests if gaps are identified

## Inventory Check

Before starting, verify:
- [ ] Review `contracts/protocols/dexes/aerodrome/slipstream/`
- [ ] Compare with Uniswap V3 implementation for deviations
- [ ] Identify all public entrypoints and consumers

## Completion Criteria

- [ ] Memo exists at `docs/review/slipstream-utils.md`
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
