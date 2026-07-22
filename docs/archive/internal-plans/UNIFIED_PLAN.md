# Unified Development Plan — Crane

This document tracks all planned work and review tasks for the Crane framework.
Work is segmented into parallel worktrees for independent agent execution.

**Last Updated:** 2026-01-12

## Worktree Status

Worktrees are created on-demand when launching an agent via `/backlog:launch <task-number>`.

| Task | Worktree | Status |
|------|----------|--------|
| C-1 | `review/crn-create3-factory-and-determinism` | 🔧 Ready for agent |
| C-2 | `review/crn-diamond-package-and-proxy-correctness` | 🔧 Ready for agent |
| C-3 | `review/crn-test-framework-and-ifacet-pattern` | 🔧 Ready for agent |
| C-4 | `review/crn-dex-utils-slipstream-uniswap` | 🔧 Ready for agent |
| C-5 | `review/crn-token-standards-eip712-permit` | 🔧 Ready for agent |
| C-6 | `review/crn-constprodutils-and-bonding-math` | 🔧 Ready for agent |

---

## Task C-1: Review — CREATE3 Factory and Deterministic Deployment Correctness

**Layer:** Crane
**Worktree:** `review/crn-create3-factory-and-determinism`
**Status:** Ready for Agent

### Description
Review Crane’s CREATE3 factory stack and deterministic deployment helpers for correctness and adequate coverage. The goal is to raise confidence in the deployment guarantees that IndexedEx depends on.

### Dependencies
- None

### User Stories

**US-C1.1: Produce a determinism review memo**
As a maintainer, I want a clear description of determinism invariants and failure modes so that downstream deployments are trustworthy.

Acceptance Criteria:
- Memo explains salt derivation/normalization rules
- Memo identifies replay/idempotency assumptions
- Memo lists collision/address reuse behaviors

**US-C1.2: Add at least one missing negative test**
As a maintainer, I want at least one concrete test that fails when determinism invariants are violated so that regressions are caught.

Acceptance Criteria:
- Add at least one negative test (revert/edge case) related to deployment determinism
- `forge test` passes

### Files to Create/Modify

**New Files:**
- `docs/review/create3-and-determinism.md` - Review memo + test gap list

**Potentially Modified Files:**
- `test/foundry/**` - Add/strengthen tests around CREATE3 deployment

### Inventory Check (Agent must verify)
- [ ] Identify CREATE3 factory entrypoints under `contracts/factories/create3/**`
- [ ] Identify any helper libraries used by downstream scripts

### Completion Criteria
- Memo exists
- At least one meaningful test improvement included
- `forge build` and `forge test` pass

---

## Task C-2: Review — Diamond Package and Proxy Architecture Correctness

**Layer:** Crane
**Worktree:** `review/crn-diamond-package-and-proxy-correctness`
**Status:** Ready for Agent

### Description
Review the Diamond package factories, callback wiring, and proxy mechanisms for correctness and adequate coverage, focusing on selector registration and upgrade/initialization safety.

### Dependencies
- None

### User Stories

**US-C2.1: Produce an architecture + risk memo**
As a maintainer, I want a clear description of the Diamond wiring invariants so that downstream packages/proxies remain safe.

Acceptance Criteria:
- Memo identifies selector collision risks and protections
- Memo documents initialization/post-deploy hooks and invariants

### Files to Create/Modify

**New Files:**
- `docs/review/diamond-package-and-proxy.md` - Review memo

### Inventory Check (Agent must verify)
- [ ] Review `contracts/factories/diamondPkg/**`
- [ ] Review `contracts/proxies/**`

### Completion Criteria
- Memo exists

---

## Task C-3: Review — Test Framework and IFacet Pattern Trust Audit

**Layer:** Crane
**Worktree:** `review/crn-test-framework-and-ifacet-pattern`
**Status:** Ready for Agent

### Description
Audit Crane’s test framework and IFacet test pattern for trustworthiness, ensuring tests enforce interface/selector correctness and include negative cases.

