# Code Review: CRANE-053

**Reviewer:** (pending)
**Review Started:** 2026-01-14
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

(None. Review performed strictly against TASK.md acceptance criteria.)

---

## Review Findings

### Finding 1: TokenConfigUtils._sort swaps only `token`
**File:** [contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol](../../contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol)
**Severity:** Critical
**Description:** `_sort(TokenConfig[] memory)` only swaps the `token` field, leaving `tokenType`, `rateProvider`, and `paysYieldFees` in their original array slots. This corrupts `TokenConfig` alignment after sorting and can lead to invalid pool configuration.
**Status:** Resolved
**Resolution:** Implemented full-struct element swaps and updated tests to assert alignment preservation (worktree change).

### Finding 2: US-CRANE-053.2 not met (no real DFPkg diamond deployment / postDeploy flow test)
**File:** [test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.t.sol](../../test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.t.sol)
**Severity:** High
**Description:** The tests validate metadata (`facetCuts`, interface IDs, selector collision scan, `calcSalt`, `processArgs`, `updatePkg`) but do not execute a full deployment via `IDiamondPackageCallBackFactory.deploy(...)`, do not exercise `initAccount(...)` initialization behavior, and do not execute `postDeploy(...)` (Balancer Vault registration).

This fails TASK.md acceptance criteria for US-CRANE-053.2:
- “Test full diamond deployment via DFPkg”
- “Test vault registration flow”

**Status:** Open
**Resolution:** Add an integration-style test using the real factory stack (`Create3Factory` + `DiamondPackageCallBackFactory` via `InitDevService`) and deploy the package + proxy, then assert:
- Proxy has expected facets/selectors
- `initAccount` initializes ERC20/EIP712/pool state as expected
- `postDeploy` performs Balancer Vault registration (or is at least invoked and makes expected calls)

### Finding 3: Salt/order-independence tests do not cover heterogeneous TokenConfig fields
**File:** [test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.t.sol](../../test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.t.sol)
**Severity:** Medium
**Description:** `calcSalt` sorts `TokenConfig[]` then hashes `abi.encode(decodedArgs)`. Because sorting is currently buggy (Finding 1) and these tests mostly use identical/zeroed non-token fields, they can pass while real-world order-independence fails when token configs differ per token.

Concretely: with distinct `tokenType` / `rateProvider` / `paysYieldFees` per token, swapping only `token` changes meaning of the encoded struct array and can make salts depend on input ordering.
**Status:** Resolved
**Resolution:** Added regression coverage using heterogeneous per-token fields for `calcSalt` and an explicit `processArgs` alignment assertion (worktree change).

### Finding 4: “Pool never loses value due to rounding” is not asserted strictly for EXACT_OUT
**File:** [contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol](../../contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolTarget.sol)
**Severity:** Medium
**Description:** `onSwap` uses integer division for both swap kinds, which always rounds down. For `SwapKind.EXACT_OUT`, pool-favorable rounding typically requires rounding *up* the required `amountIn` (ceiling) to avoid the pool giving away value. The current test suite allows invariant decreases via tolerances (e.g., `- 1e9`, or 0.01%), and does not include a targeted check that EXACT_OUT uses pool-favorable rounding.
**Status:** Open
**Resolution:** Add a targeted test that searches a small input space for a counterexample (or deterministic example) where floor division under-charges `amountIn` for EXACT_OUT and decreases $k$, and then tighten assertions once the implementation is corrected.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Fix TokenConfigUtils._sort by swapping full structs
**Priority:** P0
**Description:** Replace the token-only swap with a full `TokenConfig` element swap. This is required for correctness and will enable the “fields remain aligned after sorting” acceptance criterion to be enforced.
**Affected Files:**
- [contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol](../../contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol)
**User Response:** (pending)
**Notes:** After fixing, update the “KNOWN_BUG” tests to assert correct alignment (or remove/rename them).

### Suggestion 2: Add real factory deployment + postDeploy registration test
**Priority:** P1
**Description:** Implement an integration-style test that deploys the DFPkg and a proxy via the actual factory stack and asserts that `postDeploy` causes the expected Balancer Vault registration behavior.
**Affected Files:**
- [test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.t.sol](../../test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.t.sol)
**User Response:** (pending)
**Notes:** Use existing Crane patterns (`InitDevService`) rather than mocks.

### Suggestion 3: Strengthen order-independence tests with heterogeneous TokenConfig fields
**Priority:** P1
**Description:** Add `calcSalt`/`processArgs` tests where each token has distinct config fields (rate provider, token type, fee flags) to ensure sorting preserves alignment and order-independence holds under realistic inputs.
**Affected Files:**
- [test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.t.sol](../../test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.t.sol)
**User Response:** (pending)
**Notes:** This will likely fail until Suggestion 1 is implemented.

### Suggestion 4: Add explicit EXACT_OUT pool-favorable rounding assertions
**Priority:** P2
**Description:** Add a test specifically asserting pool-favorable behavior for EXACT_OUT swaps (ceil required input) and tighten/remove “allow small decrease” tolerances once correctness is verified.
**Affected Files:**
- [test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3RoundingInvariants.t.sol](../../test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3RoundingInvariants.t.sol)
**User Response:** (pending)
**Notes:** Consider brute-forcing small balances/amounts to deterministically find rounding edge cases.

---

## Review Summary

**Findings:** 4 (1 critical, 1 high, 2 medium)
**Suggestions:** 4 follow-ups proposed
**Recommendation:** Do not treat CRANE-053 as fully meeting TASK.md until the real DFPkg deployment + vault registration flow tests are added and TokenConfig sorting is fixed/enforced.

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`

<promise>REVIEW_COMPLETE</promise>
