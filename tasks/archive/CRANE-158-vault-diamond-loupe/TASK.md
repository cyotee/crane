# Task CRANE-158: Add DiamondLoupe Support to Balancer V3 Vault

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-28
**Dependencies:** CRANE-141
**Worktree:** `feature/vault-diamond-loupe`
**Origin:** Code review suggestion from CRANE-141

---

## Description

Add EIP-2535 DiamondLoupe support to the Balancer V3 Vault Diamond. The CRANE-141 acceptance criteria called for DiamondLoupe functions, but the current implementation only provides `diamondCut()` and fallback routing. DiamondLoupe is needed for introspection and is required by other tasks (e.g., CRANE-155 interface coverage tests).

(Created from code review of CRANE-141 - Suggestion 4)

## Dependencies

- CRANE-141: Refactor Balancer V3 Vault as Diamond Facets (parent task)

## User Stories

### US-CRANE-158.1: Implement IDiamondLoupe Interface

As a developer, I want DiamondLoupe functions available so that I can introspect the Diamond's facets and selectors.

**Acceptance Criteria:**
- [ ] `facets()` returns all facets with their selectors
- [ ] `facetFunctionSelectors(address)` returns selectors for a specific facet
- [ ] `facetAddresses()` returns all facet addresses
- [ ] `facetAddress(bytes4)` returns the facet for a specific selector
- [ ] All functions match IDiamondLoupe interface exactly

### US-CRANE-158.2: ERC-165 Support for DiamondLoupe

As a developer, I want ERC-165 to report DiamondLoupe support so that tools can detect the interface.

**Acceptance Criteria:**
- [ ] `supportsInterface(IDiamondLoupe.interfaceId)` returns true
- [ ] `supportsInterface(IDiamondCut.interfaceId)` returns true
- [ ] `supportsInterface(IERC165.interfaceId)` returns true

## Technical Details

### IDiamondLoupe Interface

```solidity
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    function facets() external view returns (Facet[] memory facets_);
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);
    function facetAddresses() external view returns (address[] memory facetAddresses_);
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}
```

### Implementation Options

**Option A: Add DiamondLoupe Facet**
Create a new `DiamondLoupeFacet.sol` that reads from `ERC2535Repo` and cut it into the Diamond.

**Option B: Implement Directly on Diamond Proxy**
Add the loupe functions directly to `BalancerV3VaultDiamond.sol` alongside `diamondCut()`.

**Recommendation:** Option A (facet) is more modular and follows the Diamond pattern.

### Integration with ERC2535Repo

The existing `ERC2535Repo` should already track facets and selectors. The loupe facet needs to:
1. Enumerate all facet addresses from storage
2. For each facet, enumerate its selectors
3. Provide reverse lookup (selector → facet)

## Files to Create/Modify

**New Files:**
- `contracts/protocols/dexes/balancer/v3/vault/diamond/facets/DiamondLoupeFacet.sol` - Loupe implementation

**Modified Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDiamond.t.sol` - Add loupe facet to cuts, add loupe tests
- `contracts/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDiamond.sol` - Optionally add ERC-165 support

## Inventory Check

Before starting, verify:
- [ ] ERC2535Repo provides storage enumeration helpers
- [ ] IDiamondLoupe interface is available in contracts/interfaces/
- [ ] Existing Diamond tests pass

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] DiamondLoupe facet implemented and cut into Diamond
- [ ] All 4 loupe functions work correctly
- [ ] ERC-165 reports DiamondLoupe support
- [ ] Tests pass
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
