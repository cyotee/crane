# Code Review: CRANE-146

**Reviewer:** OpenCode (AI)
**Review Started:** 2026-01-31
**Status:** In Progress

---

## Clarifying Questions

Questions asked to understand review criteria:

- None.

---

## Review Findings

### Finding 1: CoW pool/router implementation is untracked (not in git)
**File:** `contracts/protocols/dexes/balancer/v3/pools/cow/*` and `test/foundry/spec/protocols/balancer/v3/pools/cow/*`
**Severity:** Blocker
**Description:** The new CoW contracts and tests exist in the worktree but are currently untracked (`git status` shows them under `??`). This means the implementation is not part of the branch history and will not land in a PR/merge unless added.
**Status:** Open
**Resolution:** `git add` the new CoW files (and ensure they appear under `git ls-files`), then commit them.

### Finding 2: Missing initialization path for critical CoW storage
**File:** `contracts/protocols/dexes/balancer/v3/pools/cow/CowPoolRepo.sol`, `contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterRepo.sol`
**Severity:** Blocker
**Description:** `CowPoolRepo._initialize(...)` and `CowRouterRepo._initialize(...)` are internal-only and there are no on-chain/external entrypoints (e.g., DFPkg `initAccount()`/initializer facet) in this change-set that call them. As a result:
- `CowPoolTarget.onRegister(...)` will always fail (stored `cowPoolFactory` defaults to `address(0)`), preventing pool registration.
- `CowRouterTarget.withdrawCollectedProtocolFees(...)` depends on a configured `feeSweeper`; without initialization, the fee sweeper is zero.
**Status:** Open
**Resolution:** Add a deployment/init mechanism (DFPkg `initAccount()` or an initializer facet callable during deploy) that sets:
- `CowPoolRepo`: `cowPoolFactory`, `trustedCowRouter`
- `CowRouterRepo`: `protocolFeePercentage`, `feeSweeper`

### Finding 3: Test suite does not verify Diamond Vault integration behavior
**File:** `test/foundry/spec/protocols/balancer/v3/pools/cow/CowPoolFacet.t.sol`, `test/foundry/spec/protocols/balancer/v3/pools/cow/CowRouterFacet.t.sol`
**Severity:** Major
**Description:** Current tests validate deployability, bytecode size, and `IFacet` metadata only. They do not exercise:
- `CowPoolTarget.onRegister(...)` with real Vault registration inputs
- hook gating (`onBeforeSwap`, donation gating)
- `CowRouterTarget` unlock/settle flows against a Vault instance
This makes the acceptance-criteria statements about “Vault integration verified” effectively untested.
**Status:** Open
**Resolution:** Add behavior/integration tests that deploy a minimal Vault + pool/router diamond (or use existing protocol TestBases), initialize repos, and execute at least one swap+donate and donation-only path.

---

## Suggestions

Actionable items for follow-up tasks:

### Suggestion 1: Add DFPkg(s) (or initializer facet) for CoW pool + router
**Priority:** High
**Description:** Introduce a proper deployment story that wires required storage in `CowPoolRepo` and `CowRouterRepo` during diamond initialization (e.g., `IDiamondFactoryPackage.initAccount()`), and ensure it's covered by tests.
**Affected Files:**
- `contracts/protocols/dexes/balancer/v3/pools/cow/*`
- (new) `contracts/**/Cow*DFPkg*.sol` (or equivalent initializer facet)
**User Response:** Accepted
**Notes:** Converted to task CRANE-191. This also resolves Finding 2.

### Suggestion 2: Add input length validation in router settlement paths
**Priority:** Medium
**Description:** Consider explicit `require`/custom errors to enforce `donationAmounts.length == tokens.length` and `transferAmountHints.length == tokens.length` to avoid out-of-bounds reverts and to provide clearer failure modes.
**Affected Files:**
- `contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterTarget.sol`
**User Response:** Accepted
**Notes:** Converted to task CRANE-192. Safety/usability improvement; custom errors minimize bytecode impact.

---

## Review Summary

**Findings:** 2 Blockers, 1 Major
**Suggestions:** 2
**Recommendation:** Request changes (must fix untracked files + add init path)

---

**When review complete, output:** `<promise>REVIEW_COMPLETE</promise>`
