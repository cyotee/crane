# Task CRANE-155: Add Balancer V3 Vault Interface Coverage Tests

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-28
**Dependencies:** CRANE-141
**Worktree:** `feature/vault-interface-coverage-tests`
**Origin:** Code review suggestion from CRANE-141

---

## Description

Create comprehensive interface coverage tests for the Balancer V3 Vault Diamond. For each function selector in `IVaultMain`, `IVaultExtension`, and `IVaultAdmin`, verify that calling it via the Diamond does not revert with "function not found" and, where feasible, verify correct behavior.

(Created from code review of CRANE-141 - Suggestion 1)

## Dependencies

- CRANE-141: Refactor Balancer V3 Vault as Diamond Facets (parent task)

## User Stories

### US-CRANE-155.1: Interface Selector Coverage Tests

As a developer, I want comprehensive interface coverage tests so that I can verify the Diamond implements all required Balancer V3 Vault interfaces.

**Acceptance Criteria:**
- [ ] Test file enumerates all selectors from IVaultMain, IVaultExtension, IVaultAdmin
- [ ] Each selector is tested to ensure it routes to a facet (not "function not found")
- [ ] Tests verify return types match interface definitions
- [ ] Tests document which functions are stubs vs fully implemented
- [ ] Test suite identifies any missing selectors clearly

### US-CRANE-155.2: Interface Enumeration Helper

As a developer, I want a helper that extracts all interface selectors so that tests stay in sync with upstream Balancer interfaces.

**Acceptance Criteria:**
- [ ] Helper function/library enumerates IVaultMain selectors
- [ ] Helper function/library enumerates IVaultExtension selectors
- [ ] Helper function/library enumerates IVaultAdmin selectors
- [ ] Selectors extracted match canonical Balancer interface definitions

## Technical Details

### Interface Sources

```
lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/IVaultMain.sol
lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/IVaultExtension.sol
lib/balancer-v3-monorepo/pkg/interfaces/contracts/vault/IVaultAdmin.sol
```

### Test Structure

```solidity
contract BalancerV3VaultInterfaceCoverage is Test {
    // For each selector in IVaultMain
    function test_IVaultMain_allSelectorsRouted() public {
        bytes4[] memory selectors = _getIVaultMainSelectors();
        for (uint i = 0; i < selectors.length; i++) {
            address facet = IDiamondLoupe(address(diamond)).facetAddress(selectors[i]);
            assertNotEq(facet, address(0), _selectorToName(selectors[i]));
        }
    }

    // Similar for IVaultExtension, IVaultAdmin
}
```

## Files to Create/Modify

**New Files:**
- `test/foundry/spec/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultInterfaceCoverage.t.sol`

**Modified Files:**
- None

## Inventory Check

Before starting, verify:
- [ ] CRANE-141 implementation exists at contracts/protocols/dexes/balancer/v3/vault/diamond/
- [ ] Balancer V3 interface files are accessible
- [ ] DiamondLoupe is available (may depend on CRANE-158)

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] Tests enumerate 100% of interface selectors
- [ ] Tests pass (identifying stubs as expected)
- [ ] Build succeeds
- [ ] Test output clearly shows coverage status

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
