# Task CRANE-266: Remove Unused BALANCER_V3_VAULT_AWARE_SLOT Constant

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-119
**Worktree:** `fix/CRANE-266-remove-unused-vault-aware-slot-constant`
**Origin:** Code review suggestion from CRANE-119 (Suggestion 1)

---

## Description

Remove the unused file-level constant `BALANCER_V3_VAULT_AWARE_SLOT` and its section comment (lines 66-69) from the integration test file. This is dead code left over from development.

(Created from code review of CRANE-119)

## Dependencies

- CRANE-119: Add Proxy-State Assertions for Pool/Vault-Aware Repos (parent task)

## User Stories

### US-CRANE-266.1: Remove unused constant

As a developer, I want unused constants removed from test files so that the codebase stays clean and doesn't mislead future readers.

**Acceptance Criteria:**
- [ ] `BALANCER_V3_VAULT_AWARE_SLOT` constant and its comment block are removed
- [ ] No references to the removed constant exist in the file
- [ ] All existing tests pass
- [ ] `forge build` succeeds

## Files to Create/Modify

**Modified Files:**
- test/foundry/spec/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg_Integration.t.sol (lines 66-69)

## Inventory Check

Before starting, verify:
- [ ] CRANE-119 is complete
- [ ] The constant exists and is unused

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] `forge test` passes
- [ ] `forge build` succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
