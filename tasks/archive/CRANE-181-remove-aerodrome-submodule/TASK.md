# Task CRANE-181: Remove lib/aerodrome-contracts Submodule

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-148
**Worktree:** `chore/remove-aerodrome-submodule`
**Origin:** Code review of CRANE-148

---

## Description

Now that CRANE-148 has verified the complete port of Aerodrome V1 contracts to `contracts/protocols/dexes/aerodrome/v1/`, the `lib/aerodrome-contracts` submodule can be safely removed. This reduces repository size and eliminates external dependencies for Aerodrome functionality.

## Dependencies

- CRANE-148: Verify Aerodrome Contract Port Completeness ✓ (Complete)

## User Stories

### US-CRANE-181.1: Remove Aerodrome Submodule

As a developer, I want to remove the lib/aerodrome-contracts submodule so that the repository is cleaner and we don't have external dependencies for Aerodrome functionality.

**Acceptance Criteria:**
- [ ] Remove lib/aerodrome-contracts submodule entry from .gitmodules
- [ ] Remove lib/aerodrome-contracts directory
- [ ] Update foundry.toml remappings (remove aerodrome submodule paths if any)
- [ ] Verify no direct imports from submodule remain
- [ ] All existing tests still pass
- [ ] Build succeeds

## Technical Details

### Pre-Removal Verification

Before removing, verify the port completeness from CRANE-148:
- Pool contracts: Pool.sol, PoolFees.sol
- Factory contracts: PoolFactory.sol
- Router contracts: Router.sol
- All interfaces ported
- All libraries ported

### Files to Modify

**Modified Files:**
- `.gitmodules` - Remove aerodrome-contracts entry
- `foundry.toml` - Remove any aerodrome remappings pointing to submodule

**Removed Files:**
- `lib/aerodrome-contracts/` - Entire submodule

### Removal Commands

```bash
# Remove submodule entry from .gitmodules
git submodule deinit -f lib/aerodrome-contracts

# Remove from git's module tracking
rm -rf .git/modules/lib/aerodrome-contracts

# Remove the directory
rm -rf lib/aerodrome-contracts

# Stage the removal
git add .gitmodules lib/aerodrome-contracts

# Verify build
forge build

# Run tests
forge test
```

## Inventory Check

Before starting, verify:
- [x] CRANE-148 is complete
- [ ] All imports use local port paths (not submodule)
- [ ] Build passes with current remappings
- [ ] Tests pass with current remappings

## Completion Criteria

- [ ] Submodule removed from .gitmodules
- [ ] lib/aerodrome-contracts directory deleted
- [ ] Remappings updated
- [ ] All tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
