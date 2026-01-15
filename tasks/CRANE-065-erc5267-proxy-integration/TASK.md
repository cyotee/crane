# Task CRANE-065: Add ERC5267 Diamond Proxy Integration Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-14
**Dependencies:** CRANE-023
**Worktree:** `test/erc5267-proxy-integration`
**Origin:** Code review suggestion from CRANE-023

---

## Description

Add an integration test that calls `eip712Domain()` through a Diamond proxy and asserts `verifyingContract` equals the proxy address, confirming correct delegatecall semantics.

(Created from code review of CRANE-023)

## Dependencies

- CRANE-023: Add ERC-5267 Test Coverage (parent task) - Complete

## User Stories

### US-CRANE-065.1: Delegatecall Verification

As a developer, I want an integration test that verifies `eip712Domain()` returns the correct `verifyingContract` when called through a Diamond proxy so that EIP-712 signatures are validated against the correct address.

**Acceptance Criteria:**
- [ ] Integration test calls `eip712Domain()` through Diamond proxy
- [ ] Test asserts `verifyingContract == address(proxy)`
- [ ] Test uses existing proxy fixture if available, or creates minimal one
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**New Files:**
- `test/foundry/integration/ERC5267/ERC5267ProxyIntegration.t.sol` (or adjacent location)

**Reference Files:**
- Existing Diamond proxy fixtures in test suite

## Inventory Check

Before starting, verify:
- [ ] CRANE-023 is complete
- [ ] Diamond proxy test fixtures exist
- [ ] ERC5267Facet is deployable to proxy

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
