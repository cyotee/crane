# Task CRANE-226: Fix BetterStrings toHexString Missing "0x" Prefix (1 test)

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-05
**Dependencies:** None
**Worktree:** `fix/betterstrings-hex-prefix`

---

## Description

`BetterStrings._toHexString(uint256, uint256)` calls `LibString.toHexStringNoPrefix()` instead of a prefixed version, causing it to return `"1234"` instead of `"0x1234"`. This is inconsistent with the other `toHexString` overloads in the same library (which include the prefix) and breaks OZ API compatibility. The fix is to call the prefixed version or manually prepend "0x".

## Dependencies

- None

## User Stories

### US-CRANE-226.1: Fix Hex String Prefix Consistency

As a developer, I want `toHexString(uint256, uint256)` to return hex strings with the "0x" prefix so that it's consistent with the other `toHexString` overloads and OZ compatibility.

**Acceptance Criteria:**
- [ ] `test__toHexString_uint_len` passes
- [ ] `toHexString(uint256, uint256)` returns "0x"-prefixed strings
- [ ] Other `toHexString` overloads are not affected

## Technical Details

### Root Cause

In `contracts/utils/Strings.sol`, the function at line ~44-46:
```solidity
function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    return LibString.toHexStringNoPrefix(value, length);  // BUG: no prefix
}
```

Other overloads in the same file correctly use `LibString.toHexString()` (with prefix).

### Fix

Change `toHexStringNoPrefix` to `toHexString`:
```solidity
function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    return LibString.toHexString(value, length);  // Now includes "0x" prefix
}
```

### Affected Test (1 total)

**test/foundry/spec/utils/BetterStrings.t.sol:**
- `test__toHexString_uint_len` - asserts `"0x1234"` but gets `"1234"`

## Files to Create/Modify

**Modified Files:**
- `contracts/utils/Strings.sol` - Change `toHexStringNoPrefix` to `toHexString` in the `(uint256, uint256)` overload

## Inventory Check

Before starting, verify:
- [ ] `LibString.toHexString(uint256, uint256)` exists and returns "0x"-prefixed strings
- [ ] No other code depends on the no-prefix behavior of this specific overload

## Completion Criteria

- [ ] `test__toHexString_uint_len` passes
- [ ] All other BetterStrings tests still pass
- [ ] Build succeeds with no new warnings

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
