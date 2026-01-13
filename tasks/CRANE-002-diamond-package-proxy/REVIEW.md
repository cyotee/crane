# Code Review: CRANE-002

**Reviewer:** GitHub Copilot (GPT-5.2)
**Review Started:** 2026-01-12
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

None.

---

## Review Findings

### Finding 1: ERC2535 selector removal does not clear routing
**File:** contracts/introspection/ERC2535/ERC2535Repo.sol
**Severity:** High
**Description:** `_removeFacet()` sets `layout.facetAddress[selector] = facetCut.facetAddress` instead of `address(0)`. Because proxy routing in `MinimalDiamondCallBackProxy._getTarget()` uses `ERC2535Repo._facetAddress(msg.sig)`, removed selectors can remain routable.
**Impact:** Breaks the intended “remove” semantics; prevents safe re-add of selectors; and critically undermines the post-deploy hook removal (the `postDeploy()` selector can remain callable even after “removal”).
**Status:** Open
**Resolution:** Follow-up fix: set selector mapping to `address(0)` on removal and ensure facet bookkeeping stays consistent.

### Finding 2: ERC2535 replace path removes wrong facet address
**File:** contracts/introspection/ERC2535/ERC2535Repo.sol
**Severity:** High
**Description:** In `_replaceFacet()`, when the old facet becomes empty, the code calls `layout.facetAddresses._remove(facetCut.facetAddress)`.
**Impact:** `facetCut.facetAddress` is the *new* facet address, not the old one being emptied. This can leave the old facet address in the facet address set (and/or remove the wrong entry), making loupe results inconsistent with actual selector routing.
**Status:** Open
**Resolution:** Follow-up fix: remove `currentFacet` when its selector set becomes empty (and consider deleting its selector set storage).

### Finding 3: ERC165Repo overload unregisters interfaces
**File:** contracts/introspection/ERC165/ERC165Repo.sol
**Severity:** Medium
**Description:** `_registerInterface(bytes4)` assigns `false` instead of `true`.
**Impact:** Latent defect: current codepaths appear to call `_registerInterfaces(bytes4[])`, which uses the correct storage-parameterized overload, so the bug may not be hit today. However, the overload is public to the codebase and is likely to be used in the future.
**Status:** Open
**Resolution:** Follow-up fix: set to `true`.

### Finding 4: Core factory deployment flow lacks direct tests
**File:** test/foundry/spec/factories/diamondPlg/DiamondPackageCallBackFactory.t.sol
**Severity:** High
**Description:** The test file exists but is effectively empty (only pragma/license).
**Impact:** The most critical integration path (CREATE2 deployment + constructor callback + facet cuts + post-deploy hook removal) is unvalidated by tests in this repo.
**Status:** Open
**Resolution:** Follow-up: add an end-to-end Foundry test that deploys a minimal package and asserts selector routing, ERC165 registration, idempotent deploy, and postDeploy removal.

### Finding 5: Factory performs DELEGATECALL into package code during deploy
**Files:**
- contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol
- contracts/factories/diamondPkg/utils/DiamondFactoryPackageAdaptor.sol
**Severity:** High
**Description:** `deploy()` uses `pkg._calcSalt(pkgArgs)` and `pkg._processArgs(pkgArgs)` which are implemented as `delegatecall` into `pkg`.
**Impact:** Package code executes in the factory’s storage context during deploy. A malicious/buggy package can mutate factory storage (or attempt destructive behavior) prior to proxy creation.
**Status:** Open
**Resolution:** Document the trust model explicitly and consider redesigning these hooks to avoid `delegatecall` (e.g., pure/view call with returned data) unless there is a hard requirement for execution in the factory context.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Fix ERC2535 remove/replace correctness
**Priority:** Critical
**Description:** Address the two ERC2535Repo issues (selector mapping not cleared on remove; wrong facet address removed on replace). These directly affect proxy routing correctness and post-deploy hook removal safety.
**Affected Files:**
- contracts/introspection/ERC2535/ERC2535Repo.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-014. Add unit tests that would have caught both (remove should make selector unroutable; replace should update loupe facet list deterministically).

### Suggestion 2: Fix ERC165Repo overload
**Priority:** High
**Description:** Change `_registerInterface(bytes4)` to set `true` to match the storage-parameterized overload.
**Affected Files:**
- contracts/introspection/ERC165/ERC165Repo.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-015. Consider adding a small unit test to cover both overloads.

### Suggestion 3: Add end-to-end factory deployment tests
**Priority:** High
**Description:** Add a Foundry test that exercises `DiamondPackageCallBackFactory.deploy()` end-to-end using a minimal test package:
- asserts deterministic address / idempotent deploy
- asserts base facets installed
- asserts package facets installed
- asserts postDeploy hook facet is removed and `postDeploy()` selector no longer routes
**Affected Files:**
- test/foundry/spec/factories/diamondPlg/DiamondPackageCallBackFactory.t.sol
**User Response:** Accepted
**Notes:** Converted to task CRANE-016. The current file is present but empty; filling it is likely the intended location.

### Suggestion 4: Reduce or harden package DELEGATECALL surface
**Priority:** Medium
**Description:** If `calcSalt()` and `processArgs()` do not strictly require `delegatecall`, switch to `call` (and ideally `view` for `calcSalt`). If `delegatecall` is required, restrict packages to trusted deployments and consider moving `pkgOfAccount/pkgArgsOfAccount` to a separate minimal storage contract as already noted by TODO in the factory.
**Affected Files:**
- contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol
- contracts/factories/diamondPkg/utils/DiamondFactoryPackageAdaptor.sol
**User Response:** (pending)
**Notes:** Current approach is viable under an explicit “operator-trusted packages only” model, but that assumption should be written down.

### Suggestion 5: Clarify interface usage in PostDeployAccountHookFacet
**Priority:** Low
**Description:** `PostDeployAccountHookFacet.postDeploy()` uses `IDiamondFactoryPackage.postDeploy.selector` to call back into the factory. Consider using a factory-specific interface/selector to reduce confusion and accidental coupling.
**Affected Files:**
- contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol
**User Response:** (pending)
**Notes:** Not a correctness bug today because the signature matches, but it’s surprising.

---

## Review Summary

**Findings:** 5 (3 High, 2 Medium+)
**Suggestions:** 5
**Recommendation:** Do not treat the Diamond package/proxy system as production-ready until ERC2535Repo remove/replace issues are fixed and the missing end-to-end factory deployment tests are added.

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
