# Task CRANE-195: Make lib/reclamm Submodule Removal Possible

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-01
**Dependencies:** CRANE-149
**Worktree:** `fix/reclamm-submodule-removal-enablement`
**Origin:** Code review suggestion from CRANE-149

---

## Description

Stop resolving Balancer v3 dependencies via `lib/reclamm`. The ported ReClaMM contracts in `contracts/protocols/dexes/balancer/v3/reclamm/**` still import `@balancer-labs/v3-*`, and current remappings route those packages through `lib/reclamm/...`. Until this is fixed, removing the `lib/reclamm` submodule (CRANE-188) will break compilation.

Either:
- (a) Move/vend the needed Balancer v3 monorepo packages into a dedicated repo path (e.g., `lib/balancer-v3-monorepo/` or `contracts/external/balancer-v3/`) and update `remappings.txt`, or
- (b) Convert ReClaMM imports to use Crane-owned interfaces/contracts that do not re-export from `@balancer-labs/v3-*`

Note: `contracts/interfaces/protocols/dexes/balancer/v3/IVault.sol` currently re-exports the upstream interface via `@balancer-labs/v3-interfaces`.

(Created from code review of CRANE-149)

## Dependencies

- CRANE-149: Fork ReClaMM Pool to Local Contracts (parent task)

## Recommendation

Prefer (a): vend the minimal required `@balancer-labs/v3-*` packages into a dedicated location (e.g. `lib/balancer-v3-monorepo/` or `contracts/external/balancer-v3/`) and update remappings accordingly. This reduces churn in the ported ReClaMM code and keeps upstream namespace expectations intact.

## User Stories

### US-CRANE-195.1: Eliminate lib/reclamm Dependency

As a developer, I want the ReClaMM contracts to compile without `lib/reclamm` so that the submodule can be safely removed.

**Acceptance Criteria:**
- [ ] ReClaMM contracts compile without `lib/reclamm` submodule present
- [ ] remappings.txt no longer resolves `@balancer-labs/v3-*` via `lib/reclamm/**`
- [ ] If vendoring is used, vendored Balancer v3 packages are pinned to a specific upstream commit/tag (previously pinned submodule commit: ddb0d82de24a9db960d90b33649203e2462cf1c9)
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

## Suggested Verification

```bash
# Verify no remappings route through lib/reclamm
rg "lib/reclamm" remappings.txt foundry.toml

# Build should succeed even if lib/reclamm is missing
forge build
forge test
```

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
