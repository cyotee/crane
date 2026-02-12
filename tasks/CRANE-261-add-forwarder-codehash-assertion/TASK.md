# Task CRANE-261: Add Forwarder Codehash Equality Assertion

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-08
**Dependencies:** CRANE-239 (Complete)
**Worktree:** `fix/CRANE-261-add-forwarder-codehash-assertion`
**Origin:** Code review suggestion from CRANE-239

---

## Description

Add a defensive `assertEq` in `TestBase_OpenGSNFork.setUp()` to verify that `PortedForwarder` and `UpstreamForwarder` have the same codehash. The entire CRANE-239 fix relies on both forwarders being the same contract (and thus sharing the same constructor-registered type hash). If someone later changes the upstream import to a different contract, this assertion will fail early with a clear message rather than causing cryptic type hash mismatches.

Example:
```solidity
assertEq(address(portedForwarder).codehash, address(upstreamForwarder).codehash, "Forwarders must be same contract");
```

(Created from code review of CRANE-239)

## Dependencies

- CRANE-239: Fix OpenGSN Forwarder Fork Test Type Hash Registration (Complete)

## User Stories

### US-CRANE-261.1: Add codehash equality assertion

As a test maintainer, I want an explicit assertion that both forwarder instances are the same contract so that any future change that breaks this invariant produces a clear error message.

**Acceptance Criteria:**
- [ ] `setUp()` in `TestBase_OpenGSNFork.sol` asserts codehash equality between `portedForwarder` and `upstreamForwarder`
- [ ] Assertion message clearly explains the invariant
- [ ] All 16 OpenGSN fork tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `test/foundry/fork/ethereum_main/gsn/TestBase_OpenGSNFork.sol`

## Inventory Check

Before starting, verify:
- [ ] CRANE-239 is complete
- [ ] `TestBase_OpenGSNFork.sol` exists

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>PHASE_DONE</promise>`

**If blocked, output:** `<promise>BLOCKED: [reason]</promise>`
