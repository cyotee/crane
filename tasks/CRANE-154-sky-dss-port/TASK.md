# Task CRANE-154: Port Sky/DSS Protocol to Local Contracts

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-28
**Dependencies:** None
**Worktree:** `feature/sky-dss-port`

---

## Description

Port the MakerDAO DSS (Multi-Collateral DAI) system from lib/dss, lib/dss-deploy, and lib/dss-test into local contracts at `contracts/protocols/cdps/sky/`. This provides a self-contained, Solidity 0.8+ modernized version of the CDP system with exact ABI compatibility for fork testing. The port includes all core modules, dependency libraries (ds-token, ds-auth, etc.), interfaces, test utilities, and cross-chain domain support.

## Dependencies

- None

## User Stories

### US-CRANE-154.1: Core DSS Contract Port

As a developer, I want local copies of the DSS core contracts so that I can test CDP functionality without external dependencies.

**Acceptance Criteria:**
- [ ] All DSS core contracts ported to `contracts/protocols/cdps/sky/core/`:
  - Vat.sol (CDP database)
  - Dai.sol (DAI token)
  - Dog.sol (liquidation engine)
  - Cat.sol (legacy liquidation)
  - Jug.sol (interest rate accumulation)
  - Pot.sol (DAI Savings Rate)
  - Spot.sol (price feed integration)
  - Vow.sol (system surplus/deficit)
  - End.sol (global settlement)
  - Flap.sol (surplus auction)
  - Flip.sol (collateral auction)
  - Flop.sol (debt auction)
  - Clip.sol (liquidation 2.0)
  - Join.sol (token adapters)
  - Abaci.sol (auction price calculators)
- [ ] Contracts compile with Solidity ^0.8.0
- [ ] Function signatures match mainnet DSS exactly (ABI compatibility)
- [ ] All math operations properly handle Solidity 0.8 overflow checks with unchecked blocks where needed

### US-CRANE-154.2: DS-Library Dependencies Port

As a developer, I want local copies of the ds-* dependency libraries so that DSS contracts are self-contained.

**Acceptance Criteria:**
- [ ] Port ds-token to `contracts/protocols/cdps/sky/dependencies/ds-token/`
- [ ] Port ds-auth to `contracts/protocols/cdps/sky/dependencies/ds-auth/`
- [ ] Port ds-math to `contracts/protocols/cdps/sky/dependencies/ds-math/`
- [ ] Port ds-value to `contracts/protocols/cdps/sky/dependencies/ds-value/`
- [ ] Port ds-note to `contracts/protocols/cdps/sky/dependencies/ds-note/`
- [ ] All dependencies modernized to Solidity ^0.8.0
- [ ] Import paths updated to local references

### US-CRANE-154.3: DSS Interfaces Port

As a developer, I want local copies of all DSS interface abstracts so that I can interact with DSS contracts via standard patterns.

