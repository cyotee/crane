# Task CRANE-198: Add Submodule Removal Verification to CI

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-01
**Dependencies:** CRANE-152
**Worktree:** `feature/v4-submodule-removal-ci-check`
**Origin:** Code review suggestion from CRANE-152

---

## Description

Add a deterministic check that the repo builds/tests without `lib/v4-core` and `lib/v4-periphery` present (or at minimum, ensure no active remappings require them). This turns submodule independence into a mechanically verifiable invariant.

Recommended approach: After CRANE-200 removes v4-submodule-coupled remappings, run `forge build` + the two known-good V4 test commands:
- `forge test --match-path "test/foundry/spec/protocols/dexes/uniswap/v4/**/*.t.sol"`
- `forge test --match-path "test/foundry/fork/ethereum_main/uniswapV4/*.t.sol"`

(Created from code review of CRANE-152)

## Dependencies

- CRANE-200: Remove v4-periphery-coupled Remappings (enables running without v4 submodules)
- CRANE-189: Remove lib/v4-core and lib/v4-periphery Submodules (optional, but ideal)

## User Stories

### US-CRANE-198.1: CI Verification for Submodule Independence

As a developer, I want CI to verify that v4-core and v4-periphery submodules are not required so that submodule removal remains a verifiable invariant.

**Acceptance Criteria:**
- [ ] CI/test script verifies build works without v4-submodule remappings
- [ ] V4 tests pass with local sources only
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `foundry.toml`
- `remappings.txt`
- (Optional) CI pipeline config

## Inventory Check

Before starting, verify:
- [ ] CRANE-200 is complete
- [ ] V4 contracts exist locally

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
