# Task CRANE-188: Remove lib/reclamm Submodule

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-31
**Dependencies:** CRANE-195
**Worktree:** `chore/remove-reclamm-submodule`
**Origin:** Submodule cleanup initiative

---

## Description

Remove the `lib/reclamm` submodule after CRANE-195 eliminates the build-time dependency on `lib/reclamm` (remappings/imports). This is a high-priority removal as it includes the nested `balancer-v3-monorepo` submodule, totaling ~62M of disk space per worktree.

## Dependencies

- CRANE-195: Make lib/reclamm Submodule Removal Possible (must complete first)

## User Stories

### US-CRANE-188.1: Remove ReClaMM Submodule

As a developer, I want to remove the lib/reclamm submodule so that worktrees are smaller and we don't have external dependencies for ReClaMM functionality.

**Acceptance Criteria:**
- [ ] Remove lib/reclamm submodule entry from .gitmodules
- [ ] Remove lib/reclamm directory
- [ ] No remappings/imports resolve via lib/reclamm
- [ ] Remove reclamm remapping from remappings.txt if present
- [ ] All existing tests still pass
- [ ] Build succeeds

## Submodule Analysis

**lib/reclamm contains:**
- ReClaMM pool implementation
- Nested: `lib/reclamm/lib/balancer-v3-monorepo` (large)

**Total size: ~62M**

## Files to Create/Modify

**Modified Files:**
- `.gitmodules` (remove reclamm entry)
- `remappings.txt` (remove reclamm mappings if present)
- `foundry.lock` (remove reclamm entry)

**Removed Files:**
- `lib/reclamm/` (entire submodule including nested deps)

## Pre-Removal Checklist

Before removing the submodule:
- [ ] CRANE-195 is complete (no build-time dependency on lib/reclamm)
- [ ] Verify no direct imports from `lib/reclamm/`
- [ ] Verify tests pass with current remappings
- [ ] Verify build succeeds

## Removal Commands

```bash
# Sanity: ensure no imports reference lib/reclamm
rg "import\s+\"lib/reclamm/" -n contracts test --glob "*.sol"

# Remove submodule entry from .gitmodules
git submodule deinit -f lib/reclamm

# Remove from git's module tracking
rm -rf .git/modules/lib/reclamm

# Remove the directory
rm -rf lib/reclamm

# Stage the removal
git add .gitmodules lib/reclamm

# Update foundry.lock (remove reclamm entry)
# Update remappings.txt if needed

# Verify
forge build
forge test
```

## Inventory Check

Before starting, verify:
- [ ] CRANE-149 is complete
- [ ] All remappings redirect to ported contracts

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] Build succeeds
- [ ] Worktree size reduced by ~62M

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
