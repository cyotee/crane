# Task CRANE-182: Final Submodule Cleanup and forge-std Installation

**Repo:** Crane Framework
**Status:** Blocked
**Created:** 2026-01-30
**Dependencies:** CRANE-171, CRANE-181, (future removal tasks)
**Worktree:** `chore/final-submodule-cleanup`

---

## Description

After all submodules have been removed (except forge-std), perform a comprehensive cleanup of the repository to ensure all imports use local ported code, remappings are cleaned up, empty lib/ directories are removed, and forge-std is properly configured as the sole remaining submodule. This task ensures the repository can use Foundry with minimal external dependencies.

## Goal

The end state should be:
- Only `lib/forge-std` remains as a submodule
- All other protocol code lives in `contracts/protocols/`
- All remappings point to local contracts
- Clean, minimal `.gitmodules` file
- Build and tests pass

## Dependencies

**Completed Ports (submodule removal tasks must be done first):**
- CRANE-171: Remove lib/permit2 Submodule (Ready - depends on CRANE-168, CRANE-169)
- CRANE-181: Remove lib/aerodrome-contracts Submodule (Ready)

**In Progress / Future Ports (removal tasks TBD):**
- Uniswap V3: CRANE-151 (In Progress) → removal task TBD
- Uniswap V4: CRANE-152 (Ready) → removal task TBD
- Resupply: CRANE-153 (Ready) → removal task TBD
- Slipstream: No port task yet (uses submodule)
- Balancer V3: CRANE-141-147 (various statuses)
- Other submodules: aave-v3, aave-v4, comet, euler-*, openzeppelin-contracts, etc.

**Note:** This task should only be started when ALL protocol submodules have been ported and removed, leaving only forge-std.

## User Stories

### US-CRANE-182.1: Clean Up Remappings

As a developer, I want all remappings updated to point only to local contracts and forge-std.

**Acceptance Criteria:**
- [ ] Remove all submodule remappings from foundry.toml (except forge-std)
- [ ] Add/verify remappings for all local protocol ports:
  - `@crane/contracts/=contracts/`
  - `@aerodrome/=contracts/protocols/dexes/aerodrome/`
  - `@uniswap/v3/=contracts/protocols/dexes/uniswap/v3/`
  - `@uniswap/v4/=contracts/protocols/dexes/uniswap/v4/`
  - `@balancer/v3/=contracts/protocols/dexes/balancer/v3/`
  - `@permit2/=contracts/protocols/infra/permit2/`
  - `@sky/=contracts/protocols/cdps/sky/`
  - etc.
- [ ] Verify all import paths resolve correctly
- [ ] Build succeeds with new remappings

### US-CRANE-182.2: Update All Import Statements

As a developer, I want all imports updated to use the new local paths.

**Acceptance Criteria:**
- [ ] Search for any remaining submodule imports (e.g., `import "lib/...`)
- [ ] Update all imports to use remapped paths or relative paths
- [ ] No import references `lib/` except `lib/forge-std`
- [ ] All contracts compile

### US-CRANE-182.3: Remove Empty lib/ Directories

As a developer, I want the lib/ directory cleaned of removed submodule remnants.

**Acceptance Criteria:**
- [ ] Remove any empty directories in lib/
- [ ] Remove any leftover .git files from submodule removal
- [ ] Verify lib/ only contains forge-std
- [ ] Verify .git/modules/ is cleaned (only forge-std module)

### US-CRANE-182.4: Update .gitmodules

As a developer, I want .gitmodules to only contain forge-std.

**Acceptance Criteria:**
- [ ] .gitmodules contains only forge-std entry:
  ```ini
  [submodule "lib/forge-std"]
      path = lib/forge-std
      url = https://github.com/foundry-rs/forge-std
  ```
- [ ] No other submodule entries remain
- [ ] git submodule status shows only forge-std

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
- [ ] Fresh clone test: `git clone --recursive` works and only fetches forge-std
- [ ] `forge build` succeeds
- [ ] `forge test` passes (all tests)
- [ ] No compiler warnings about missing imports
- [ ] `forge coverage` works (if applicable)

## Technical Details

### Current Submodules (to be removed before this task)

Based on `git submodule status`:
```
lib/aave-v3-horizon
lib/aave-v4
lib/aerodrome-contracts       → CRANE-181
lib/balancer-v3-monorepo
lib/comet
lib/ethereum-vault-connector
lib/euler-price-oracle
lib/euler-vault-kit
lib/evc-playground
lib/evk-periphery
lib/forge-std                 → KEEP (only this remains)
lib/gsn
lib/openzeppelin-contracts
lib/permit2                   → CRANE-171
lib/reclamm
lib/resupply
lib/scaffold-eth-2
lib/slipstream
lib/solady
lib/solidity-lib
lib/solmate
lib/solplot
lib/v3-core                   → After CRANE-151
lib/v3-periphery              → After CRANE-151
lib/v4-core                   → After CRANE-152
lib/v4-periphery              → After CRANE-152
```

### Expected Final State

```
lib/
└── forge-std/                # Only submodule remaining

.gitmodules:
[submodule "lib/forge-std"]
    path = lib/forge-std
    url = https://github.com/foundry-rs/forge-std

foundry.toml remappings:
[
    "forge-std/=lib/forge-std/src/",
    "@crane/=contracts/",
    "@aerodrome/=contracts/protocols/dexes/aerodrome/",
    "@balancer/v3/=contracts/protocols/dexes/balancer/v3/",
    "@uniswap/v3/=contracts/protocols/dexes/uniswap/v3/",
    "@uniswap/v4/=contracts/protocols/dexes/uniswap/v4/",
    "@permit2/=contracts/protocols/infra/permit2/",
    "@sky/=contracts/protocols/cdps/sky/",
    ...
]
```

### Import Update Script

Create a script to find and report remaining submodule imports:

```bash
#!/bin/bash
# Find imports still referencing lib/ (except forge-std)
grep -r "import.*lib/" contracts/ test/ --include="*.sol" | \
  grep -v "forge-std" | \
  grep -v "node_modules"
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
