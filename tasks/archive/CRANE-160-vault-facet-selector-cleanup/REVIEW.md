# Code Review: CRANE-160

**Reviewer:** Claude (Code Review Agent)
**Review Started:** 2026-02-07
**Status:** Complete

---

## Clarifying Questions

No clarifying questions needed - task scope and acceptance criteria are clear.

---

## Review Findings

### Finding 1: Clean removal of dead code from VaultPoolTokenFacet
**File:** `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultPoolTokenFacet.sol`
**Severity:** N/A (positive finding)
**Description:** `totalSupply`, `balanceOf`, `allowance`, `approve` were correctly removed. These functions were never in `facetFuncs()` and thus unreachable through the Diamond proxy. The facet now contains only `transfer` and `transferFrom`, matching its `facetFuncs()` exactly.
**Status:** Resolved
**Resolution:** Correctly implemented

### Finding 2: Clean removal of dead code from VaultQueryFacet
**File:** `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultQueryFacet.sol`
**Severity:** N/A (positive finding)
**Description:** `isVaultPaused()` and `isQueryDisabled()` were correctly removed. Both were absent from `facetFuncs()` and existed as dead code. The canonical implementations remain in `VaultAdminFacet` (at `facetFuncs()` indices 2 and 18). The `VaultStateLib`/`VaultStateBits` imports remain correctly used by `quote()` and `quoteAndRevert()` which call the library method `.isQueryDisabled()` on the storage bits (not the removed external function).
**Status:** Resolved
**Resolution:** Correctly implemented

### Finding 3: No selector collisions across facets
**File:** All facets in `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/`
**Severity:** N/A (positive finding)
**Description:** Verified each selector appears in exactly one facet's `facetFuncs()`:
- `transfer`, `transferFrom` -> `VaultPoolTokenFacet` only
- `totalSupply`, `balanceOf`, `allowance`, `approve` -> `VaultQueryFacet` only
- `isVaultPaused`, `isQueryDisabled` -> `VaultAdminFacet` only
**Status:** Resolved
**Resolution:** No collisions

### Finding 4: All tests pass
**File:** `test/foundry/spec/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDFPkg.t.sol`
**Severity:** N/A (positive finding)
**Description:** All 18 BalancerV3VaultDFPkg tests pass, including:
- `test_interface_IVaultMain_selectorsResolveTofacets`
- `test_interface_IVaultExtension_selectorsResolveTofacets`
- `test_interface_IVaultAdmin_selectorsResolveTofacets`
No test modifications were needed because tests verify selector resolution on the Diamond proxy, not direct facet calls.
**Status:** Resolved
**Resolution:** Build succeeds, all tests pass

---

## Suggestions

No follow-up suggestions. The implementation is clean and minimal.

---

## Review Summary

**Findings:** 4 (all positive - correct implementation)
**Suggestions:** 0
**Recommendation:** APPROVE

### Acceptance Criteria Verification

| Criterion | Status |
|-----------|--------|
| VaultPoolTokenFacet contains only `transfer` and `transferFrom` | PASS |
| All pool-token read functions exist only in VaultQueryFacet | PASS |
| `isVaultPaused()` and `isQueryDisabled()` only in VaultAdminFacet | PASS |
| `VaultQueryFacet.facetFuncs()` returns only query-related selectors | PASS |
| No selector collisions in Diamond | PASS |
| Tests pass | PASS (18/18) |
| Build succeeds | PASS |

### Summary

This is a clean, minimal change that removes dead code from two facets. The diff is deletion-only (no additions to production code). Each removed function was unreachable through the Diamond proxy because it was absent from the owning facet's `facetFuncs()`. The canonical implementations remain in their correct homes (`VaultQueryFacet` for BPT reads, `VaultAdminFacet` for admin queries). No regressions introduced.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
