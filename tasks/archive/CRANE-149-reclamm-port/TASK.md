# Task CRANE-149: Fork ReClaMM Pool to Local Contracts

**Repo:** Crane Framework
**Status:** Complete
**Created:** 2026-01-28
**Dependencies:** CRANE-141 (Balancer V3 Vault facets - for local imports)
**Worktree:** `feature/reclamm-port`

---

## Description

Fork the ReClaMM (Rebalancing Constant Liquidity AMM) pool contracts from `lib/reclamm` into `contracts/protocols/dexes/balancer/v3/reclamm/`. The ported contracts must be behavior and interface equivalent to serve as drop-in replacements. Imports should use the local Crane Diamond Vault port (CRANE-141) rather than the Balancer V3 submodule.

## Goal

Enable removal of the `lib/reclamm` submodule by having a complete local port that integrates with the Crane Diamond Vault infrastructure.

## Source Analysis

**Submodule Location:** `lib/reclamm/contracts/`
**Target Location:** `contracts/protocols/dexes/balancer/v3/reclamm/`

### ReClaMM Contract Structure

```
contracts/
├── ReClammPool.sol           # Main pool contract (~42KB)
├── ReClammPoolExtension.sol  # Pool extension (~22KB)
├── ReClammPoolFactory.sol    # Factory contract (~6KB)
├── ReClammStorage.sol        # Storage layout (~6KB)
├── ReClammCommon.sol         # Common utilities (~3KB)
├── interfaces/
│   ├── IReClammPool.sol
│   ├── IReClammPoolExtension.sol
│   ├── IReClammPoolMain.sol
│   ├── IReClammErrors.sol
│   └── IReClammEvents.sol
├── lib/
│   ├── ReClammMath.sol       # Core math library
│   └── ReClammPoolLib.sol    # Pool utilities
└── test/
    ├── ReClammMathMock.sol
    ├── ReClammPoolMock.sol
    ├── ReClammPoolFactoryMock.sol
    └── HardhatImports.sol
```

### Key Dependencies

ReClaMM imports from Balancer V3:
- `@balancer-labs/v3-vault/contracts/Vault.sol`
- `@balancer-labs/v3-interfaces/contracts/vault/IVault.sol`
- `@balancer-labs/v3-solidity-utils/contracts/*`

These must be remapped to use the local Crane Diamond Vault.

## Dependencies

- **CRANE-141**: Balancer V3 Vault Facets - Required for local Vault imports

## User Stories

### US-CRANE-149.1: Core Pool Contract Port

As a deployer, I want ReClammPool ported to use local Vault.

**Acceptance Criteria:**
- [ ] ReClammPool.sol copied and adapted
- [ ] Imports remapped to local Crane Vault
- [ ] All function signatures preserved
- [ ] Contract compiles successfully

### US-CRANE-149.2: Pool Extension Port

As a deployer, I want ReClammPoolExtension ported.

**Acceptance Criteria:**
- [ ] ReClammPoolExtension.sol ported
- [ ] Virtual balance management works
- [ ] Price bound updates work
- [ ] Integrates with local Vault

### US-CRANE-149.3: Factory Port

As a deployer, I want ReClammPoolFactory ported.

**Acceptance Criteria:**
- [ ] ReClammPoolFactory.sol ported
- [ ] Factory creates valid pools
- [ ] Works with local Vault registration

### US-CRANE-149.4: Math Libraries Port

As a developer, I want ReClaMM math libraries ported.

**Acceptance Criteria:**
- [ ] ReClammMath.sol ported (pure math, no external deps)
- [ ] ReClammPoolLib.sol ported
- [ ] All math functions work identically

### US-CRANE-149.5: Interfaces Port

As a developer, I want all interfaces ported.

**Acceptance Criteria:**
- [ ] All 5 interface files ported
- [ ] Function signatures match original
- [ ] Events match original
- [ ] Custom errors match original

### US-CRANE-149.6: Test Suite Adaptation

As a developer, I want ReClaMM tests adapted for local contracts.

**Acceptance Criteria:**
- [ ] Fork ReClaMM's Foundry test suite
- [ ] Adapt imports to local contracts
- [ ] All original tests pass
- [ ] Integration with Crane Vault verified

## Technical Details

### Import Remapping Strategy

Original imports:
```solidity
import "@balancer-labs/v3-vault/contracts/Vault.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
```

Remapped to:
```solidity
import "contracts/protocols/dexes/balancer/v3/vault/...";
// Or Diamond Vault interfaces
```

### File Structure After Port

```
contracts/protocols/dexes/balancer/v3/reclamm/
├── ReClammPool.sol
├── ReClammPoolExtension.sol
├── ReClammPoolFactory.sol
├── ReClammStorage.sol
├── ReClammCommon.sol
├── interfaces/
│   ├── IReClammPool.sol
│   ├── IReClammPoolExtension.sol
│   ├── IReClammPoolMain.sol
│   ├── IReClammErrors.sol
│   └── IReClammEvents.sol
└── lib/
    ├── ReClammMath.sol
    └── ReClammPoolLib.sol
```

### Contract Size Analysis

| Contract | Size | Notes |
|----------|------|-------|
| ReClammPool.sol | ~42KB | May need Diamond split if >24KB bytecode |
| ReClammPoolExtension.sol | ~22KB | Should be deployable |
| ReClammPoolFactory.sol | ~6KB | Small, no issues |
| ReClammMath.sol | Library | No size limit |

**Note:** If ReClammPool exceeds 24KB bytecode, consider splitting into facets similar to Vault.

## Files to Create/Modify

**New Files:**
- `contracts/protocols/dexes/balancer/v3/reclamm/*.sol` - All ported contracts
- `test/foundry/protocols/balancer/v3/reclamm/*.t.sol` - Adapted test suite

**Dependencies:**
- Requires CRANE-141 complete for Vault imports

## Completion Criteria

- [x] All ReClaMM contracts ported to local directory
- [x] Imports use local Crane Vault (not submodule)
- [x] All contracts compile successfully
- [x] Adapted test suite passes (206 passed, 1 expected failure, 4 skipped)
- [x] Function signatures match original (interface compatible)
- [x] Behavior matches original (drop-in replacement)

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
