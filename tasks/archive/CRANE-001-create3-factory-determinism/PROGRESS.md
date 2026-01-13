# Progress: CRANE-001 — CREATE3 Factory and Deterministic Deployment Correctness

## Status: Complete

## Work Log

### Session 1
**Date:** 2026-01-12
**Agent:** Claude (Opus 4.5)

**Completed:**
- [x] Identified CREATE3 factory entrypoints under `contracts/factories/create3/**`
  - `Create3Factory.sol` - Main factory with `create3()`, `deployFacet()`, `deployPackage()` methods
  - `Create3FactoryAwareRepo.sol` - Storage/dependency injection for factory reference
  - `Create3FactoryAwareFacet.sol` - Facet exposing factory reference
- [x] Identified helper libraries used by downstream scripts
  - `contracts/utils/Creation.sol` - CREATE/CREATE2/CREATE3 helper wrappers
  - `contracts/utils/Bytecode.sol` - Low-level CREATE3 implementation with proxy initcode
  - `contracts/utils/BetterEfficientHashLib.sol` - Efficient hashing utilities
  - `contracts/InitDevService.sol` - Factory bootstrapping for tests/scripts
  - `contracts/access/AccessFacetFactoryService.sol` - Access control facet deployments
  - `contracts/introspection/IntrospectionFacetFactoryService.sol` - ERC165/Diamond facet deployments
- [x] Reviewed salt derivation patterns and determinism invariants
  - Standard pattern: `abi.encode(type(X).name)._hash()` for salts
  - CREATE3 address depends only on deployer + salt, not initCode
  - Idempotent behavior at factory and low-level layers
- [x] Drafted review memo at `docs/review/create3-and-determinism.md`
- [x] Added two negative tests for determinism invariants
  - `test_create3_differentInitCode_sameSalt_returnsOriginal()` - Verifies idempotency when different initCode deployed to same salt
  - `test_deployFacet_differentInitCode_sameSalt_returnsOriginalAndDoesNotReRegister()` - Verifies registry idempotency
- [x] `forge build` passes (with warnings only)
- [x] `forge test` passes for Create3Factory and Creation tests (58 tests total)

**In Progress:**
- (none)

**Blockers:**
- (none)

**Key Findings:**
1. CREATE3 implementation is correct and follows the standard pattern
2. Salt derivation is consistent across all FactoryService libraries
3. Idempotency is properly implemented at multiple levels:
   - Factory level: Checks if target address already has code before deploying
   - Low-level: Bytecode.create3() reverts with `TargetAlreadyExists` if code exists
4. Registry operations (AddressSetRepo._add) are idempotent - no duplicate entries
5. Access control via `onlyOwnerOrOperator` prevents unauthorized salt occupation

**Files Created:**
- `docs/review/create3-and-determinism.md` - Comprehensive review memo

**Files Modified:**
- `test/foundry/spec/factories/create3/Create3Factory.t.sol` - Added 2 determinism tests

## Checklist

### Inventory Check
- [x] CREATE3 factory entrypoints identified
- [x] Helper libraries catalogued

### Deliverables
- [x] `docs/review/create3-and-determinism.md` created
- [x] At least one negative test added (added 2)
- [x] `forge build` passes
- [x] `forge test` passes

## Final Summary

The CREATE3 factory implementation in Crane is well-designed with proper determinism guarantees:
- Consistent salt derivation using type names
- Idempotent deployments at both factory and low-level
- Cross-chain address consistency (same deployer + salt = same address)
- Access-controlled factory preventing unauthorized usage
- Registry deduplication via AddressSet

No critical issues found. Tests added to prevent regression.
