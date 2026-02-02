# Task CRANE-183: Refactor V3 NFT Metadata to Fix Stack-Too-Deep

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-30
**Completed:** 2026-02-01
**Dependencies:** CRANE-151
**Worktree:** `fix/v3-nft-metadata-refactor`
**Origin:** Code review suggestion from CRANE-151

---

## Description

Refactor NFTDescriptor.sol to fix "stack too deep" compilation error without enabling viaIR (which is forbidden in this repo). Re-enable the three disabled NFT metadata files.

(Created from code review of CRANE-151)

## Dependencies

- CRANE-151: Port and Verify Uniswap V3 Core + Periphery (parent task)

## User Stories

### US-CRANE-183.1: Refactor NFTDescriptor for Stack Depth

As a developer, I want NFTDescriptor.sol to compile without viaIR so that NFT positions can return proper tokenURI metadata.

**Acceptance Criteria:**
- [x] NFTDescriptor.sol compiles without viaIR
- [x] Refactored to use structs/helpers to reduce stack depth
- [x] NFTSVG.sol re-enabled
- [x] NonfungibleTokenPositionDescriptor.sol re-enabled
- [x] tokenURI returns valid SVG data
- [x] Tests pass (2148 passed, 7 pre-existing failures unrelated to NFT metadata)
- [x] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/uniswap/v3/periphery/libraries/NFTDescriptor.sol.disabled` → `.sol` ✅
- `contracts/protocols/dexes/uniswap/v3/periphery/libraries/NFTSVG.sol.disabled` → `.sol` ✅
- `contracts/protocols/dexes/uniswap/v3/periphery/NonfungibleTokenPositionDescriptor.sol.disabled` → `.sol` ✅

## Inventory Check

Before starting, verify:
- [x] CRANE-151 is complete
- [x] Disabled files exist

## Completion Criteria

- [x] All acceptance criteria met
- [x] Tests pass
- [x] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
