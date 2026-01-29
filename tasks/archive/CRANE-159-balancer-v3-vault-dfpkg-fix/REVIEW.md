# Code Review: CRANE-159

**Reviewer:** OpenCode
**Review Started:** 2026-01-29
**Status:** Complete

---

## Clarifying Questions

Questions asked to understand review criteria:

- None.

---

## Review Findings

### Finding 1: Duplicate pool-token read functions still exist in PoolToken facet
**File:** `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultPoolTokenFacet.sol`
**Severity:** Medium
**Description:**
- `VaultPoolTokenFacet.facetFuncs()` correctly exposes only `transfer` and `transferFrom`.
- However, `VaultPoolTokenFacet` still defines `totalSupply`, `balanceOf`, `allowance`, `approve` (which are intended to live in `VaultQueryFacet`, and are not part of `IVaultMain`).
- Because these extra functions are not included in `facetFuncs()`, they are not routed by the Diamond today, but they increase confusion and create future collision risk if someone later adds selectors to the wrong facet.
**Status:** Open
**Resolution:**
- Remove `totalSupply`, `balanceOf`, `allowance`, `approve` from `VaultPoolTokenFacet` and keep them only in `VaultQueryFacet`.

### Finding 2: Query facet contains non-routed admin-ish functions
**File:** `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultQueryFacet.sol`
**Severity:** Low
**Description:**
- `VaultQueryFacet` defines `isVaultPaused()` and `isQueryDisabled()`.
- These selectors are not returned by `VaultQueryFacet.facetFuncs()` (so they are not part of the Diamond surface), and similar functionality also exists on the admin facet.
- Keeping non-routed/duplicate surface functions in a facet contract makes future selector maintenance error-prone.
**Status:** Open
**Resolution:**
- Remove `isVaultPaused()` / `isQueryDisabled()` from `VaultQueryFacet` (or ensure there is a single canonical home and the other copies do not exist).

### Finding 3: TASK.md expects a VaultLoupeFacet, but implementation relies on factory loupe
**File:** `tasks/CRANE-159-balancer-v3-vault-dfpkg-fix/TASK.md`
**Severity:** Medium
**Description:**
- US-CRANE-159.5 acceptance criteria explicitly requires creating `VaultLoupeFacet.sol` and bundling it in the Vault DFPkg.
- In this branch there is no `VaultLoupeFacet.sol`; loupe support is provided via the factory-supplied `DiamondLoupeFacet` (and Vault tests assert `IDiamondLoupe` routing).
- This is either a deliberate deviation or a requirements mismatch that should be resolved.
**Status:** Open
**Resolution:**
- Either (A) update `TASK.md` to reflect the factory-provided loupe facet approach, or (B) implement `VaultLoupeFacet.sol` and include it in `BalancerV3VaultDFPkg`.

### Finding 4: Router DFPkg tests still use a MockVault (integration criterion not met)
**File:** `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterDFPkg.t.sol`
**Severity:** Medium
**Description:**
- US-CRANE-159.7 requires updating Router tests to deploy/use the real `BalancerV3VaultDFPkg`.
- Current test file defines and uses `MockVault` and does not import/deploy the Vault DFPkg.
- This means Router-Vault integration is not being exercised end-to-end.
**Status:** Open
**Resolution:**
- Update router tests to deploy a real Vault Diamond via `BalancerV3VaultDFPkg`, and point the router to it (or explicitly mark US-CRANE-159.7 as deferred/optional in `TASK.md`).

### Finding 5: Some IVaultExtension functions are implemented as placeholders
**File:** `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultQueryFacet.sol`
**Severity:** Low
**Description:**
- `getBptRate()` currently returns `1e18` as a placeholder.
- `quote()` / `quoteAndRevert()` are implemented via a direct callback and do not model Balancer v3's full unlock/transient settlement behavior (they may be sufficient for selector compatibility tests but not for behavioral correctness).
**Status:** Open
**Resolution:**
- Either document these as intentionally non-production/compat-only implementations, or implement the real behavior (including settlement checks) if the goal is functional parity beyond selector coverage.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Remove non-routed duplicate selectors from facets
**Priority:** High
**Description:**
- Align facet code with `facetFuncs()` intent: keep pool-token reads/approve only in `VaultQueryFacet`, keep `IVaultMain` write funcs only in `VaultPoolTokenFacet`, and avoid extra duplicate public/external functions that are not routed.
**Affected Files:**
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultPoolTokenFacet.sol`
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultQueryFacet.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-160

### Suggestion 2: Resolve TASK.md vs implementation mismatch (loupe + router integration)
**Priority:** High
**Description:**
- Decide whether US-CRANE-159.5/159.7 are required for completion. If not required, update `TASK.md` to match the implemented approach (factory-provided loupe, router tests deferred). If required, implement missing pieces.
**Affected Files:**
- `tasks/CRANE-159-balancer-v3-vault-dfpkg-fix/TASK.md`
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterDFPkg.t.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-161

---

## Review Summary

**Findings:** 5 (2 medium, 3 low)
**Suggestions:** 2
**Recommendation:** Request changes (or update `TASK.md`) to resolve acceptance mismatches and remove duplicate/non-routed facet functions.

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
