# Submodule Removal Plan

**Created:** 2026-01-31
**Updated:** 2026-01-31
**Status:** Phase 1 & 2 Complete

## Summary

Reduced submodule count from **26 to 8**, significantly improving worktree creation performance.

## Current State: 8 Submodules (Target Achieved)

| Submodule | Purpose | Status |
|-----------|---------|--------|
| `forge-std` | Test framework | KEEP |
| `openzeppelin-contracts` | Core ERC standards | KEEP |
| `solady` | Efficient utilities | KEEP |
| `solmate` | ERC20/utilities | KEEP |
| `reclamm` | Balancer V3 integration | KEEP |
| `permit2` | Permit2 integration | KEEP (until tests complete) |
| `v4-core` | Uniswap V4 | KEEP (until ported) |
| `v4-periphery` | Uniswap V4 | KEEP (until ported) |

## Completed Removals (18 Submodules)

### Phase 1: Zero-Risk Removals (Completely Unused) ✓

| Submodule | Notes |
|-----------|-------|
| `scaffold-eth-2` | Frontend boilerplate - not used |
| `solplot` | Plotting library - not used |
| `solidity-lib` | Uniswap's old library - not used |
| `evc-playground` | Euler example code - not used |
| `aave-v3-horizon` | Aave V3 - not used |
| `aave-v4` | Aave V4 - not used |
| `comet` | Compound V3 - not used |
| `euler-vault-kit` | Euler EVK - not used |
| `euler-price-oracle` | Euler oracles - not used |
| `evk-periphery` | Euler periphery - not used |
| `ethereum-vault-connector` | EVC - not used |
| `balancer-v3-monorepo` | Duplicate of reclamm's copy |

### Phase 2: Already-Ported Removals ✓

| Submodule | Ported To |
|-----------|-----------|
| `aerodrome-contracts` | `contracts/protocols/dexes/aerodrome/v1/` |
| `slipstream` | `contracts/protocols/dexes/aerodrome/slipstream/` |
| `v3-core` | `contracts/protocols/dexes/uniswap/v3/` |
| `v3-periphery` | `contracts/protocols/dexes/uniswap/v3/` |
| `resupply` | `contracts/protocols/cdps/resupply/` |
| `gsn` | `contracts/protocols/utils/gsn/` (Forwarder only) |

## GSN Port Details

The GSN submodule was removed and the required `Forwarder` contract was ported locally:

**New files:**
- `contracts/protocols/utils/gsn/forwarder/Forwarder.sol`
- `contracts/protocols/utils/gsn/forwarder/IForwarder.sol`

**Updated imports in:**
- `contracts/protocols/dexes/aerodrome/v1/stubs/ProtocolForwarder.sol`
- `contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome.sol`

**Remapping removed:**
- `@opengsn/contracts/=lib/gsn/packages/contracts/`

## Remaining Work

### Phase 3: Complete Permit2 Port (CRANE-171)

**Blocking tasks:**
- CRANE-168: Add SafeCast160 Unit Tests
- CRANE-169: Add Permit2Lib Integration Tests

Once tests are complete, remove `lib/permit2`.

### Phase 4: Port Uniswap V4 (CRANE-152)

Port v4-core and v4-periphery to local contracts, then remove submodules.

### Phase 5: Final Cleanup (CRANE-182)

1. Remove permit2 submodule (after Phase 3)
2. Remove v4-core and v4-periphery (after Phase 4)
3. Consider installing forge-std via `forge install` instead of submodule

## Final Target State

After all phases complete, only these submodules should remain:

1. `forge-std` - Test framework
2. `openzeppelin-contracts` - Core ERC standards
3. `solady` - Efficient utilities
4. `solmate` - ERC20/utilities
5. `reclamm` - Balancer V3 (until fully ported)

This will reduce from 26 submodules to 5, an **81% reduction**.

## Related Tasks

| Task ID | Description | Status |
|---------|-------------|--------|
| CRANE-148 | Verify Aerodrome Contract Port Completeness | Complete |
| CRANE-150 | Verify Permit2 Contract Port Completeness | Complete |
| CRANE-151 | Port and Verify Uniswap V3 Core + Periphery | Complete |
| CRANE-152 | Port and Verify Uniswap V4 Core + Periphery | Ready |
| CRANE-168 | Add SafeCast160 Unit Tests | In Progress |
| CRANE-169 | Add Permit2Lib Integration Tests | Ready |
| CRANE-170 | Document DeployPermit2 Bytecode Source | In Progress |
| CRANE-171 | Remove lib/permit2 Submodule | Blocked |
| CRANE-181 | Remove lib/aerodrome-contracts Submodule | **Complete** |
| CRANE-182 | Final Submodule Cleanup | In Progress |
| CRANE-186 | Remove v3-core and v3-periphery Submodules | **Complete** |
