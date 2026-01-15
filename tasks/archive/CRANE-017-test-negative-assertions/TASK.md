# Task CRANE-017: Add Negative Assertions to Test Framework

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-003
**Worktree:** `fix/test-negative-assertions`
**Origin:** Code review suggestion from CRANE-003 (Suggestion 1 - High Priority)

---

## Description

Implement the 3 high-priority recommendations from the CRANE-003 test framework audit to address critical safety gaps:

1. **Add negative tests to all Behavior libraries** - Ensure invalid inputs return expected failures
2. **Verify ERC165 self-support in all tests** - Add explicit check that `supportsInterface(0x01ffc9a7)` returns `true`
3. **Add length equality assertions to TestBase_IFacet** - Add explicit assertions that actual array lengths match expected

These address critical safety gaps where a green build does NOT currently guarantee:
- Invalid interface IDs return `false` from `supportsInterface()`
- Facets don't declare extra unexpected selectors/interfaces
- ERC165 self-support is properly implemented

## Dependencies

- CRANE-003: Test Framework and IFacet Pattern Audit (parent task - COMPLETE)

## User Stories

### US-CRANE-017.1: Negative Interface Testing

As a developer, I want Behavior_IERC165 to test that invalid interface IDs return `false` so that an always-`true` implementation cannot pass tests.

**Acceptance Criteria:**
- [ ] `Behavior_IERC165.hasValid_IERC165_supportsInterface()` also tests that a known-invalid interface ID returns `false`
- [ ] Test uses `0xffffffff` (explicitly invalid per ERC165) as the negative case
- [ ] Tests pass

### US-CRANE-017.2: ERC165 Self-Support Verification

As a developer, I want all ERC165 tests to verify the contract correctly reports support for ERC165 itself so that basic interface compliance is guaranteed.

**Acceptance Criteria:**
- [ ] `TestBase_IERC165` includes explicit check: `assertTrue(subject.supportsInterface(0x01ffc9a7))`
- [ ] Check runs as part of standard ERC165 validation
- [ ] Tests pass

### US-CRANE-017.3: Length Equality Assertions

As a developer, I want TestBase_IFacet to assert that actual array lengths match expected lengths so that extra/missing declarations are caught explicitly.

**Acceptance Criteria:**
- [ ] `test_IFacet_FacetInterfaces()` asserts `controlFacetInterfaces().length == testFacet.facetInterfaces().length`
- [ ] `test_IFacet_FacetFuncs()` asserts `controlFacetFuncs().length == testFacet.facetFuncs().length`
- [ ] Length assertions run BEFORE content comparison for clearer error messages
- [ ] Tests pass

## Files to Create/Modify

**Modified Files:**
- `contracts/factories/diamondPkg/TestBase_IFacet.sol` - Add length assertions
- `contracts/introspection/ERC165/Behavior_IERC165.sol` - Add negative interface test
- `contracts/introspection/ERC165/TestBase_IERC165.sol` - Add ERC165 self-support check

## Inventory Check

Before starting, verify:
- [x] CRANE-003 is complete
- [ ] Affected files exist and compile
- [ ] Current tests pass before changes

## Completion Criteria

- [ ] All 3 acceptance criteria met
- [ ] All existing tests still pass
- [ ] `forge build` succeeds
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
