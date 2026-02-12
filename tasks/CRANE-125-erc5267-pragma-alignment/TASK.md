# Task CRANE-125: Align ERC5267 Integration Test Pragma with Repo Version

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-065
**Worktree:** `fix/erc5267-pragma-alignment`
**Origin:** Code review suggestion from CRANE-065

---

## Description

Bump `pragma solidity ^0.8.0` to `pragma solidity ^0.8.30` (or the project's pinned version) for consistency across the test suite.

(Created from code review of CRANE-065)

## Dependencies

- CRANE-065: Add ERC5267 Diamond Proxy Integration Test (parent task)

## User Stories

### US-CRANE-125.1: Pragma Alignment

As a developer, I want the ERC-5267 integration test to use the project's standard Solidity version so that the test suite has consistent compiler settings.

**Acceptance Criteria:**
- [ ] Update pragma from ^0.8.0 to ^0.8.30 (or project standard)
- [ ] Verify test compiles cleanly with updated pragma
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/utils/cryptography/ERC5267/ERC5267ProxyIntegration.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-065 is complete
- [ ] ERC5267ProxyIntegration.t.sol exists
- [ ] Project standard pragma version is identified

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
