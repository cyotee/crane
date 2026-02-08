# Task CRANE-240: Remove Commented-Out Console Imports from CamelotV2Service

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-07
**Dependencies:** -
**Worktree:** `fix/remove-commented-console-imports`
**Origin:** Code review suggestion from CRANE-101

---

## Description

CamelotV2Service.sol contains three commented-out console import lines (lines 4-6) that are dead code. They produce no bytecode but create false positives when grepping for `console` across the codebase.

(Created from code review of CRANE-101)

## Dependencies

None (CRANE-101 is complete).

## User Stories

### US-CRANE-240.1: Remove Dead Console Imports

As a developer, I want commented-out console imports removed from CamelotV2Service.sol so that codebase-wide console.log audits don't produce false positives.

**Acceptance Criteria:**
- [ ] Remove the three commented-out lines from CamelotV2Service.sol:
  - `// import "hardhat/console.sol";`
  - `// import "forge-std/console.sol";`
  - `// import "forge-std/console2.sol";`
- [ ] No other code changes in the file
- [ ] `forge build` passes
- [ ] Tests pass

## Files to Create/Modify

**Modified Files:**
- contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol - Remove 3 commented-out import lines

## Inventory Check

Before starting, verify:
- [ ] CamelotV2Service.sol exists at the expected path
- [ ] The commented-out imports are still present

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] `forge build` passes
- [ ] Tests pass

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
