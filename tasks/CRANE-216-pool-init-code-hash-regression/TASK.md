# Task CRANE-216: Add POOL_INIT_CODE_HASH Regression Test

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-02-03
**Dependencies:** CRANE-201 (complete/archived)
**Worktree:** `test/pool-init-code-hash-regression`
**Origin:** Code review suggestion from CRANE-201

---

## Description

Add a dedicated test asserting `PoolAddress.POOL_INIT_CODE_HASH` matches `keccak256(type(UniswapV3Pool).creationCode)`.

Updating `PoolAddress.POOL_INIT_CODE_HASH` is cross-cutting: it affects deterministic pool address computation for all periphery consumers. This test prevents future drift between the constant and the actual pool creation code.

(Created from code review of CRANE-201)

## Dependencies

- CRANE-201: Add V3 NFT tokenURI Shape Test (complete/archived - parent task)

## User Stories

### US-CRANE-216.1: POOL_INIT_CODE_HASH Regression Test

As a developer, I want an automated test tying `POOL_INIT_CODE_HASH` to the actual pool creation code so that changes to either are detected.

**Acceptance Criteria:**
- [ ] Create test that computes `keccak256(type(UniswapV3Pool).creationCode)`
- [ ] Assert computed hash equals `PoolAddress.POOL_INIT_CODE_HASH`
- [ ] Test name clearly indicates purpose (e.g., `test_POOL_INIT_CODE_HASH_matchesCreationCode`)
- [ ] Tests pass
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- `contracts/protocols/dexes/uniswap/v3/periphery/libraries/PoolAddress.sol` (if hash needs updating)

**New Files:**
- `test/foundry/spec/protocols/dexes/uniswap/v3/periphery/PoolAddress.t.sol` (or similar location)

## Technical Notes

```solidity
// Example test pattern
function test_POOL_INIT_CODE_HASH_matchesCreationCode() public {
    bytes32 computed = keccak256(type(UniswapV3Pool).creationCode);
    assertEq(PoolAddress.POOL_INIT_CODE_HASH, computed, "POOL_INIT_CODE_HASH mismatch");
}
```

## Inventory Check

Before starting, verify:
- [ ] CRANE-201 is complete (check tasks/archive/)
- [ ] `PoolAddress.sol` exists with `POOL_INIT_CODE_HASH` constant
- [ ] `UniswapV3Pool.sol` exists and compiles

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests pass: `forge test --match-test POOL_INIT_CODE_HASH`
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
