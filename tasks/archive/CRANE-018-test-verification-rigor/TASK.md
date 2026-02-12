# Task CRANE-018: Improve Test Verification Rigor

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-003
**Worktree:** `fix/test-verification-rigor`
**Origin:** Code review suggestion from CRANE-003 (Suggestion 2 - Medium Priority)

---

## Description

Implement the 3 medium-priority recommendations from the CRANE-003 test framework audit to improve verification rigor and code clarity:

1. **Test facetMetadata() consistency** - Verify that `facetMetadata()` returns values consistent with individual getters
2. **Add interface ID computation tests** - Verify interface IDs are correctly computed via XOR of selectors
3. **Document expected comparator behavior** - Add NatSpec to clarify bidirectional checking semantics

These improvements ensure:
- Aggregate functions return the same data as individual getters
- Interface IDs are verifiably correct
- Comparator behavior is clear to maintainers

## Dependencies

- CRANE-003: Test Framework and IFacet Pattern Audit (parent task - COMPLETE)

## User Stories

### US-CRANE-018.1: Metadata Consistency Testing

As a developer, I want tests to verify `facetMetadata()` returns values matching individual getters so that I can trust the aggregate function.

**Acceptance Criteria:**
- [ ] `Behavior_IFacet` includes test that `facetMetadata().name == facetName()`
- [ ] Test verifies `facetMetadata().interfaces` matches `facetInterfaces()`
- [ ] Test verifies `facetMetadata().functions` matches `facetFuncs()`
- [ ] Tests pass

### US-CRANE-018.2: Interface ID Computation Tests

As a developer, I want tests to verify interface IDs are correctly computed so that ERC165 compliance is guaranteed.

**Acceptance Criteria:**
- [ ] Add helper or test that computes expected interface ID via XOR of function selectors
- [ ] Compare computed value against declared `interfaceId`
- [ ] Apply to at least one representative interface (e.g., `IERC165`, `IFacet`)
- [ ] Tests pass

### US-CRANE-018.3: Document Comparator Behavior

As a developer, I want `Bytes4SetComparator` behavior clearly documented so that maintainers understand what assertions it performs.

**Acceptance Criteria:**
- [ ] `Bytes4SetComparator._compare()` has NatSpec explaining bidirectional checking
- [ ] Documentation notes that both `expectedMisses` and `actualMisses` are tracked
- [ ] Documentation explains failure conditions (missing expected, unexpected actual, length mismatch, duplicates)
- [ ] No code changes required beyond documentation

## Files to Create/Modify

**Modified Files:**
- `contracts/factories/diamondPkg/Behavior_IFacet.sol` - Add metadata consistency test
- `contracts/factories/diamondPkg/TestBase_IFacet.sol` - Add interface ID computation verification
- `contracts/test/comparators/Bytes4SetComparator.sol` - Add NatSpec documentation

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
