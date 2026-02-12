# Task CRANE-243: Extract Shared Vault Test Mocks to TestBase

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-07
**Dependencies:** CRANE-161
**Worktree:** `refactor/CRANE-243-extract-vault-test-mocks`
**Origin:** Code review suggestion from CRANE-161

---

## Description

Move `MockAuthorizer` and `MockProtocolFeeController` (currently duplicated in `BalancerV3VaultDFPkg.t.sol` and `BalancerV3RouterVaultIntegration.t.sol`) into a shared location. Both test files define nearly identical mock contracts with different prefixes to avoid naming collisions. These should be extracted to the existing `TestBase_BalancerV3Vault.sol` or a shared test bases directory.

(Created from code review of CRANE-161)

## Dependencies

- CRANE-161: Resolve Vault Loupe and Router Integration (parent task) - Complete

## User Stories

### US-CRANE-243.1: Extract Duplicated Mock Contracts

As a developer, I want shared vault test mocks in a single location so that mock behavior changes only need to be made once and test files don't accumulate duplicate contract definitions.

**Acceptance Criteria:**
- [ ] `MockAuthorizer` defined in exactly one location (TestBase or shared file)
- [ ] `MockProtocolFeeController` defined in exactly one location
- [ ] `BalancerV3VaultDFPkg.t.sol` imports shared mocks instead of defining its own
- [ ] `BalancerV3RouterVaultIntegration.t.sol` imports shared mocks instead of defining its own
- [ ] `IntegrationMockAuthorizer` and `IntegrationMockProtocolFeeController` removed
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDFPkg.t.sol` - Remove inline mocks, import shared
- `test/foundry/spec/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterVaultIntegration.t.sol` - Remove inline mocks, import shared
- `contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3Vault.sol` - Add shared mock definitions (or create new shared file)

## Inventory Check

Before starting, verify:
- [ ] CRANE-161 is complete
- [ ] Both test files exist with duplicate mocks
- [ ] TestBase_BalancerV3Vault.sol exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] No duplicate mock contract definitions across test files
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
