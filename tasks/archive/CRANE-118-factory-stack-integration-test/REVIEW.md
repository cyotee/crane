# Code Review: CRANE-118

**Reviewer:** Claude (Opus 4.6)
**Review Started:** 2026-02-08
**Status:** Complete

---

## Clarifying Questions

No clarifying questions needed. The task requirements are clear: replace `new` with `create3Factory.deployFacet()` for facets and `create3Factory.deployPackageWithArgs()` for the DFPkg.

---

## Acceptance Criteria Verification

### US-CRANE-118.1: Deploy facets via Create3Factory

- [x] **Test deploys all facets via `ICreate3Factory.deployFacet()`** - All 5 facets (`BalancerV3VaultAwareFacet`, `BalancerV3PoolTokenFacet`, `BalancerV3AuthenticationFacet`, `BalancerV3ConstantProductPoolFacet`, `MockPoolInfoFacet`) are deployed via `create3Factory.deployFacet()` in `_deployRealFacets()` (lines 317-358).
- [x] **Facet addresses are deterministic and verifiable** - Each facet uses salt `abi.encode(type(X).name)._hash()`, matching the framework convention used in `GyroPoolFactoryService` and `IntrospectionFacetFactoryService`.
- [x] **Tests pass with factory-deployed facets** - All 21 tests pass.

### US-CRANE-118.2: Deploy package via Create3Factory

- [x] **Test deploys DFPkg via `ICreate3Factory.deployPackageWithArgs()`** - `_deployPkg()` (lines 360-382) uses `create3Factory.deployPackageWithArgs()` with creation code, ABI-encoded PkgInit struct, and type-name-derived salt.
- [x] **Package address is deterministic** - Salt derived from `abi.encode(type(BalancerV3ConstantProductPoolDFPkg).name)._hash()`.
- [x] **Tests pass with factory-deployed package** - All 21 tests pass.

### Completion Criteria

- [x] All acceptance criteria met
- [x] All tests pass (21/21)
- [x] `forge test` passes
- [x] `forge build` succeeds (warnings only, no errors)

---

## Review Findings

### Finding 1: Pattern matches framework conventions exactly
**File:** `test/foundry/.../BalancerV3ConstantProductPoolDFPkg_Integration.t.sol`
**Severity:** None (positive observation)
**Description:** The deployment pattern in `_deployRealFacets()` and `_deployPkg()` exactly matches the established convention from `GyroPoolFactoryService.sol` and `IntrospectionFacetFactoryService.sol`:
- Salt: `abi.encode(type(X).name)._hash()`
- Labels: `vm.label(address(x), type(X).name)` (improved from previous string literals)
- Package: `create3Factory.deployPackageWithArgs(creationCode, abi.encode(constructorArgs), salt)`
**Status:** Resolved (no action needed)

### Finding 2: PkgInit struct fields match interface definition
**File:** `test/foundry/.../BalancerV3ConstantProductPoolDFPkg_Integration.t.sol` (lines 365-376)
**Severity:** None (positive observation)
**Description:** All 10 fields of `IBalancerV3ConstantProductPoolStandardVaultPkg.PkgInit` are correctly populated. Verified against the struct definition in `BalancerV3ConstantProductPoolDFPkg.sol` (lines 60-71).
**Status:** Resolved (no action needed)

### Finding 3: Label improvement from hardcoded strings to type(X).name
**File:** `test/foundry/.../BalancerV3ConstantProductPoolDFPkg_Integration.t.sol`
**Severity:** None (positive observation)
**Description:** The diff shows labels changed from hardcoded strings (e.g., `"BalancerV3VaultAwareFacet"`) to `type(X).name`. This is safer because it stays in sync if a contract is renamed, and matches the FactoryService convention.
**Status:** Resolved (no action needed)

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Extract ConstantProductPoolFactoryService
**Priority:** P3 (nice-to-have)
**Description:** The inlined deployment logic in `_deployRealFacets()` and `_deployPkg()` could be extracted into a `ConstantProductPoolFactoryService.sol` library, mirroring the existing `GyroPoolFactoryService.sol` pattern. This would make the deployment logic reusable across tests and deployment scripts.
**Affected Files:**
- New: `contracts/protocols/dexes/balancer/v3/pool-constProd/ConstantProductPoolFactoryService.sol`
- Modified: `test/foundry/.../BalancerV3ConstantProductPoolDFPkg_Integration.t.sol` (to use the new service)
**User Response:** Accepted
**Notes:** Converted to task CRANE-264. Not blocking. The current inline approach is functionally correct and follows the same patterns. The GyroPoolFactoryService exists because it's used across multiple test files; the constant product pool may not need one until there are multiple consumers.

### Suggestion 2: Add test verifying facet addresses are registered in Create3Factory
**Priority:** P3 (nice-to-have)
**Description:** The current tests verify that facets work correctly on the deployed proxy, but don't explicitly assert that the facet addresses are registered in the Create3Factory's internal registry (e.g., querying `create3Factory.getDeployedFacet(salt)` if such a method exists). This would more directly validate "registry behavior" as mentioned in the task description.
**Affected Files:**
- Modified: `test/foundry/.../BalancerV3ConstantProductPoolDFPkg_Integration.t.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-265. The existing tests indirectly prove registry behavior works (deployment succeeds and proxy uses the facets). An explicit registry check would be a minor hardening.

---

## Review Summary

**Findings:** 3 findings, all positive observations (no issues found)
**Suggestions:** 2 suggestions, both P3 (nice-to-have, not blocking)
**Recommendation:** APPROVE

The implementation correctly fulfills both user stories. All facets and the DFPkg are deployed via the Create3Factory with deterministic salts following established framework conventions. The diff is clean and focused: only `_deployRealFacets()` and `_deployPkg()` were modified, with no unrelated changes. All 21 tests pass. Build succeeds. Labels were improved from hardcoded strings to `type(X).name`.

---

**When review complete, output:** `<promise>PHASE_DONE</promise>`