**Acceptance Criteria:**
- [ ] Port all dss-interfaces/src/dss/*.sol to `contracts/protocols/cdps/sky/interfaces/dss/`
- [ ] Port all dss-interfaces/src/dapp/*.sol to `contracts/protocols/cdps/sky/interfaces/dapp/`
- [ ] Port dss-interfaces/src/ERC/*.sol if needed
- [ ] Interfaces compile and match mainnet ABIs

### US-CRANE-154.4: DSS Test Utilities Port

As a developer, I want local test utilities for DSS testing so that I can write comprehensive tests.

**Acceptance Criteria:**
- [ ] Port DssTest.sol to `contracts/protocols/cdps/sky/test/DssTest.sol`
- [ ] Port GodMode.sol to `contracts/protocols/cdps/sky/test/GodMode.sol`
- [ ] Port MCD.sol to `contracts/protocols/cdps/sky/test/MCD.sol`
- [ ] Port MCDUser.sol to `contracts/protocols/cdps/sky/test/MCDUser.sol`
- [ ] Port ScriptTools.sol to `contracts/protocols/cdps/sky/test/ScriptTools.sol`
- [ ] All test utilities updated for Solidity ^0.8.0

### US-CRANE-154.5: Cross-chain Domain Utilities Port

As a developer, I want cross-chain domain utilities so that I can test L2 bridging scenarios.

**Acceptance Criteria:**
- [ ] Port Domain.sol to `contracts/protocols/cdps/sky/test/domains/Domain.sol`
- [ ] Port ArbitrumDomain.sol to `contracts/protocols/cdps/sky/test/domains/ArbitrumDomain.sol`
- [ ] Port OptimismDomain.sol to `contracts/protocols/cdps/sky/test/domains/OptimismDomain.sol`
- [ ] Port BridgedDomain.sol to `contracts/protocols/cdps/sky/test/domains/BridgedDomain.sol`
- [ ] Port RootDomain.sol to `contracts/protocols/cdps/sky/test/domains/RootDomain.sol`
- [ ] Port RecordedLogs.sol to `contracts/protocols/cdps/sky/test/domains/RecordedLogs.sol`

### US-CRANE-154.6: Mock Chainlog Implementation

As a developer, I want a mock chainlog so that tests can resolve contract addresses without mainnet dependencies.

**Acceptance Criteria:**
- [ ] Create MockChainlog.sol in `contracts/protocols/cdps/sky/test/mocks/MockChainlog.sol`
- [ ] Mock supports setAddress(bytes32, address) for registration
- [ ] Mock supports getAddress(bytes32) for lookup
- [ ] MCD.sol library updated to work with mock chainlog

### US-CRANE-154.7: FactoryService and TestBase

As a developer, I want a FactoryService library and TestBase to deploy and test DSS locally.

**Acceptance Criteria:**
- [ ] Create SkyDssFactoryService.sol in `contracts/protocols/cdps/sky/services/SkyDssFactoryService.sol`
- [ ] FactoryService deploys complete DSS system (Vat, Dai, Jug, etc.)
- [ ] FactoryService initializes default ilks
- [ ] Create TestBase_SkyDss.sol in `contracts/protocols/cdps/sky/test/bases/TestBase_SkyDss.sol`
- [ ] TestBase provides helpers for CDP operations (open, lock, draw, wipe, free)
- [ ] TestBase extends DssTest for utility functions

## Technical Details

### Directory Structure

```
contracts/protocols/cdps/sky/
├── core/                         # Core DSS contracts
│   ├── Vat.sol
│   ├── Dai.sol
│   ├── Dog.sol
│   ├── Cat.sol
│   ├── Jug.sol
│   ├── Pot.sol
│   ├── Spot.sol
│   ├── Vow.sol
│   ├── End.sol
│   ├── Flap.sol
│   ├── Flip.sol
│   ├── Flop.sol
│   ├── Clip.sol
│   ├── Join.sol
│   └── Abaci.sol
├── dependencies/                 # DS-library dependencies
│   ├── ds-token/
│   │   └── DSToken.sol
│   ├── ds-auth/
│   │   └── DSAuth.sol
│   ├── ds-math/
│   │   └── DSMath.sol
│   ├── ds-value/
│   │   └── DSValue.sol
│   └── ds-note/
│       └── DSNote.sol
├── interfaces/                   # DSS interface abstracts
│   ├── dss/
│   │   ├── VatAbstract.sol
│   │   ├── DaiAbstract.sol
│   │   └── ... (all dss interfaces)
│   └── dapp/
│       ├── DSTokenAbstract.sol
│       └── ... (all dapp interfaces)
├── services/
│   └── SkyDssFactoryService.sol  # Deployment orchestration
└── test/
    ├── DssTest.sol               # Base test utilities
    ├── GodMode.sol               # Cheat codes wrapper
    ├── MCD.sol                   # MCD instance helpers
    ├── MCDUser.sol               # Test user wrapper
    ├── ScriptTools.sol           # Script utilities
    ├── mocks/
    │   └── MockChainlog.sol      # Local chainlog mock
    ├── domains/
    │   ├── Domain.sol
    │   ├── ArbitrumDomain.sol
    │   ├── OptimismDomain.sol
    │   ├── BridgedDomain.sol
    │   ├── RootDomain.sol
    │   └── RecordedLogs.sol
    └── bases/
        └── TestBase_SkyDss.sol   # Test base for DSS testing
```

### Solidity 0.8 Modernization Notes

1. **Overflow handling**: DSS uses custom safe math. With Solidity 0.8, wrap intentional overflow operations in `unchecked { }` blocks.

2. **Constructor visibility**: Remove `public` from constructors (deprecated in 0.8).

3. **Pragma**: Change `pragma solidity >=0.5.12;` to `pragma solidity ^0.8.0;`

4. **Error strings to custom errors**: Consider adding custom errors while keeping original revert strings for compatibility.

5. **ABIEncoderV2**: No longer needed as pragma directive in 0.8+.

### ABI Compatibility Requirements

To maintain fork testing compatibility with mainnet DSS:
- Keep all function signatures identical
- Keep all event signatures identical
- Keep all public/external state variable names identical
- Keep storage layouts compatible where practical

### Key Interfaces to Preserve

```solidity
// Vat core interface
function frob(bytes32 ilk, address u, address v, address w, int dink, int dart) external;
function grab(bytes32 ilk, address u, address v, address w, int dink, int dart) external;
function fork(bytes32 ilk, address src, address dst, int dink, int dart) external;
function slip(bytes32 ilk, address usr, int256 wad) external;
function flux(bytes32 ilk, address src, address dst, uint256 wad) external;
function move(address src, address dst, uint256 rad) external;
function hope(address usr) external;
function nope(address usr) external;
function init(bytes32 ilk) external;
function file(bytes32 what, uint data) external;
function file(bytes32 ilk, bytes32 what, uint data) external;
function cage() external;
function heal(uint rad) external;
function suck(address u, address v, uint rad) external;
function fold(bytes32 i, address u, int rate) external;
```

## Files to Create/Modify

**New Files:**
- All files listed in directory structure above (~60+ files)

**Modified Files:**
- `foundry.toml` - Add remappings for `@sky/` → `contracts/protocols/cdps/sky/`

**Tests:**
- `test/protocols/cdps/sky/SkyDss.t.sol` - Basic deployment and operation tests
- `test/protocols/cdps/sky/SkyDss.fork.t.sol` - Fork tests against mainnet (optional)

## Inventory Check

Before starting, verify:
- [ ] lib/dss submodule is initialized and contains source files
- [ ] lib/dss-test submodule is initialized and contains source files
- [ ] lib/dss-test/lib/dss-interfaces submodule is initialized
- [ ] contracts/protocols/cdps/sky directory exists (create if needed)
- [ ] All source contracts are readable

## Completion Criteria

- [ ] All core DSS contracts ported and compile
- [ ] All dependency libraries ported and compile
- [ ] All interfaces ported and compile
- [ ] All test utilities ported and compile
- [ ] Mock chainlog implemented
- [ ] FactoryService deploys complete system
- [ ] TestBase provides testing helpers
- [ ] Basic unit tests pass
- [ ] No compiler warnings
- [ ] Import paths use local references only

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
