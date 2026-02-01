# Task CRANE-195: Make lib/reclamm Submodule Removal Possible

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-01
**Dependencies:** CRANE-149
**Worktree:** `fix/reclamm-submodule-removal-enablement`
**Origin:** Code review suggestion from CRANE-149

---

## Description

Stop resolving Balancer v3 dependencies via `lib/reclamm`. The ported ReClaMM contracts in `contracts/protocols/dexes/balancer/v3/reclamm/**` still import `@balancer-labs/v3-*`, so removing the `lib/reclamm` submodule will break compilation.

Either:
- (a) Move/vend the needed Balancer v3 monorepo packages into a dedicated repo path (e.g., `lib/balancer-v3-monorepo/` or `contracts/external/balancer-v3/`) and update `remappings.txt`, or
- (b) Convert ReClaMM imports to use Crane-owned interfaces/contracts that do not re-export from `@balancer-labs/v3-*`

Note: `contracts/interfaces/protocols/dexes/balancer/v3/IVault.sol` currently re-exports the upstream interface via `@balancer-labs/v3-interfaces`.

(Created from code review of CRANE-149)

## Dependencies

- CRANE-149: Fork ReClaMM Pool to Local Contracts (parent task)

## User Stories

### US-CRANE-195.1: Eliminate lib/reclamm Dependency

As a developer, I want the ReClaMM contracts to compile without `lib/reclamm` so that the submodule can be safely removed.

**Acceptance Criteria:**
- [ ] ReClaMM contracts compile without `lib/reclamm` submodule
- [ ] Remappings updated to use local/vendored Balancer v3 packages
- [ ] All imports resolved to Crane-owned paths
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `remappings.txt`
- `contracts/protocols/dexes/balancer/v3/reclamm/ReClammPool.sol`
- `contracts/protocols/dexes/balancer/v3/reclamm/ReClammPoolExtension.sol`
- `contracts/protocols/dexes/balancer/v3/reclamm/ReClammPoolFactory.sol`
- `contracts/interfaces/protocols/dexes/balancer/v3/IVault.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-149 is complete
- [ ] Affected files exist

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
