# Task CRANE-060: Add ERC-165 Strict Semantics for 0xffffffff

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-14
**Dependencies:** CRANE-015
**Worktree:** `fix/erc165-strict-semantics`
**Origin:** Code review suggestion from CRANE-015

---

## Description

Consider excluding `0xffffffff` in fuzz tests or enforcing strict ERC-165 semantics at the Repo level.

ERC-165 specifies `0xffffffff` as an invalid interface ID. The current ERC165Repo is a generic mapping that allows any bytes4 value. This task evaluates whether to:
1. Exclude `0xffffffff` from fuzz tests (minimal change)
2. Enforce strict ERC-165 semantics at the Repo level (revert on 0xffffffff)
3. Document the intentional generic behavior

(Created from code review of CRANE-015)

## Dependencies

- CRANE-015: Fix ERC165Repo Overload Bug (parent task - complete)

## User Stories

### US-CRANE-060.1: ERC-165 Compliance Decision

As a developer, I want clear handling of the `0xffffffff` interface ID so that ERC-165 compliance expectations are documented and tested.

**Acceptance Criteria:**
- [ ] Decision made: strict semantics vs. generic mapping
- [ ] If strict: `_registerInterface(0xffffffff)` reverts or is rejected
- [ ] If generic: Document intentional behavior in NatSpec
- [ ] Fuzz test updated to match chosen semantics
- [ ] All existing tests continue to pass

## Files to Create/Modify

**Modified Files:**
- contracts/introspection/ERC165/ERC165Repo.sol (if enforcing strict semantics)
- test/foundry/spec/introspection/ERC165/ERC165Repo.t.sol

## Inventory Check

Before starting, verify:
- [x] CRANE-015 is complete
- [x] ERC165Repo.sol exists
- [x] ERC165Repo.t.sol exists

## Implementation Notes

From reviewer: "I'd personally keep current behavior unless higher-level facets enforce strict ERC-165 constraints."

Options to consider:
1. **Minimal (fuzz exclusion only):** Add `vm.assume(interfaceId != 0xffffffff)` to fuzz test
2. **Documentation only:** Add NatSpec explaining generic mapping behavior
3. **Strict enforcement:** Add require check in `_registerInterface`

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass: `forge test --match-path "test/foundry/spec/introspection/ERC165/ERC165Repo.t.sol"`
- [ ] Build succeeds: `forge build`

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
