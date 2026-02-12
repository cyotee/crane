# Task CRANE-171: Remove lib/permit2 Submodule

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-30
**Dependencies:** CRANE-150, CRANE-168, CRANE-169
**Worktree:** `chore/remove-permit2-submodule`
**Origin:** Code review suggestion from CRANE-150

---

## Description

Now that all imports are redirected via remappings, the `lib/permit2` submodule can be removed to clean up the repository.

(Created from code review of CRANE-150)

## Dependencies

- CRANE-150: Verify Permit2 Contract Port Completeness (Complete)
- CRANE-168: Add SafeCast160 Unit Tests (ensures port is tested before removal)
- CRANE-169: Add Permit2Lib Integration Tests (ensures port is tested before removal)

## User Stories

### US-CRANE-171.1: Remove Permit2 Submodule

As a developer, I want to remove the lib/permit2 submodule so that the repository is cleaner and we don't have external dependencies for Permit2 functionality.

**Acceptance Criteria:**
- [ ] Remove lib/permit2 submodule entry from .gitmodules
- [ ] Remove lib/permit2 directory
- [ ] Update any remaining direct imports (should be none after CRANE-150)
- [ ] Remove permit2 fallback remapping from remappings.txt
- [ ] All existing tests still pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `.gitmodules` (remove permit2 entry)
- `remappings.txt` (remove `permit2/=lib/permit2/` fallback)

**Removed Files:**
- `lib/permit2/` (entire submodule)

## Pre-Removal Checklist

Before removing the submodule:
- [ ] Verify no direct imports from `permit2/src/` (all redirected via remappings)
- [ ] Verify tests pass with current remappings
- [ ] Verify build succeeds

## Removal Commands

```bash
# Remove submodule entry from .gitmodules
git submodule deinit -f lib/permit2

# Remove from git's module tracking
rm -rf .git/modules/lib/permit2

# Remove the directory
rm -rf lib/permit2

# Stage the removal
git add .gitmodules lib/permit2

# Update remappings.txt (remove fallback line)
```

## Inventory Check

Before starting, verify:
- [x] CRANE-150 is complete
- [ ] CRANE-168 is complete (or skip if minor)
- [ ] CRANE-169 is complete (or skip if minor)
- [ ] All remappings are in place

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
