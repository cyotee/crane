# Task Index: Crane Framework

**Repo:** CRANE
**Last Updated:** 2026-01-13

## Active Tasks

| ID | Title | Status | Dependencies | Worktree |
|----|-------|--------|--------------|----------|
| CRANE-010 | Aerodrome V1 Utilities Review | In Progress | None | `review/crn-aerodrome-v1-utils` |
| CRANE-011 | Slipstream Utilities Review | Ready | None | `review/crn-slipstream-utils` |
| CRANE-012 | Camelot V2 Utilities Review | Ready | None | `review/crn-camelot-v2-utils` |
| CRANE-013 | Balancer V3 Utilities Review | Ready | None | `review/crn-balancer-v3-utils` |
| CRANE-014 | Fix ERC2535 Remove/Replace Correctness | Ready | CRANE-002 | `fix/erc2535-remove-replace` |
| CRANE-015 | Fix ERC165Repo Overload Bug | Ready | CRANE-002 | `fix/erc165-overload` |
| CRANE-016 | Add End-to-End Factory Deployment Tests | Ready | CRANE-002 | `test/factory-e2e` |
| CRANE-017 | Add Negative Assertions to Test Framework | Ready | CRANE-003 | `fix/test-negative-assertions` |
| CRANE-018 | Improve Test Verification Rigor | Ready | CRANE-003 | `fix/test-verification-rigor` |
| CRANE-019 | Add Test Edge Cases and Cleanup | Ready | CRANE-003 | `fix/test-edge-cases` |
| CRANE-020 | Fix Critical ERC20 transferFrom Allowance Bypass | Ready | CRANE-005 | `fix/erc20-transferfrom-allowance` |
| CRANE-021 | Fix ERC5267Facet Array Size Bug | Ready | CRANE-005 | `fix/erc5267-array-size` |
| CRANE-022 | Rename EIP721_TYPE_HASH to EIP712_TYPE_HASH | Ready | CRANE-005 | `fix/eip712-typehash-typo` |
| CRANE-023 | Add ERC-5267 Test Coverage | Ready | CRANE-005 | `test/erc5267-coverage` |
| CRANE-024 | Harden Zap-Out Fee-On Input Validation | Ready | CRANE-006 | `fix/zapout-fee-validation` |
| CRANE-025 | Replace Fee-Denominator Heuristic | Ready | CRANE-006 | `fix/explicit-fee-denominator` |
| CRANE-026 | Strengthen Overflow Boundary Tests | Ready | CRANE-006 | `test/overflow-boundary-tests` |

## Status Legend

- **Ready** - All dependencies met, can be launched with `/backlog:launch`
- **In Progress** - Implementation agent working (has worktree)
- **In Review** - Implementation complete, awaiting code review
- **Changes Requested** - Review found issues, needs fixes
- **Pending Merge** - Approved and rebased, ready for fast-forward merge
- **Complete** - Review passed, ready to archive with `/backlog:prune`
- **Blocked** - Waiting on dependencies

## Quick Filters

### Ready for Agent

**DEX Protocol Reviews (4 tasks):**
- ~~CRANE-010: Aerodrome V1 Utilities Review~~ (In Progress)
- CRANE-011: Slipstream Utilities Review
- CRANE-012: Camelot V2 Utilities Review
- CRANE-013: Balancer V3 Utilities Review

**Core Framework (13 tasks):**
- CRANE-014: Fix ERC2535 Remove/Replace Correctness (from CRANE-002)
- CRANE-015: Fix ERC165Repo Overload Bug (from CRANE-002)
- CRANE-016: Add End-to-End Factory Deployment Tests (from CRANE-002)
- CRANE-017: Add Negative Assertions to Test Framework (from CRANE-003)
- CRANE-018: Improve Test Verification Rigor (from CRANE-003)
- CRANE-019: Add Test Edge Cases and Cleanup (from CRANE-003)
- **CRANE-020: Fix Critical ERC20 transferFrom Allowance Bypass (P0 - from CRANE-005)**
- CRANE-021: Fix ERC5267Facet Array Size Bug (from CRANE-005)
- CRANE-022: Rename EIP721_TYPE_HASH to EIP712_TYPE_HASH (from CRANE-005)
- CRANE-023: Add ERC-5267 Test Coverage (from CRANE-005)
- **CRANE-024: Harden Zap-Out Fee-On Input Validation (High - from CRANE-006)**
- CRANE-025: Replace Fee-Denominator Heuristic (from CRANE-006)
- CRANE-026: Strengthen Overflow Boundary Tests (from CRANE-006)

### Blocked

(No blocked tasks)

## Retired Tasks

| ID | Reason |
|----|--------|
| CRANE-004 | Split into per-DEX per-version tasks (CRANE-007 through CRANE-013) |

## Archived Tasks

| ID | Title | Completed | Location |
|----|-------|-----------|----------|
| CRANE-001 | CREATE3 Factory and Deterministic Deployment Review | 2026-01-13 | archive/CRANE-001-create3-factory-determinism/ |
| CRANE-002 | Diamond Package and Proxy Architecture Review | 2026-01-13 | archive/CRANE-002-diamond-package-proxy/ |
| CRANE-003 | Test Framework and IFacet Pattern Audit | 2026-01-13 | archive/CRANE-003-test-framework-ifacet/ |
| CRANE-005 | Token Standards Review (ERC20, Permit, EIP-712) | 2026-01-13 | archive/CRANE-005-token-standards-eip712-permit/ |
| CRANE-006 | Constant Product & Bonding Math Review | 2026-01-13 | archive/CRANE-006-constprodutils-bonding-math/ |
| CRANE-007 | Uniswap V2 Utilities Review | 2026-01-13 | archive/CRANE-007-uniswap-v2-utils/ |
| CRANE-008 | Uniswap V3 Utilities Review | 2026-01-13 | archive/CRANE-008-uniswap-v3-utils/ |
| CRANE-009 | Uniswap V4 Utilities Review | 2026-01-13 | archive/CRANE-009-uniswap-v4-utils/ |

## Cross-Repo Dependencies

Tasks in other repos that depend on this repo's tasks:
- (none yet)
