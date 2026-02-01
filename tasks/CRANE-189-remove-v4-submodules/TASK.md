# Task CRANE-189: Remove lib/v4-core and lib/v4-periphery Submodules

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-31
**Dependencies:** CRANE-152
**Worktree:** `chore/remove-v4-submodules`
**Origin:** Submodule cleanup initiative

---

## Description

Remove the `lib/v4-core` and `lib/v4-periphery` submodules after CRANE-152 has ported the Uniswap V4 contracts to local. This is a high-priority removal as these submodules contain significant nested dependencies:

- lib/v4-core (~26M): Contains forge-std, openzeppelin-contracts, solmate
- lib/v4-periphery (~47M): Contains permit2 (with all its deps), v4-core (duplicate), and more

Combined, removing both eliminates ~73M of disk space per worktree and removes duplicate nested submodules.

## Dependencies

- CRANE-152: Port and Verify Uniswap V4 Core + Periphery (must complete first)

## User Stories

### US-CRANE-189.1: Remove Uniswap V4 Submodules

As a developer, I want to remove the lib/v4-core and lib/v4-periphery submodules so that worktrees are smaller and we don't have external dependencies for Uniswap V4 functionality.

**Acceptance Criteria:**
- [ ] Remove lib/v4-core submodule entry from .gitmodules
- [ ] Remove lib/v4-periphery submodule entry from .gitmodules
- [ ] Remove lib/v4-core directory
- [ ] Remove lib/v4-periphery directory
- [ ] Update any remaining direct imports (should be none after CRANE-152)
- [ ] Remove v4 remappings from remappings.txt if present
- [ ] All existing tests still pass
- [ ] Build succeeds

## Submodule Analysis

**lib/v4-core contains (26M total):**
- Uniswap V4 core pool manager and libraries
- Nested: forge-std, openzeppelin-contracts (with erc4626-tests, forge-std), solmate

**lib/v4-periphery contains (47M total):**
- Uniswap V4 periphery (position manager, quoter, etc.)
- Nested: permit2 (with forge-gas-snapshot, forge-std, openzeppelin-contracts, solmate)
- Nested: v4-core (duplicate of top-level)

**Combined size: ~73M**

## Files to Create/Modify

**Modified Files:**
- `.gitmodules` (remove v4-core and v4-periphery entries)
- `remappings.txt` (remove v4 mappings if present)
- `foundry.lock` (remove v4-core and v4-periphery entries)

**Removed Files:**
- `lib/v4-core/` (entire submodule including nested deps)
- `lib/v4-periphery/` (entire submodule including nested deps)

## Pre-Removal Checklist

Before removing the submodules:
- [ ] CRANE-152 is complete (Uniswap V4 ported to local)
- [ ] Verify no direct imports from `lib/v4-core/` or `lib/v4-periphery/`
- [ ] Verify tests pass with current remappings
- [ ] Verify build succeeds

## Removal Commands

```bash
# Remove submodule entries from .gitmodules
git submodule deinit -f lib/v4-core
git submodule deinit -f lib/v4-periphery

# Remove from git's module tracking
rm -rf .git/modules/lib/v4-core
rm -rf .git/modules/lib/v4-periphery

# Remove the directories
rm -rf lib/v4-core
rm -rf lib/v4-periphery

# Stage the removal
git add .gitmodules lib/v4-core lib/v4-periphery

# Update foundry.lock (remove v4-core and v4-periphery entries)
# Update remappings.txt if needed
```

## Inventory Check

Before starting, verify:
- [ ] CRANE-152 is complete
- [ ] All remappings redirect to ported contracts

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] Build succeeds
- [ ] Worktree size reduced by ~73M

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
