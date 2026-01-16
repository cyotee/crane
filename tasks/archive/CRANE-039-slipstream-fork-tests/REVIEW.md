# Code Review: CRANE-039

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-15
**Review Completed:** 2026-01-16
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

- None. TASK.md acceptance criteria were clear.

---

## Review Findings

### Finding 1: Misleading pool naming vs actual fee
**File:** test/foundry/fork/base_main/slipstream/TestBase_SlipstreamFork.sol
**Severity:** Low
**Description:** The constant `WETH_USDC_CL_500` implies 0.05% (500) but the forked pool reports `fee: 400` via `pool.fee()` at the pinned block. This is harmless (fee is read from the pool) but can confuse future maintainers and reviewers.
**Status:** Open
**Resolution:** Rename constants/comments to match observed fee (e.g., `WETH_USDC_CL` or `WETH_USDC_CL_400`) and update the in-file commentary.

### Finding 2: TASK.md “files to create” path mismatch
**File:** tasks/CRANE-039-slipstream-fork-tests/TASK.md
**Severity:** Low
**Description:** TASK.md lists new files under `test/foundry/protocols/dexes/aerodrome/slipstream/fork/…`, but the implementation follows the repo’s existing fork-test convention under `test/foundry/fork/base_main/slipstream/…`.
**Status:** Open
**Resolution:** Update TASK.md to reference the actual paths (or add a short note explaining the fork-test directory convention).

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Gate fork tests with an explicit env flag
**Priority:** Medium
**Description:** `setUp()` currently skips fork tests when `INFURA_KEY` is unset. Consider also gating behind something like `RUN_FORK_TESTS=1` (and keeping the `INFURA_KEY` check) so CI/local runs don't silently skip when a key exists but forks are not desired.
**Affected Files:**
- test/foundry/fork/base_main/slipstream/TestBase_SlipstreamFork.sol
**User Response:** Rejected
**Notes:** Current INFURA_KEY check is sufficient.

### Suggestion 2: Add at least one additional high-liquidity pool (with existence check)
**Priority:** Medium
**Description:** TASK.md calls out “other high-liquidity Slipstream pools”. Current coverage is great for WETH/USDC, but adding one more (e.g., AERO/USDC) would reduce the chance of pair-specific assumptions slipping in. If address stability at the fork block is uncertain, add a lightweight “pool exists” check and `vm.skip(true)` for that test only.
**Affected Files:**
- test/foundry/fork/base_main/slipstream/TestBase_SlipstreamFork.sol
- test/foundry/fork/base_main/slipstream/SlipstreamUtils_Fork.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-089

### Suggestion 3: Round out the edge-case matrix for exact-output
**Priority:** Low
**Description:** There is a zero-amount test for exact-input. Consider adding `quoteExactOutputSingle(0, …) == 0` and (optionally) a “dust exact-output” test with slightly relaxed tolerance.
**Affected Files:**
- test/foundry/fork/base_main/slipstream/SlipstreamUtils_Fork.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-090

---

## Review Summary

**Findings:** 2 (both Low severity)
**Suggestions:** 3
**Recommendation:** Approve (minor nits + optional follow-ups)

**Verification:**
- `forge test -vvv test/foundry/fork/base_main/slipstream/SlipstreamUtils_Fork.t.sol` (10/10 pass)
- `forge test -vvv test/foundry/fork/base_main/slipstream/SlipstreamGas_Fork.t.sol` (10/10 pass)
- Quote assertions match actual swaps exactly on the pinned fork block; gas report prints as expected.

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