### Dependencies
- None

### User Stories

**US-C3.1: Produce a test-quality memo**
As a maintainer, I want a clear analysis of how tests are structured and what they guarantee so that green builds mean real safety.

Acceptance Criteria:
- Memo identifies weak assertions and missing negative tests
- Memo recommends concrete improvements

### Files to Create/Modify

**New Files:**
- `docs/review/test-framework-quality.md` - Review memo

### Completion Criteria
- Memo exists

---

## Task C-4: Review — DEX Utilities Used by IndexedEx (Slipstream + Uniswap)

**Layer:** Crane
**Worktree:** `review/crn-dex-utils-slipstream-uniswap`
**Status:** Ready for Agent

### Description
Review Crane’s DEX utility surfaces used by IndexedEx vaults (Slipstream/Aerodrome, Uniswap V2/V3/V4). Focus on quote correctness, rounding, revert expectations, and test coverage.

### Dependencies
- None

### User Stories

**US-C4.1: Produce a DEX utilities correctness memo**
As a maintainer, I want a clear summary of quote correctness assumptions and edge cases so that downstream vault logic can be trusted.

Acceptance Criteria:
- Memo lists key invariants and edge cases per DEX
- Memo lists missing tests and recommended suites (unit/spec/fuzz)

### Files to Create/Modify

**New Files:**
- `docs/review/dex-utils.md` - Review memo

### Completion Criteria
- Memo exists

---

## Task C-5: Review — Token Standards (ERC20 facets, Permit, EIP-712 / ERC-5267)

**Layer:** Crane
**Worktree:** `review/crn-token-standards-eip712-permit`
**Status:** Ready for Agent

### Description
Review Crane token facets and cryptography utilities for signature correctness and coverage (domain separation, replay protections, chainId behaviors).

### Dependencies
- None

### User Stories

**US-C5.1: Produce a token standards correctness memo**
As a maintainer, I want a clear summary of signature and domain invariants so that token integrations are safe.

Acceptance Criteria:
- Memo documents domain separation and replay protections
- Memo lists missing tests

### Files to Create/Modify

**New Files:**
- `docs/review/token-standards.md` - Review memo

### Completion Criteria
- Memo exists

---

## Task C-6: Review — Constant Product & Bonding Math Utilities (ConstProdUtils)

**Layer:** Crane
**Worktree:** `review/crn-constprodutils-and-bonding-math`
**Status:** Ready for Agent

### Description
Review Crane’s constant-product and bonding math utilities (especially `contracts/utils/math/ConstProdUtils.sol`) for rounding correctness, overflow safety, invariant preservation, and adequate test coverage.

This task exists as a prerequisite for downstream protocol components (e.g., bonding/exchange flows) that rely on these math primitives.

### Dependencies
- None

### User Stories

**US-C6.1: Produce a math correctness memo**
As a maintainer, I want a memo describing the math invariants and edge cases so that downstream protocol logic can rely on these utilities.

Acceptance Criteria:
- Memo lists key invariants, rounding modes, and overflow/underflow assumptions
- Memo identifies any surprising behaviors (e.g., boundary conditions at 0/1 reserves)

**US-C6.2: Add at least one high-signal test**
As a maintainer, I want at least one concrete test improvement around math edge cases so that regressions are caught.

Acceptance Criteria:
- Add/strengthen at least one unit/spec/fuzz test that covers a boundary or adversarial case
- `forge test` passes

### Files to Create/Modify

**New Files:**
- `docs/review/constprodutils-and-bonding-math.md` - Review memo

**Potentially Modified Files:**
- `test/foundry/**` - Add/strengthen tests

### Inventory Check (Agent must verify)
- [ ] Identify all public entrypoints/consumers of `ConstProdUtils`
- [ ] Identify any assumptions about fee units, precision, or scaling factors

### Completion Criteria
- Memo exists
- At least one meaningful test improvement included
- `forge build` and `forge test` pass
