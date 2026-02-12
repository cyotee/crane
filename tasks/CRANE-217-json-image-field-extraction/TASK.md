# Task CRANE-217: Reduce False Positives In JSON Validation

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-03
**Dependencies:** CRANE-201 (complete/archived)
**Worktree:** `test/json-image-field-extraction`
**Origin:** Code review suggestion from CRANE-201
**Priority:** Low

---

## Description

Instead of only searching for the SVG prefix substring anywhere in JSON, extract the `"image":"..."` value and assert it starts with `data:image/svg+xml;base64,`. This avoids passing if the prefix ever appears in another field.

(Created from code review of CRANE-201)

## Dependencies

- CRANE-201: Add V3 NFT tokenURI Shape Test (complete/archived - parent task)

## User Stories

### US-CRANE-217.1: Precise JSON Image Field Extraction

As a developer, I want the tokenURI tests to extract the actual `image` field value so that false positives from prefix matches elsewhere are avoided.

**Acceptance Criteria:**
- [ ] Parse JSON and extract the `"image"` field value
- [ ] Assert the extracted value starts with `data:image/svg+xml;base64,`
- [ ] Remove or replace the substring search approach
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v3/periphery/NFTDescriptorTokenURI.t.sol`

## Technical Notes

Options for JSON parsing in Solidity tests:
1. Use string manipulation to find `"image":"` and extract until closing quote
2. Use a minimal JSON parser library if available
3. Use `vm.parseJson()` if Foundry supports the structure

## Inventory Check

Before starting, verify:
- [ ] CRANE-201 is complete (check tasks/archive/)
- [ ] `NFTDescriptorTokenURI.t.sol` exists
- [ ] Current tests use substring search

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass: `forge test --match-contract NFTDescriptorTokenURI`
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
