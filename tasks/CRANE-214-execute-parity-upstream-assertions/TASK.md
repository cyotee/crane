# CRANE-214: Add Upstream Execute Parity Assertions

## Priority
Low

## Description
The CRANE-211 code review identified that `execute()` parity coverage is partial. While `execute()` success is exercised for both the ported Forwarder and upstream OpenGSN (via nonce increment + appended sender parity), the `test_execute_targetReverts()` and `test_execute_withValue()` tests only assert the ported behavior.

This task adds upstream-side assertions for the revert + value paths to make the "execute parity" claim unambiguous and complete.

## Background
From CRANE-211 REVIEW.md Finding #2:
> `execute()` success is exercised for both (via nonce increment + appended sender parity), but `test_execute_targetReverts()` and `test_execute_withValue()` only assert the ported behavior.

## Acceptance Criteria
- [ ] `test_execute_targetReverts()` includes upstream Forwarder assertions proving identical revert behavior
- [ ] `test_execute_withValue()` includes upstream Forwarder assertions proving identical value-forwarding behavior
- [ ] All fork tests pass with `INFURA_KEY` set
- [ ] Tests still skip gracefully when `INFURA_KEY` is unset

## Affected Files
- `test/foundry/fork/ethereum_main/gsn/OpenGSNForwarder_Fork.t.sol`

## Dependencies
- CRANE-211 (completed) - OpenGSN Forwarder Port + Fork Parity Tests

## Notes
This is a test coverage enhancement. The existing tests pass but don't fully prove parity for all execution paths.
