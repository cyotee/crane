# Task CRANE-200: Remove v4-periphery-coupled Remappings

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-01
**Dependencies:** CRANE-152
**Worktree:** `fix/v4-periphery-remapping-removal`
**Origin:** Code review suggestion from CRANE-152

---

## Description

If V4 and other Crane codepaths already rely on local Permit2 interfaces and locally ported Solmate, then remappings to `lib/v4-periphery/**` (and `lib/v4-core/**`) are unnecessary coupling and should be removed.

After removal, rerun `forge build` + V4 tests to confirm no hidden dependency.

(Created from code review of CRANE-152)

## Dependencies

- CRANE-152: Port and Verify Uniswap V4 Core + Periphery (parent task)

## User Stories

### US-CRANE-200.1: Remove v4-periphery Remappings

As a developer, I want v4-periphery remappings removed so that the submodule can be safely deleted.

**Acceptance Criteria:**
- [ ] remappings.txt does not reference lib/v4-periphery or lib/v4-core
- [ ] `permit2/` resolves to Crane-owned sources (or is removed if unused)
- [ ] `solmate/` resolves to Crane-owned sources (or is removed if unused)
- [ ] No other remappings to lib/v4-periphery or lib/v4-core
- [ ] `forge build` succeeds
- [ ] V4 tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `foundry.toml`
- `remappings.txt`

## Suggested Verification

```bash
rg "lib/v4-(core|periphery)" remappings.txt foundry.toml
forge build
forge test --match-path "test/foundry/spec/protocols/dexes/uniswap/v4/**/*.t.sol"
forge test --match-path "test/foundry/fork/ethereum_main/uniswapV4/*.t.sol"
```

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
