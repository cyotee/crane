# Progress: CRANE-010 — Aerodrome V1 Utilities

## Status: Complete

## Work Log

### Session 1
**Date:** 2026-01-13
**Agent:** Claude Agent

**Completed:**
- [x] Reviewed `contracts/protocols/dexes/aerodrome/v1/` directory structure
- [x] Analyzed Pool.sol for stable vs volatile pool curve implementation
- [x] Documented fee handling (10,000 denominator vs Uniswap's 100,000)
- [x] Reviewed AerodromService.sol - identified volatile-only limitation
- [x] Reviewed AerodromeRouterAwareRepo and AerodromePoolMetadataRepo
- [x] Analyzed ConstProdUtils integration with AERO_FEE_DENOM
- [x] Reviewed TestBase_Aerodrome.sol and TestBase_Aerodrome_Pools.sol
- [x] Analyzed existing test coverage (19 direct Aerodrome tests + 27 ConstProdUtils tests)
- [x] Created correctness memo at `docs/review/aerodrome-v1-utils.md`
- [x] Verified `forge build` passes
- [x] Verified all 46 Aerodrome-related tests pass

**In Progress:**
- (none)

**Blockers:**
- (none)

**Key Findings:**
1. **Stable pool gap**: `AerodromService` hardcodes `stable: false`, making it incompatible with stable pools despite stubs supporting both
2. **Fee denominator correct**: AERO_FEE_DENOM = 10,000 properly passed to ConstProdUtils
3. **Invariants documented**:
   - Volatile: `x * y = k`
   - Stable: `x³y + xy³ = k` (normalized)
4. **Test coverage good** for volatile pools, missing stable pool tests

**Next Steps:**
- (Task complete - recommend adding stable pool support in future work)

## Checklist

### Inventory Check
- [x] Aerodrome V1 utilities reviewed
- [x] Stable pool curve documented
- [x] Volatile pool curve documented

### Deliverables
- [x] `docs/review/aerodrome-v1-utils.md` created
- [x] `forge build` passes
- [x] `forge test` passes

## Summary

Created comprehensive review memo documenting:
- Key invariants for both pool types
- Fee structure (10,000 basis point denominator)
- Router/factory integration patterns
- AwareRepo dependency injection patterns
- Test coverage analysis with gaps identified
- Critical issue: lack of stable pool support in service layer
- Recommendations for future improvements
