# Task CRANE-215: Add End-to-End tokenURI() Shape Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-03
**Dependencies:** CRANE-201 (complete/archived)
**Worktree:** `test/v3-tokenuri-e2e-shape`
**Origin:** Code review suggestion from CRANE-201

---

## Description

Add a test that calls `NonfungibleTokenPositionDescriptor.tokenURI()` with stubbed `INonfungiblePositionManager` + `IUniswapV3Pool` (returning controlled `positions()`, `factory()`, `slot0()`, `tickSpacing()`), then runs the same shape assertions as the existing NFTDescriptor tests.

This directly satisfies the acceptance criterion from CRANE-201 and covers integration wiring that the current `NFTDescriptor.constructTokenURI()` tests miss.

(Created from code review of CRANE-201)

## Dependencies

- CRANE-201: Add V3 NFT tokenURI Shape Test (complete/archived - parent task)

## User Stories

### US-CRANE-215.1: End-to-End tokenURI() Test

As a developer, I want an end-to-end test for `NonfungibleTokenPositionDescriptor.tokenURI()` so that integration wiring issues are caught.

**Acceptance Criteria:**
- [ ] Create stub for `INonfungiblePositionManager` returning controlled `positions()` and `factory()`
- [ ] Create stub for `IUniswapV3Pool` returning controlled `slot0()` and `tickSpacing()`
- [ ] Call `descriptor.tokenURI(stubManager, tokenId)`
- [ ] Assert result starts with `data:application/json;base64,`
- [ ] Assert decoded JSON contains `image` field with SVG prefix
- [ ] Assert decoded SVG has proper `<svg>...</svg>` structure
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v3/periphery/NFTDescriptorTokenURI.t.sol`

**New Files (Optional):**
- Stub contracts if not inlined in test

## Inventory Check

Before starting, verify:
- [ ] CRANE-201 is complete (check tasks/archive/)
- [ ] `NFTDescriptorTokenURI.t.sol` exists
- [ ] `NonfungibleTokenPositionDescriptor` contract exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass: `forge test --match-contract NFTDescriptorTokenURI`
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
