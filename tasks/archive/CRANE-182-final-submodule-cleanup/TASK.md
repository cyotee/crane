# Task CRANE-182: Final Submodule Cleanup and forge-std Installation

**Repo:** Crane Framework
**Status:** Blocked
**Created:** 2026-01-30
**Dependencies:** CRANE-171, CRANE-181, (future removal tasks)
**Worktree:** `chore/final-submodule-cleanup`

---

## Description

After the targeted protocol submodule removals are complete (Permit2, Aerodrome, Uniswap v3/v4, ReClaMM, and any other protocol ports), do a comprehensive cleanup so Foundry builds/tests without protocol submodules. This task is explicitly NOT the place where we decide to remove core dev/library dependencies like OpenZeppelin or Solady; keep those as submodules unless/until there is an explicit task to remove them.

## Goal

The end state should be:
- No protocol submodules are required for `forge build` / `forge test`
- All protocol code lives in `contracts/protocols/` and is imported via Crane-owned paths
- Remappings do not reference removed protocol submodules
- `.gitmodules` contains only the submodules we intentionally keep (e.g., forge-std, openzeppelin-contracts, solady)
- Build and tests pass

## Dependencies

**Protocol removal tasks (must be done first):**
- CRANE-171: Remove lib/permit2 Submodule
- CRANE-181: Remove lib/aerodrome-contracts Submodule
- CRANE-186: Remove v3-core and v3-periphery Submodules
- CRANE-189: Remove lib/v4-core and lib/v4-periphery Submodules
- CRANE-188: Remove lib/reclamm Submodule

**Notes:**
- Submodule removals should be tracked as their own tasks; if a protocol is still consumed via submodule, create a dedicated removal/enablement task rather than expanding this one.
- OpenZeppelin and Solady are core library dependencies; do not remove them as part of this task.

**Note:** This task should only be started when the protocol submodule removal tasks above are complete.

## User Stories

### US-CRANE-182.1: Clean Up Remappings

As a developer, I want all remappings updated to point only to local contracts and forge-std.

**Acceptance Criteria:**
- [ ] remappings.txt and foundry.toml do not reference removed protocol submodules (permit2, v3, v4, reclamm, aerodrome)
- [ ] Add/verify remappings for Crane-owned protocol ports (only if actually used in code)
- [ ] `forge build` succeeds

### US-CRANE-182.2: Update All Import Statements

As a developer, I want all imports updated to use the new local paths.

**Acceptance Criteria:**
- [ ] No Solidity import references removed protocol submodules (`lib/permit2`, `lib/v3-*`, `lib/v4-*`, `lib/reclamm`, `lib/aerodrome-contracts`)
- [ ] All contracts compile

### US-CRANE-182.3: Remove Empty lib/ Directories

As a developer, I want the lib/ directory cleaned of removed submodule remnants.

**Acceptance Criteria:**
- [ ] Remove any empty directories in lib/ left by protocol submodule removals
- [ ] Verify .git/modules/ does not contain removed protocol submodules

### US-CRANE-182.4: Update .gitmodules

As a developer, I want .gitmodules to only contain forge-std.

**Acceptance Criteria:**
- [ ] .gitmodules contains only the intentionally kept submodules (forge-std + any core libs still intentionally tracked)
- [ ] No removed protocol submodule entries remain
- [ ] git submodule status does not include removed protocol submodules

### US-CRANE-182.5: Update CI/Documentation

As a developer, I want CI and documentation updated to reflect the new structure.

**Acceptance Criteria:**
- [ ] Update README.md if it references submodules
- [ ] Update any CI workflows that initialize submodules (should only need forge-std)
- [ ] Update CLAUDE.md if it references submodule structure
- [ ] Update any installation instructions

### US-CRANE-182.6: Final Verification

As a developer, I want complete verification that the cleanup is successful.

**Acceptance Criteria:**
- [ ] Fresh clone test: `git clone --recursive` works with the intended remaining submodules
- [ ] `forge build` succeeds
- [ ] `forge test` passes

## Technical Details

### Targeted Removals Covered by This Epic

This cleanup assumes the following protocol submodules have already been removed by their dedicated tasks:
- lib/permit2
- lib/aerodrome-contracts
- lib/v3-core
- lib/v3-periphery
- lib/v4-core
- lib/v4-periphery
- lib/reclamm

### Expected Final State

- Protocol imports resolve from `contracts/` (no dependency on removed protocol submodules)
- `.gitmodules` no longer contains removed protocol submodules
- `forge build` and `forge test` succeed

### Verification Commands

Use these commands as quick invariants:

```bash
rg "import\s+\"lib/(permit2|aerodrome-contracts|v3-|v4-|reclamm)/" -n contracts test --glob "*.sol"
forge build
forge test
```

## Files to Create/Modify

**Modified Files:**
- `.gitmodules` - Clean up to only forge-std
- `foundry.toml` - Update remappings
- `CLAUDE.md` / `README.md` - Update if needed
- Multiple `.sol` files with import path updates

**Removed Files/Directories:**
- All `lib/*` directories except `lib/forge-std`
- `.git/modules/*` except forge-std

## Inventory Check

Before starting, verify:
- [ ] CRANE-171 (permit2 removal) is complete
- [ ] CRANE-181 (aerodrome removal) is complete
- [ ] All other submodule removal tasks are complete
- [ ] Only lib/forge-std remains

## Completion Criteria

- [ ] Only forge-std submodule remains
- [ ] All remappings point to local code
- [ ] All imports updated
- [ ] .gitmodules is clean
- [ ] Fresh clone works
- [ ] All tests pass
- [ ] Build succeeds
- [ ] Documentation updated

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
