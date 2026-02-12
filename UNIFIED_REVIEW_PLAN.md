# Unified Review Plan — Crane (DEPRECATED)

This file has been superseded by `UNIFIED_PLAN.md` in this repo.
Use `UNIFIED_PLAN.md` Task C-1..C-5 for review execution.

This document defines **review tasks** (correctness + test coverage/quality) for the Crane repo.
These tasks must not modify IndexedEx code; IndexedEx review tasks live in `indexedex/UNIFIED_REVIEW_PLAN.md`.

## How this relates to IndexedEx
IndexedEx depends on Crane heavily (factories, proxies, facets, and DEX utilities). The goal here is to raise confidence that the Crane primitives used by IndexedEx are correct and adequately tested.

## Gates (must-pass for any change)
- `crane`: `forge build` and `forge test`

## Worktree Status

| Task | Worktree | Status |
|------|----------|--------|
| 1 | `review/crn-create3-factory-and-determinism` | 🔧 Ready for agent |
| 2 | `review/crn-diamond-package-and-proxy-correctness` | 🔧 Ready for agent |
| 3 | `review/crn-test-framework-and-ifacet-pattern` | 🔧 Ready for agent |
| 4 | `review/crn-dex-utils-slipstream-uniswap` | 🔧 Ready for agent |
| 5 | `review/crn-token-standards-eip712-permit` | 🔧 Ready for agent |
| 6 | `review/crn-constprodutils-and-bonding-math` | 🔧 Ready for agent |

---

## Task 6: Constant Product & Bonding Math Utilities (ConstProdUtils)

NOTE: Canonical tracking is in `UNIFIED_PLAN.md` as **Task C-6**.

**Layer:** Crane
**Worktree:** `review/crn-constprodutils-and-bonding-math`
**Status:** Ready for Agent

### Scope
- `contracts/utils/math/ConstProdUtils.sol`
- Any other math helpers used by DEX utils and downstream protocol logic

### Deliverables
- Review memo: `docs/review/constprodutils-and-bonding-math.md`
- Missing-test list + at least one concrete test improvement proposal

### Completion criteria
- Memo exists and lists key invariants + boundary cases
- At least one high-signal test improvement is implemented (or a concrete blocker is recorded)

---

## Task 1: CREATE3 Factory & Deterministic Deployment Correctness

**Layer:** Crane
**Worktree:** `review/crn-create3-factory-and-determinism`
**Status:** Ready for Agent

### Scope
- `contracts/factories/create3/**`
- Any wrappers/helpers that IndexedEx uses for deterministic deployment
- Existing tests and scripts that validate determinism

### Deliverables
- Review memo: `docs/review/create3-and-determinism.md`
- A list of missing tests (e.g., collision handling, salt derivation invariants, replay/idempotency)

### Inventory checks
- Identify all public deployment entrypoints.
- Identify how salts are derived/normalized.
- Identify whether the factory enforces codehash expectations.

---

## Task 2: Diamond Package + Proxy Architecture Correctness

**Layer:** Crane
**Worktree:** `review/crn-diamond-package-and-proxy-correctness`
**Status:** Ready for Agent

### Scope
- `contracts/factories/diamondPkg/**`
- `contracts/proxies/**`
- Facet/package metadata patterns used for programmatic wiring

### Deliverables
- Review memo: `docs/review/diamond-package-and-proxy.md`
- Test-gap list, especially around upgrade safety and selector mapping

### Inventory checks
- Identify invariants for facet registration and selector collisions.
- Identify upgrade/initialization flows and post-deploy hooks.

---

## Task 3: Test Framework & IFacet Pattern Trust Audit

**Layer:** Crane
**Worktree:** `review/crn-test-framework-and-ifacet-pattern`
**Status:** Ready for Agent

### Scope
- `test/foundry/**` and any base test contracts under `contracts/test/**`
- IFacet test pattern expectations (interfaces + selectors)

### Deliverables
- Review memo: `docs/review/test-framework-quality.md`
- Recommendations to make tests more trustworthy (reduce false positives, add negative tests, improve assertions)

---

## Task 4: DEX Utilities Used by IndexedEx (Slipstream + Uniswap)

**Layer:** Crane
**Worktree:** `review/crn-dex-utils-slipstream-uniswap`
**Status:** Ready for Agent

### Scope
- DEX utility repos and Crane adapters used by IndexedEx vaults:
  - Slipstream / Aerodrome quoting helpers
  - Uniswap V2/V3/V4 utilities
- Any tests covering quote correctness, rounding, and edge cases

### Deliverables
- Review memo: `docs/review/dex-utils.md`
- A prioritized list of new tests (unit/spec/fuzz) to support IndexedEx vault correctness

---

## Task 5: Token Standards (ERC20 Facets, Permit, EIP-712 / ERC-5267)

**Layer:** Crane
**Worktree:** `review/crn-token-standards-eip712-permit`
**Status:** Ready for Agent

### Scope
- `contracts/tokens/**`
- `contracts/utils/cryptography/**` (EIP-712, ERC-5267)

### Deliverables
- Review memo: `docs/review/token-standards.md`
- Test-gap list for signature correctness, domain separation, replay protections
