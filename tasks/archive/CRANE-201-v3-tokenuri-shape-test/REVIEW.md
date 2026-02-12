# Code Review: CRANE-201

**Reviewer:** OpenCode
**Review Started:** 2026-02-03
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None.

---

## Requirements Verification (from TASK.md)

- [ ] Test mints a position (or stubs the manager/pool)
- [x] Asserts `tokenURI()` returns prefix `data:application/json;base64,`
- [x] Decoded JSON includes `image` field with prefix `data:image/svg+xml;base64,`
- [x] Decoded SVG starts with `<svg` and ends with `</svg>`
- [x] Tests pass
- [ ] Build succeeds

---

## Review Findings

### Finding 1: Test Doesn't Exercise `NonfungibleTokenPositionDescriptor.tokenURI`
**File:** `test/foundry/spec/protocols/dexes/uniswap/v3/periphery/NFTDescriptorTokenURI.t.sol`
**Severity:** Medium
**Description:** Tests call `NFTDescriptor.constructTokenURI()` directly rather than calling `NonfungibleTokenPositionDescriptor.tokenURI()` with a stubbed `INonfungiblePositionManager` + `IUniswapV3Pool`. This validates the core formatting logic, but can miss wiring issues (pool address computation, `slot0()` tick sourcing, flipRatio behavior, token symbol/decimals sourcing).
**Status:** Open
**Resolution:** Add a minimal stub position manager and pool in-test (or as dedicated stubs) and run at least one end-to-end `descriptor.tokenURI(stubManager, tokenId)` shape test.

### Finding 2: `POOL_INIT_CODE_HASH` Change Not Guarded by a Test
**File:** `contracts/protocols/dexes/uniswap/v3/periphery/libraries/PoolAddress.sol`
**Severity:** Medium
**Description:** Updating `PoolAddress.POOL_INIT_CODE_HASH` is cross-cutting: it affects deterministic pool address computation for all periphery consumers. The new value may be correct for the Crane-ported `UniswapV3Pool`, but there is no automated check tying it to `keccak256(type(UniswapV3Pool).creationCode)`.
**Status:** Open
**Resolution:** Add a unit test that asserts `POOL_INIT_CODE_HASH == keccak256(type(UniswapV3Pool).creationCode)` (or equivalent) to prevent future drift.

### Finding 3: Unable To Verify `forge build` In This Environment
**File:** (repo-wide)
**Severity:** Low
**Description:** `forge test --match-contract NFTDescriptorTokenURI` passes (4/4), but `forge build` did not complete within a 10 minute timeout in this environment.
**Status:** Open
**Resolution:** Re-run `forge build` in CI / a normal dev environment and confirm it completes successfully.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Add An End-to-End `tokenURI()` Shape Test
**Priority:** High
**Description:** Add a test that calls `NonfungibleTokenPositionDescriptor.tokenURI()` with stubbed `INonfungiblePositionManager` + `IUniswapV3Pool` (returning controlled `positions()`, `factory()`, `slot0()`, `tickSpacing()`), then runs the same shape assertions. This directly satisfies the acceptance criterion and covers integration wiring.
**Affected Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v3/periphery/NFTDescriptorTokenURI.t.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-215

### Suggestion 2: Add A Regression Test For `POOL_INIT_CODE_HASH`
**Priority:** High
**Description:** Add a dedicated test asserting `PoolAddress.POOL_INIT_CODE_HASH` matches `keccak256(type(UniswapV3Pool).creationCode)`.
**Affected Files:**
- `contracts/protocols/dexes/uniswap/v3/periphery/libraries/PoolAddress.sol`
- New test file near `test/foundry/spec/protocols/dexes/uniswap/v3/periphery/`
**User Response:** Accepted
**Notes:** Converted to task CRANE-216

### Suggestion 3: Reduce False Positives In JSON Validation
**Priority:** Low
**Description:** Instead of only searching for the SVG prefix substring anywhere in JSON, extract the `"image":"..."` value and assert it starts with `data:image/svg+xml;base64,`. This avoids passing if the prefix ever appears in another field.
**Affected Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v3/periphery/NFTDescriptorTokenURI.t.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-217

---

## Review Summary

**Findings:** 3 (2 medium, 1 low)
**Suggestions:** 3 (2 high, 1 low)
**Recommendation:** Approve after addressing Finding 1 (end-to-end `tokenURI()` coverage) and adding a regression check for `POOL_INIT_CODE_HASH`.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
