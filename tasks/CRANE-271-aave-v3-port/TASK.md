# Task CRANE-271: Port Aave V3 Origin Code

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-04-24
**Dependencies:** None
**Worktree:** `feature/CRANE-271-aave-v3-port`

---

## Description

Port the entire Aave V3 origin repository (`https://github.com/aave-dao/aave-v3-origin.git`) into the Crane framework. This includes:
- All protocol contracts ported to `contracts/protocols/lending/aave/v3.6/`
- All transitive dependencies ported to `contracts/protocols/lending/aave/v3.6/dependencies/`
- All tests ported to `test/foundry/spec/protocols/lending/aave/3.6/`
- Convert all remappings to relative path imports
- Install Aave via `forge install` in the worktree before porting
- Goal: eventually remove the submodule before merging to main branch

## Dependencies

None

## User Stories

### US-CRANE-271.1: Port Aave V3 Protocol Contracts

As a Crane developer, I want the Aave V3 protocol contracts ported so that I can integrate with Aave V3.

**Acceptance Criteria:**
- [ ] Install `forge install https://github.com/aave-dao/aave-v3-origin.git` in the worktree
- [ ] Copy all contracts from `aave-v3-origin/src/protocol` to `contracts/protocols/lending/aave/v3.6/`
- [ ] Convert all import remappings to relative path imports (e.g., `@openzeppelin/...` → `../../dependencies/openzeppelin/...`)
- [ ] Update all import paths to use the new relative paths
- [ ] Build succeeds with `forge build`

### US-CRANE-271.2: Port Aave V3 Transitive Dependencies

As a Crane developer, I want all Aave V3 dependencies included so the code is self-contained.

**Acceptance Criteria:**
- [ ] Identify all external dependencies used by Aave V3 contracts
- [ ] Copy transitive dependencies to `contracts/protocols/lending/aave/v3.6/dependencies/`
- [ ] Update all import paths to point to the new dependency locations
- [ ] Dependencies compile without errors

### US-CRANE-271.3: Port Aave V3 Tests

As a Crane developer, I want the Aave V3 tests ported so I can verify the port is correct.

**Acceptance Criteria:**
- [ ] Copy all tests from `aave-v3-origin/src/test` to `test/foundry/spec/protocols/lending/aave/3.6/`
- [ ] Update all import paths in tests to use the new relative paths
- [ ] Tests compile and pass with `forge test`

### US-CRANE-271.4: Remove Submodule Preparation

As a Crane developer, I want the submodule removed before merge so the code is self-contained.

**Acceptance Criteria:**
- [ ] Document any modifications made during porting
- [ ] Verify all functionality is preserved without the submodule
- [ ] Prepare cleanup plan for submodule removal

## Technical Details

### Source Location
- GitHub: `https://github.com/aave-dao/aave-v3-origin.git`
- Protocol contracts: `src/protocol/`
- Tests: `src/test/`

### Target Locations
- Contracts: `contracts/protocols/lending/aave/v3.6/`
- Dependencies: `contracts/protocols/lending/aave/v3.6/dependencies/`
- Tests: `test/foundry/spec/protocols/lending/aave/3.6/`

### Import Conversion Strategy

Convert Foundry remappings to relative paths:
```
# Before (remapping)
import {Something} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Something} from "aave-v3-origin/src/protocol/pool/Pool.sol";

# After (relative)
import {Something} from "../../dependencies/openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Something} from "./Pool.sol";
```

### Worktree Setup
```bash
git worktree add -b feature/CRANE-271-aave-v3-port ../crane-wt/feature/CRANE-271-aave-v3-port
cd ../crane-wt/feature/CRANE-271-aave-v3-port
forge install https://github.com/aave-dao/aave-v3-origin.git
```

## Files to Create/Modify

**New Files:**
- `contracts/protocols/lending/aave/v3.6/**` - Ported Aave V3 contracts
- `contracts/protocols/lending/aave/v3.6/dependencies/**` - Transitive dependencies
- `test/foundry/spec/protocols/lending/aave/3.6/**` - Ported tests

**Modified Files:**
- All ported files will have updated import paths
- `foundry.toml` - May need remapping updates if conflicts arise

## Inventory Check

Before starting, verify:
- [ ] Worktree is created
- [ ] `forge install https://github.com/aave-dao/aave-v3-origin.git` succeeds
- [ ] Source repo is accessible and complete
- [ ] Target directories exist and are empty

## Completion Criteria

- [ ] All Aave V3 protocol contracts ported and compiling
- [ ] All dependencies ported and compiling
- [ ] All tests ported, compiling, and passing
- [ ] No remaining import remappings to aave-v3-origin in ported code
- [ ] Build succeeds with `forge build`
- [ ] Tests pass with `forge test`

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`