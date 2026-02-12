# Task CRANE-156: Fix Pool Token Selector Signatures in Vault Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-28
**Dependencies:** CRANE-141
**Worktree:** `feature/fix-pool-token-selectors`
**Origin:** Code review suggestion from CRANE-141

---

## Description

Fix the pool-token selector cutting in the Vault Diamond tests. The current tests use signatures with an explicit `pool` parameter, but the Balancer interfaces define these functions without a `pool` parameter (pool is `msg.sender`). This mismatch means tests pass while cutting incorrect selectors.

(Created from code review of CRANE-141 - Suggestion 2)

## Dependencies

- CRANE-141: Refactor Balancer V3 Vault as Diamond Facets (parent task)

## User Stories

### US-CRANE-156.1: Fix Pool Token Selector Signatures

As a developer, I want the test selector signatures to match the actual Balancer interface so that the Diamond correctly routes real Balancer calls.

**Acceptance Criteria:**
- [ ] Remove explicit `pool` parameter from test selector definitions
- [ ] Selectors match `IVaultMain`/`IVaultExtension` pool-token signatures exactly
- [ ] Update `_getPoolTokenFacetSelectors()` helper in test file
- [ ] Verify VaultPoolTokenFacet implementation matches interface signatures

### US-CRANE-156.2: Verify Selector Routing After Fix

As a developer, I want to verify the fixed selectors route correctly so that the Diamond works with real Balancer callers.

**Acceptance Criteria:**
- [ ] Tests verify each pool-token function can be called via Diamond
- [ ] Tests verify `msg.sender` is treated as the pool address
- [ ] Document if VaultPoolTokenFacet needs implementation changes

## Technical Details

### Current (Incorrect) Test Selectors

```solidity
// These have an extra pool parameter that doesn't exist in the interface
selectors[0] = bytes4(keccak256("transfer(address,address,address,uint256)"));  // pool,from,to,amount
selectors[1] = bytes4(keccak256("transferFrom(address,address,address,uint256)"));
selectors[2] = bytes4(keccak256("approve(address,address,address,uint256)"));  // pool,owner,spender,amount
selectors[3] = bytes4(keccak256("balanceOf(address,address)"));  // pool,account
selectors[4] = bytes4(keccak256("totalSupply(address)"));  // pool
```

### Correct Interface Signatures

From Balancer's `IVaultMain`:
```solidity
// Pool token functions - pool is msg.sender
function approve(address owner, address spender, uint256 amount) external returns (bool);
function transfer(address owner, address to, uint256 amount) external returns (bool);
function transferFrom(address spender, address from, address to, uint256 amount) external returns (bool);
function balanceOf(address token, address account) external view returns (uint256);
function totalSupply(address token) external view returns (uint256);
```

### Corrected Test Selectors

```solidity
selectors[0] = bytes4(keccak256("approve(address,address,uint256)"));
selectors[1] = bytes4(keccak256("transfer(address,address,uint256)"));
selectors[2] = bytes4(keccak256("transferFrom(address,address,address,uint256)"));
selectors[3] = bytes4(keccak256("balanceOf(address,address)"));
selectors[4] = bytes4(keccak256("totalSupply(address)"));
```

## Files to Create/Modify

**Modified Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDiamond.t.sol` - Fix `_getPoolTokenFacetSelectors()`
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultPoolTokenFacet.sol` - Verify/fix implementation signatures

## Inventory Check

Before starting, verify:
- [ ] VaultPoolTokenFacet exists
- [ ] Balancer interface files are accessible for reference
- [ ] Existing tests pass before changes

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Selector signatures match Balancer interfaces exactly
- [ ] Tests pass with corrected selectors
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
