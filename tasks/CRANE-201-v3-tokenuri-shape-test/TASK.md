# Task CRANE-201: Add V3 NFT tokenURI Shape Test

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-02-01
**Dependencies:** CRANE-183
**Worktree:** `test/v3-tokenuri-shape-test`
**Origin:** Code review suggestion from CRANE-183

---

## Description

Add a focused test that validates the shape and structure of the `tokenURI()` output from `NonfungibleTokenPositionDescriptor`. This ensures the metadata generation refactored in CRANE-183 produces correctly formatted output.

(Created from code review of CRANE-183)

## Dependencies

- CRANE-183: Refactor V3 NFT Metadata to Fix Stack-Too-Deep (Complete - parent task)

## User Stories

### US-CRANE-201.1: Validate tokenURI Output Format

As a developer, I want a test that verifies the NFT position `tokenURI()` returns properly formatted data so that I can be confident the metadata generation is correct.

**Acceptance Criteria:**
- [x] Test mints a position (or stubs the manager/pool)
- [x] Asserts `tokenURI()` returns prefix `data:application/json;base64,`
- [x] Decoded JSON includes `image` field with prefix `data:image/svg+xml;base64,`
- [x] Decoded SVG starts with `<svg` and ends with `</svg>`
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v3/periphery/NFTDescriptorTokenURI.t.sol` (or appropriate location)

**Modified Files:**
- Possibly mock/stub contracts if needed to isolate tokenURI testing

## Inventory Check

Before starting, verify:
- [x] CRANE-183 is complete (merged to main)
- [x] `NonfungibleTokenPositionDescriptor.sol` is enabled and compiles
- [x] `NFTDescriptor.sol` and `NFTSVG.sol` are enabled and compile

## Implementation Notes

The test may need to:
1. Deploy NonfungibleTokenPositionDescriptor with required dependencies
2. Mock or stub the pool/position data to avoid full integration
3. Call `tokenURI(tokenId)` and parse the result
4. Use Base64 decoding to verify JSON structure
5. Extract and decode the SVG from the JSON's `image` field

Consider using Foundry's string manipulation capabilities or a simple Base64 library for decoding.

## Completion Criteria

- [x] All acceptance criteria met
- [x] Tests pass with `forge test --match-contract NFTDescriptorTokenURI`
- [x] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
