# Progress Log: CRANE-160

## Current Checkpoint

**Last checkpoint:** Implementation complete
**Next step:** Code review
**Build status:** PASS (4900 tests pass, 6 pre-existing fork failures unrelated)
**Test status:** PASS (18/18 BalancerV3VaultDFPkg tests pass)

---

## Session Log

### 2026-02-07 - Implementation Complete

**US-CRANE-160.1: Remove Duplicate Pool Token Functions from VaultPoolTokenFacet**
- Removed `totalSupply(address)`, `balanceOf(address,address)`, `allowance(address,address,address)`, `approve(address,address,uint256)` from `VaultPoolTokenFacet.sol` (lines 96-143)
- These functions were NOT in `facetFuncs()` and were dead code
- Canonical implementations remain in `VaultQueryFacet` (included in its `facetFuncs()` at indices 20-23)
- VaultPoolTokenFacet now only contains `transfer` and `transferFrom`

**US-CRANE-160.2: Remove Duplicate Admin Functions from VaultQueryFacet**
- Removed `isVaultPaused()` and `isQueryDisabled()` from `VaultQueryFacet.sol` (lines 376-386)
- These functions were NOT in `VaultQueryFacet.facetFuncs()` and were dead code
- Canonical implementations remain in `VaultAdminFacet` (included in its `facetFuncs()` at indices 2 and 18)
- Note: `VaultStateLib`/`VaultStateBits` imports remain needed by `quote()` and `quoteAndRevert()` which call `.isQueryDisabled()` internally

**Verification:**
- `forge build` succeeds (only pre-existing warnings)
- All 18 BalancerV3VaultDFPkg tests pass
- Full test suite: 4900 pass, 6 fail (pre-existing fork test failures only), 18 skipped

**Files Modified:**
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultPoolTokenFacet.sol`
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultQueryFacet.sol`

### 2026-01-29 - Task Created

- Task created from code review suggestion
- Origin: CRANE-159 REVIEW.md Suggestion 1
- Ready for agent assignment via /backlog:launch
