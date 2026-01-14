# Review: CRANE-012 — Camelot V2 Utilities

## Status: Complete

## Review Checklist

### Deliverables Present
- [x] PROGRESS.md covers directional fees
- [x] PROGRESS.md covers fee-on-transfer handling
- [x] PROGRESS.md lists missing tests

### Quality Checks
- [x] Memo is clear and actionable
- [x] No regressions introduced

### Build Verification
- [x] `forge build` passes
- [x] `forge test` passes

## Review Notes

**Reviewer:** Automated
**Date:** 2026-01-13

### Feedback

Review findings documented in PROGRESS.md. All deliverables complete.

### Decision

- [x] Approved
- [ ] Changes Requested
- [ ] Blocked

---

## Suggestions Extracted from PROGRESS.md

The following suggestions were extracted from the review findings (Section: Missing Tests and Recommendations) and converted to tasks:

### Suggestion 1: Asymmetric Fee Testing
**Priority:** Critical
**Description:** Add tests that verify behavior when token0FeePercent != token1FeePercent (Camelot's distinguishing feature)
**User Response:** Accepted
**Notes:** Converted to task CRANE-044

### Suggestion 2: Stable Swap Pool Testing
**Priority:** High
**Description:** Add tests for CamelotPair.stableSwap mode - cubic invariant (x^3*y + y^3*x), _get_y() Newton-Raphson convergence
**User Response:** Accepted
**Notes:** Converted to task CRANE-045

### Suggestion 3: Protocol Fee Mint Parity Testing
**Priority:** Medium
**Description:** Add edge case tests for _calculateProtocolFee() - kLast=0, rootK==rootKLast, ownerFeeShare boundaries
**User Response:** Accepted
**Notes:** Converted to task CRANE-046

### Suggestion 4: Fee-on-Transfer Integration Testing
**Priority:** Medium
**Description:** Add tests with actual fee-on-transfer token stubs to verify quote accuracy and router behavior
**User Response:** Accepted
**Notes:** Converted to task CRANE-047

### Suggestion 5: Referrer Fee Integration Testing
**Priority:** Low
**Description:** Add tests for referrer fee share - quote accuracy when referrer rebate applies, fee distribution verification
**User Response:** Accepted
**Notes:** Converted to task CRANE-048

### Suggestion 6: K Invariant Preservation Tests
**Priority:** High
**Description:** Add invariant fuzz tests verifying K never decreases across all operations
**User Response:** Accepted
**Notes:** Converted to task CRANE-049

### Suggestion 7: Multi-Hop Swap with Directional Fees
**Priority:** Low
**Description:** Add tests for router multi-hop path handling with different fee configurations per hop
**User Response:** Accepted
**Notes:** Converted to task CRANE-050
