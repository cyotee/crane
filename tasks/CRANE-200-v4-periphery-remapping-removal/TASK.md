# Task CRANE-200: Remove v4-periphery-coupled Remappings

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-01
**Dependencies:** CRANE-152
**Worktree:** `fix/v4-periphery-remapping-removal`
**Origin:** Code review suggestion from CRANE-152

---

## Description

If V4 and other Crane codepaths already rely on local Permit2 interfaces (`contracts/interfaces/protocols/utils/permit2/**`) and locally ported Solmate (`contracts/protocols/dexes/uniswap/v4/external/solmate/**`), then the `foundry.toml` remappings to `lib/v4-periphery/lib/*` are unnecessary coupling and should be removed.

After removal, rerun `forge build` + V4 tests to confirm no hidden dependency.

(Created from code review of CRANE-152)

## Dependencies

- CRANE-152: Port and Verify Uniswap V4 Core + Periphery (parent task)

## User Stories

### US-CRANE-200.1: Remove v4-periphery Remappings

As a developer, I want v4-periphery remappings removed so that the submodule can be safely deleted.

**Acceptance Criteria:**
- [ ] `permit2/` remapping points to local sources, not lib/v4-periphery
- [ ] `solmate/` remapping removed or points to local sources
- [ ] No other remappings to lib/v4-periphery
- [ ] `forge build` succeeds
- [ ] V4 tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `foundry.toml`
- `remappings.txt`

## Inventory Check

Before starting, verify:
- [ ] CRANE-152 is complete
- [ ] Local permit2 interfaces exist
- [ ] Local solmate exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
