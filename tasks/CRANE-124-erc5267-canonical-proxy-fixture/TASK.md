# Task CRANE-124: Use Canonical Proxy Fixture for ERC5267 Integration Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-17
**Dependencies:** CRANE-065
**Worktree:** `refactor/erc5267-canonical-proxy`
**Origin:** Code review suggestion from CRANE-065

---

## Description

If/when a lightweight fixture exists for deploying a real Diamond proxy (via the callback factory), switch the ERC-5267 integration test to use it. That would ensure the ERC-5267 verifyingContract invariant holds through the exact production routing path.

(Created from code review of CRANE-065)

## Dependencies

- CRANE-065: Add ERC5267 Diamond Proxy Integration Test (parent task)

## User Stories

### US-CRANE-124.1: Canonical Proxy Fixture

As a developer, I want the ERC-5267 integration test to use the canonical Diamond proxy deployment path so that the test validates behavior through the exact production routing mechanics.

**Acceptance Criteria:**
- [ ] Replace DiamondProxyStub with canonical proxy fixture (if available)
- [ ] Use DiamondPackageCallBackFactory / MinimalDiamondCallBackProxy deployment path
- [ ] Verify ERC-5267 verifyingContract invariant holds through production routing
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/utils/cryptography/ERC5267/ERC5267ProxyIntegration.t.sol

## Inventory Check

Before starting, verify:
- [ ] CRANE-065 is complete
- [ ] Canonical proxy fixture exists or can be created
- [ ] ERC5267ProxyIntegration.t.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
