# Task CRANE-183: Refactor V3 NFT Metadata to Fix Stack-Too-Deep

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
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
- [ ] NFTDescriptor.sol compiles without viaIR
- [ ] Refactored to use structs/helpers to reduce stack depth
- [ ] NFTSVG.sol re-enabled
- [ ] NonfungibleTokenPositionDescriptor.sol re-enabled
- [ ] tokenURI returns valid SVG data
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/uniswap/v3/periphery/libraries/NFTDescriptor.sol.disabled` → `.sol`
- `contracts/protocols/dexes/uniswap/v3/periphery/libraries/NFTSVG.sol.disabled` → `.sol`
- `contracts/protocols/dexes/uniswap/v3/periphery/NonfungibleTokenPositionDescriptor.sol.disabled` → `.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-151 is complete
- [ ] Disabled files exist

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
