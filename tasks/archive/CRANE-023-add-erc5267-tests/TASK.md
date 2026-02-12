# Task CRANE-023: Add ERC-5267 Test Coverage

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-13
**Dependencies:** CRANE-005
**Worktree:** `test/erc5267-coverage`
**Origin:** Code review suggestion from CRANE-005

---

## Description

Create dedicated test file for `eip712Domain()` function testing fields bitmap, chainId behavior, and extensions array. Currently ERC-5267 has limited test coverage.

(Created from code review of CRANE-005)

## Dependencies

- CRANE-005: Token Standards Review (parent task - Complete)

## User Stories

### US-CRANE-023.1: Add ERC-5267 Test Coverage

As a maintainer, I want comprehensive tests for ERC-5267 so that domain separator behavior is verified.

**Acceptance Criteria:**
- [x] Test file created at `test/foundry/spec/utils/cryptography/ERC5267/ERC5267Facet.t.sol`
- [x] Tests verify `eip712Domain()` return values
- [x] Tests verify fields bitmap correctness
- [x] Tests verify extensions array is empty
- [x] All tests pass

## Technical Details

**ERC-5267 Interface:**
```solidity
function eip712Domain()
    external
    view
    returns (
        bytes1 fields,
        string memory name,
        string memory version,
        uint256 chainId,
        address verifyingContract,
        bytes32 salt,
        uint256[] memory extensions
    );
```

**Test Cases to Add:**
1. Verify all returned fields match expected values
2. Verify fields bitmap indicates which fields are used (0x0f = name, version, chainId, verifyingContract)
3. Verify extensions array is empty
4. Verify chainId matches block.chainid
5. Verify verifyingContract matches address(this)

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/utils/cryptography/ERC5267/ERC5267Facet.t.sol`

## Inventory Check

Before starting, verify:
- [x] CRANE-005 is complete
- [x] `contracts/utils/cryptography/ERC5267/ERC5267Facet.sol` exists
- [x] `contracts/utils/cryptography/ERC5267/ERC5267Target.sol` exists

## Completion Criteria

- [x] Test file created with comprehensive coverage
- [x] All new tests pass
- [x] `forge build` passes
- [x] `forge test` passes

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
