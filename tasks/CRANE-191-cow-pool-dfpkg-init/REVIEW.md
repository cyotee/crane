# Code Review: CRANE-191

**Reviewer:** OpenCode
**Review Started:** 2026-01-31
**Status:** Complete

## Clarifying Questions

- None.

## Review Findings

### Finding 1: CowPoolDFPkg stores wrong factory address during init (delegatecall context)
- **File:** `contracts/protocols/dexes/balancer/v3/pools/cow/CowPoolDFPkg.sol`
- **Severity:** High
- **Description:** `initAccount()` originally used `address(this)` as the pool factory when calling `CowPoolRepo._initialize(...)`. Because `initAccount()` runs via `delegatecall` into the proxy, `address(this)` is the proxy, not the DFPkg. In a realistic vault, `registerPool()` passes `factory = msg.sender` (the DFPkg), so `CowPoolTarget.onRegister(factory, ...)` would fail.
- **Status:** Resolved
- **Resolution:** Store `COW_POOL_FACTORY = address(this)` as an immutable in the DFPkg constructor and use that immutable in `initAccount()`.

### Finding 2: CowPoolTarget.refreshTrustedCowRouter() can revert due to factory interface mismatch
- **File:** `contracts/protocols/dexes/balancer/v3/pools/cow/CowPoolTarget.sol`
- **Severity:** Medium
- **Description:** `refreshTrustedCowRouter()` calls `ICowPoolFactory(factory).getTrustedCowRouter()`. If the stored factory is the DFPkg, it must implement `getTrustedCowRouter()` or the call can revert.
- **Status:** Resolved
- **Resolution:** Add `getTrustedCowRouter()` to `CowPoolDFPkg` returning `TRUSTED_COW_ROUTER` (minimal ICowPoolFactory compatibility).

### Finding 3: CowPoolFacet exposes zero selectors (bytes4(0))
- **File:** `contracts/protocols/dexes/balancer/v3/pools/cow/CowPoolFacet.sol`
- **Severity:** Medium
- **Description:** `facetFuncs()` returned a fixed-size array with three `bytes4(0)` entries. If the diamond factory does not filter them, this can cause unexpected selector routing for `0x00000000`.
- **Status:** Resolved
- **Resolution:** Remove the reserved zero entries and return only real selectors.

### Finding 4: “Integration tests” in TASK.md were not actually integration tests
- **File:** `tasks/CRANE-191-cow-pool-dfpkg-init/TASK.md`
- **Severity:** Medium
- **Description:** Existing tests were unit-style (construct DFPkg with mock facets / mock factory addresses) and did not deploy via the real `CraneTest` + `diamondFactory.deploy(...)` flow, nor did they validate `IHooks.onRegister` as called by a vault.
- **Status:** Resolved
- **Resolution:** Added true integration tests deploying through the real factory stack and a mock vault that enforces `onRegister()` success.

## Suggestions

### Suggestion 1: Consider adding a negative test that reproduces the old onRegister failure
- **Priority:** Low
- **Description:** Now that the bug is fixed, a regression test that demonstrates the pre-fix failure mode (using a local “broken pkg” harness or temporary flag) would lock in the invariant.
- **Affected Files:** `test/foundry/spec/protocols/dexes/balancer/v3/pools/cow/CowPoolDFPkg_Integration.t.sol`

## Review Summary

- **Acceptance criteria:** Met after adding real integration tests.
- **Key correctness fix:** Ensure pool stores DFPkg as factory (not proxy) for vault registration hooks.
- **Tests added:**
  - `test/foundry/spec/protocols/dexes/balancer/v3/pools/cow/CowPoolDFPkg_Integration.t.sol`
  - `test/foundry/spec/protocols/dexes/balancer/v3/pools/cow/CowRouterDFPkg_Integration.t.sol`
- **Recommendation:** Approve.

<promise>PHASE_DONE</promise>
