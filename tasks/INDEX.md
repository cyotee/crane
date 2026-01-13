# Task Index: Crane Framework

**Repo:** CRANE
**Last Updated:** 2026-01-12

## Active Tasks

| ID | Title | Status | Dependencies | Worktree |
|----|-------|--------|--------------|----------|
| CRANE-001 | CREATE3 Factory and Deterministic Deployment Review | Complete | None | `review/crn-create3-factory-and-determinism` |
| CRANE-002 | Diamond Package and Proxy Architecture Review | Complete | None | `review/crn-diamond-package-and-proxy-correctness` |
| CRANE-003 | Test Framework and IFacet Pattern Audit | Pending Merge | None | `review/crn-test-framework-and-ifacet-pattern` |
| CRANE-005 | Token Standards Review (ERC20, Permit, EIP-712) | Ready | None | `review/crn-token-standards-eip712-permit` |
| CRANE-006 | Constant Product & Bonding Math Review | Ready | None | `review/crn-constprodutils-and-bonding-math` |
| CRANE-007 | Uniswap V2 Utilities Review | Blocked | CRANE-006 | `review/crn-uniswap-v2-utils` |
| CRANE-008 | Uniswap V3 Utilities Review | Blocked | CRANE-007 | `review/crn-uniswap-v3-utils` |
| CRANE-009 | Uniswap V4 Utilities Review | Blocked | CRANE-008 | `review/crn-uniswap-v4-utils` |
| CRANE-010 | Aerodrome V1 Utilities Review | Blocked | CRANE-006 | `review/crn-aerodrome-v1-utils` |
| CRANE-011 | Slipstream Utilities Review | Blocked | CRANE-010 | `review/crn-slipstream-utils` |
| CRANE-012 | Camelot V2 Utilities Review | Blocked | CRANE-006 | `review/crn-camelot-v2-utils` |
| CRANE-013 | Balancer V3 Utilities Review | Ready | None | `review/crn-balancer-v3-utils` |
| CRANE-014 | Fix ERC2535 Remove/Replace Correctness | Ready | CRANE-002 | `fix/erc2535-remove-replace` |
| CRANE-015 | Fix ERC165Repo Overload Bug | Ready | CRANE-002 | `fix/erc165-overload` |
| CRANE-016 | Add End-to-End Factory Deployment Tests | Ready | CRANE-002 | `test/factory-e2e` |

## Status Legend

- **Ready** - All dependencies met, can be launched with `/backlog:launch`
- **In Progress** - Implementation agent working (has worktree)
- **In Review** - Implementation complete, awaiting code review
- **Changes Requested** - Review found issues, needs fixes
- **Pending Merge** - Approved and rebased, ready for fast-forward merge
- **Complete** - Review passed, ready to archive with `/backlog:prune`
- **Blocked** - Waiting on dependencies

## Quick Filters

### Complete

**Core Framework (2 tasks):**
- CRANE-001: CREATE3 Factory and Deterministic Deployment Review
- CRANE-002: Diamond Package and Proxy Architecture Review

### Pending Merge

- CRANE-003: Test Framework and IFacet Pattern Audit

### Ready for Agent

**Core Framework (6 tasks):**
- CRANE-005: Token Standards Review (ERC20, Permit, EIP-712)
- CRANE-006: Constant Product & Bonding Math Review
- CRANE-013: Balancer V3 Utilities Review
- CRANE-014: Fix ERC2535 Remove/Replace Correctness (from CRANE-002)
- CRANE-015: Fix ERC165Repo Overload Bug (from CRANE-002)
- CRANE-016: Add End-to-End Factory Deployment Tests (from CRANE-002)

### Blocked

**DEX Protocols (waiting on CRANE-006 math review):**
- CRANE-007: Uniswap V2 → depends on CRANE-006
- CRANE-008: Uniswap V3 → depends on CRANE-007
- CRANE-009: Uniswap V4 → depends on CRANE-008
- CRANE-010: Aerodrome V1 → depends on CRANE-006
- CRANE-011: Slipstream → depends on CRANE-010
- CRANE-012: Camelot V2 → depends on CRANE-006

## Retired Tasks

| ID | Reason |
|----|--------|
| CRANE-004 | Split into per-DEX per-version tasks (CRANE-007 through CRANE-013) |

## Cross-Repo Dependencies

Tasks in other repos that depend on this repo's tasks:
- (none yet)
