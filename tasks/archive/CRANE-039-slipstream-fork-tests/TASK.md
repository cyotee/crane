# Task CRANE-039: Add Slipstream Fork Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-13
**Dependencies:** CRANE-011
**Worktree:** `test/slipstream-fork-tests`
**Origin:** Code review suggestion from CRANE-011

---

## Description

Add fork tests against real Base mainnet Slipstream pools to validate quote accuracy against live deployments. This provides real-world validation that complements the mock-based unit tests.

(Created from code review of CRANE-011)

## Dependencies

- CRANE-011: Slipstream Utilities Review (parent task - complete)

## User Stories

### US-CRANE-039.1: Fork Test Quote Accuracy

As a developer, I want fork tests that verify quotes against real Slipstream pools so that production accuracy is validated.

**Acceptance Criteria:**
- [ ] Fork tests query real Slipstream pool state on Base mainnet
- [ ] Test `_quoteExactInputSingle()` against real pools
- [ ] Test `_quoteExactOutputSingle()` against real pools
- [ ] Quotes match actual pool behavior within acceptable tolerance
- [ ] Tests pass on fork

### US-CRANE-039.2: Gas Benchmarks

As a developer, I want gas benchmarks for Slipstream operations so that performance is documented.

**Acceptance Criteria:**
- [ ] Gas measurements for single-tick quotes
- [ ] Gas measurements for multi-tick quotes (various tick crossing counts)
- [ ] Results documented in test output

## Technical Details

**Target Pools (Base Mainnet):**
- WETH/USDC Slipstream pool
- Other high-liquidity Slipstream pools

**Fork Test Pattern:**
```solidity
function test_fork_quoteExactInput_realPool() public {
    // Fork Base mainnet
    vm.createSelectFork(BASE_RPC_URL);

    // Get real pool
    ICLPool pool = ICLPool(SLIPSTREAM_WETH_USDC);

    // Quote using our utils
    uint256 quoted = SlipstreamUtils._quoteExactInputSingle(...);

    // Compare to quoter or actual swap
    // ...
}
```

## Files to Create/Modify

**New Files:**
- `test/foundry/protocols/dexes/aerodrome/slipstream/fork/SlipstreamUtils_fork.t.sol`
- `test/foundry/protocols/dexes/aerodrome/slipstream/fork/SlipstreamGas_fork.t.sol`

**Reference Files:**
- `contracts/protocols/dexes/aerodrome/slipstream/SlipstreamUtils.sol`
- `contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol`

## Inventory Check

Before starting, verify:
- [ ] Base mainnet RPC URL available
- [ ] Slipstream pool addresses identified
- [ ] Fork test infrastructure working

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Fork tests pass against Base mainnet
- [ ] Gas benchmarks documented
- [ ] `forge build` passes
- [ ] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
