# Task CRANE-196: Replace Unsupported Foundry Config Key

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-01
**Dependencies:** CRANE-149
**Worktree:** `fix/foundry-config-cleanup`
**Origin:** Code review suggestion from CRANE-149

---

## Description

Remove `exclude_paths` and use supported Foundry configuration to avoid compiling unwanted submodule test sources.

The key `exclude_paths` in `foundry.toml` is not supported and generates a warning: `Warning: Found unknown 'exclude_paths' config for profile 'default'`.

This was already implemented during review by switching to `skip = ["lib/reclamm/**"]` but needs verification and cleanup.

(Created from code review of CRANE-149)

## Dependencies

- CRANE-149: Fork ReClaMM Pool to Local Contracts (parent task)

## User Stories

### US-CRANE-196.1: Use Supported Foundry Config

As a developer, I want Foundry configuration to use only supported keys so that build warnings are eliminated.

**Acceptance Criteria:**
- [ ] `exclude_paths` removed from foundry.toml
- [ ] Replaced with supported `skip` configuration
- [ ] No Foundry config warnings
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `foundry.toml`

## Inventory Check

Before starting, verify:
- [ ] CRANE-149 is complete
- [ ] foundry.toml exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
