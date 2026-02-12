# CRANE-077: Remove Commented-Out Parameter Stubs from ConstProdUtils

**Status:** Ready
**Priority:** Low
**Origin:** CRANE-029 REVIEW.md Suggestion 1
**Dependencies:** None

---

## Summary

Remove remaining commented-out parameter stubs from ConstProdUtils.sol that were left behind during the main dead code cleanup (CRANE-029).

## Background

During CRANE-029, the bulk of dead code (516 lines) was removed from ConstProdUtils.sol. However, a few small commented-out parameter fragments remain that read like previously-planned parameters. These should be removed or reintroduced as real parameters if still intended.

## Scope

**Files:**
- `contracts/utils/math/ConstProdUtils.sol`

**Known instances:**
- `// uint256 bufferPct` in `_quoteZapOutToTargetWithFee`
- Any other similar commented-out parameter stubs

## Acceptance Criteria

### US-CRANE-077.1: Remove Parameter Stubs

- [ ] Identify all commented-out parameter stubs in ConstProdUtils.sol
- [ ] Remove each stub OR document why it should be kept/reintroduced
- [ ] No functional changes to the contract
- [ ] Tests pass
- [ ] Build succeeds

## Verification

```bash
# Build
forge build

# Run ConstProdUtils tests
forge test --match-path "test/foundry/spec/utils/math/constProdUtils/*.t.sol"
```

## Notes

- This is a cleanup task with no behavioral changes
- If any parameter stub represents planned future functionality, document it in PROGRESS.md before removal
