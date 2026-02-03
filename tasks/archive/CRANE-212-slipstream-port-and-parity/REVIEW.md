# Code Review: CRANE-212

**Reviewer:** (pending)
**Review Started:** 2026-02-03
**Status:** In Progress

---

## Clarifying Questions

Questions asked to understand review criteria:

(Questions and answers will be recorded here during review)

---

## Review Findings

### Finding 1: Wrong Base Slipstream factory address in fork parity base
**File:** `contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_SlipstreamFork.sol`
**Severity:** High
**Description:** `SLIPSTREAM_FACTORY` was set to the pool implementation address (`0xeC8E...`) rather than the pool factory (`0x5e7B...`). This caused all fork parity tests in `test/foundry/fork/base_main/slipstream/SlipstreamForkParity.t.sol` to revert when calling `owner()` / `tickSpacingToFee()` etc.
**Status:** Resolved
**Resolution:** Updated `SLIPSTREAM_FACTORY` to `0x5e7BB104d84c7CB9B682AaC2F3d509f5F406809A` and added `SLIPSTREAM_POOL_IMPLEMENTATION` constant for clarity. Confirmed `forge test --match-path "test/foundry/fork/base_main/slipstream/*"` passes.

### Finding 2: Fork parity suite does not meet TASK.md parity depth
**File:** `test/foundry/fork/base_main/slipstream/SlipstreamForkParity.t.sol`
**Severity:** High
**Description:** TASK.md requires fork parity that creates fresh pools on both factories and validates parity for createPool+initialize, mint/burn via callback, swaps (both directions; deterministic tick-cross), and observe/cardinality. Current fork parity tests are read-only checks against existing production pools (slot0/liquidity/observe/fees/rewards/ticks). They do not compare production vs ported behavior for pool creation, callbacks, or swaps.
**Status:** Resolved
**Resolution:** Reworked the fork parity suite to deploy local test tokens, create fresh pools on both the production Slipstream factory and the ported local `CLFactory`, initialize both pools to the same `sqrtPriceX96`, and then execute parity checks for:
- createPool + initialize (`test_Parity_createPool_initialize`)
- mint/burn/collect via callback harness (`test_Parity_mint_burn_collect`)
- swaps both directions (`test_Parity_swap_bothDirections`)
- tick crossing under a large swap (`test_Parity_swap_tickCrossing`)
- observe/cardinality growth (`test_Parity_observe_cardinality`)

To pay the pool during callbacks, the suite uses a dedicated `SlipstreamCallbackHarness` (implements mint/swap callbacks) and pranks as that contract for the full call so the pool callback reaches the correct address. Verified `forge test --match-path "test/foundry/fork/base_main/slipstream/*"` passes.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Add full fork parity flows (create+init, mint/burn callbacks, swaps)
**Priority:** High
**Description:** TASK.md requires fork parity tests that create fresh pools on both factories and compare createPool+initialize, mint/burn via callback, swaps both directions (including deterministic tick-cross), and observe/cardinality. Current `test/foundry/fork/base_main/slipstream/SlipstreamForkParity.t.sol` validates read-only invariants/state against production pools, but does not exercise pool creation or callback-driven mint/burn/swap parity.
**Affected Files:**
- `test/foundry/fork/base_main/slipstream/SlipstreamForkParity.t.sol`
- `contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_SlipstreamFork.sol`
**User Response:** (pending)
**Notes:** Consider deploying a local Crane `CLFactory` + `CLPool` on the fork (using local test tokens) and comparing results against production (where possible). For production, createPool may be permissioned/undesirable on fork; alternative is to compare against a known production pool for swap/mint/burn behavior using a minimal callback harness.

**Status Update:** Implemented (this suggestion is now satisfied by the updated parity test suite).

---

## Review Summary

**Findings:** 2 (1 resolved, 1 open)
**Suggestions:** 1
**Recommendation:** Changes requested: address the missing parity flows (or update TASK.md acceptance criteria to match the intended scope) before calling CRANE-212 complete.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
