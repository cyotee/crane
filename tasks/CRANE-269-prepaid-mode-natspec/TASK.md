# Task CRANE-269: Add NatSpec Documenting Prepaid Mode Behavior

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-163
**Worktree:** `docs/CRANE-269-prepaid-mode-natspec`
**Origin:** Code review suggestion from CRANE-163

---

## Description

Add NatSpec documentation to the `_takeTokenIn()` function documenting the prepaid mode branch. The CRANE-163 fix embeds an `_isPrepaid()` check inside `_takeTokenIn()`, which diverges from the upstream Balancer pattern where prepaid guards are at the caller level. This intentional design choice should be documented for developer clarity.

(Created from code review of CRANE-163)

## Dependencies

- CRANE-163: Fix Prepaid Router Mode for Permit2-less Operations (parent task)

## User Stories

### US-CRANE-269.1: Document Prepaid Mode Divergence

As a developer, I want NatSpec on `_takeTokenIn()` explaining the prepaid mode branch so that the design divergence from upstream Balancer is clear.

**Acceptance Criteria:**
- [ ] Add NatSpec to `_takeTokenIn()` explaining the prepaid mode branch
- [ ] Document that this diverges from upstream Balancer where guards are at caller level
- [ ] Explain why the single-point fix approach was chosen (fixes all callers at once)
- [ ] Note that some callers have redundant double-checks (harmless)
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/balancer/v3/router/diamond/BalancerV3RouterModifiers.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-163 is complete
- [ ] `_takeTokenIn()` contains the `_isPrepaid()` check

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Build succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
