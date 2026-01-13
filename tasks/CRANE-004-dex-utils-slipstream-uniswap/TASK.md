# Task CRANE-004: Review — DEX Utilities (Slipstream + Uniswap)

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-12
**Dependencies:** None
**Worktree:** `review/crn-dex-utils-slipstream-uniswap`

---

## Description

Review Crane's DEX utility surfaces used by IndexedEx vaults (Slipstream/Aerodrome, Uniswap V2/V3/V4). Focus on quote correctness, rounding, revert expectations, and test coverage.

## Dependencies

- None

## User Stories

### US-CRANE-004.1: Produce a DEX Utilities Correctness Memo

As a maintainer, I want a clear summary of quote correctness assumptions and edge cases so that downstream vault logic can be trusted.

**Acceptance Criteria:**
- [ ] Memo lists key invariants and edge cases per DEX
- [ ] Memo lists missing tests and recommended suites (unit/spec/fuzz)
- [ ] Memo documents rounding behavior and slippage assumptions

## Technical Details

Focus areas by protocol:

**Uniswap V2:**
- Quote calculations in `ConstProdUtils`
- Fee handling (0.3% standard, custom fees)
- Reserve-based pricing accuracy

**Uniswap V3/V4:**
- Concentrated liquidity quote accuracy
- Tick math and price impact
- Multi-hop routing

**Aerodrome/Slipstream:**
- Concentrated liquidity specifics
- Gauge integration (if applicable)
- Fee tier handling

**Camelot V2:**
- Custom fee mechanisms
- Quote accuracy vs actual swap

## Files to Create/Modify

**New Files:**
- `docs/review/dex-utils.md` - Review memo

**Tests:**
- Optionally add tests if gaps are identified

## Inventory Check

Before starting, verify:
- [ ] Review `contracts/protocols/dexes/uniswap/v2/`
- [ ] Review `contracts/protocols/dexes/uniswap/v3/` (if exists)
- [ ] Review `contracts/protocols/dexes/uniswap/v4/` (if exists)
- [ ] Review `contracts/protocols/dexes/aerodrome/v1/`
- [ ] Review `contracts/protocols/dexes/camelot/v2/`
- [ ] Review `contracts/utils/math/ConstProdUtils.sol`

## Completion Criteria

- [ ] Memo exists at `docs/review/dex-utils.md`
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
