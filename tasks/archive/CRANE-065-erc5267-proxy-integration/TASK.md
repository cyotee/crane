# Task CRANE-065: Add ERC5267 Diamond Proxy Integration Test

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-14
**Completed:** 2026-01-17
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
- [x] Integration test calls `eip712Domain()` through Diamond proxy
- [x] Test asserts `verifyingContract == address(proxy)`
- [x] Test uses existing proxy fixture if available, or creates minimal one
- [x] Tests pass
- [x] Build succeeds

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/utils/cryptography/ERC5267/ERC5267ProxyIntegration.t.sol`

**Reference Files:**
- Existing Diamond proxy fixtures in test suite

## Inventory Check

Before starting, verify:
- [x] CRANE-023 is complete
- [x] Diamond proxy test fixtures exist
- [x] ERC5267Facet is deployable to proxy

## Completion Criteria

- [x] All acceptance criteria met
- [x] Tests pass
- [x] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
