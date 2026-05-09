# Uniswap Continuous Close Auction Porting Plan

## Overview

Port the Uniswap Continuous Clearing Auction (CCA) code from `lib/continuous-clearing-auction` into the Crane framework structure.

## Source Structure

**Original Source**: `/Users/cyotee/Development/github-cyotee/indexedex/lib/daosys/lib/crane/lib/continuous-clearing-auction`

### Source Files (33 Solidity files)
```
src/
├── BidStorage.sol
├── CheckpointStorage.sol
├── ContinuousClearingAuction.sol
├── ContinuousClearingAuctionFactory.sol
├── StepStorage.sol
├── TickStorage.sol
├── TokenCurrencyStorage.sol
├── interfaces/
│   ├── external/
│   │   ├── IDistributionStrategy.sol
│   │   ├── IERC20Minimal.sol
│   │   ├── ILBPInitializer.sol
│   │   └── IDistributionContract.sol
│   ├── IContinuousClearingAuction.sol
│   ├── IContinuousClearingAuctionFactory.sol
│   ├── ICheckpointStorage.sol
│   ├── IBidStorage.sol
│   ├── IStepStorage.sol
│   ├── ITickStorage.sol
│   ├── ITokenCurrencyStorage.sol
│   └── IValidationHook.sol
├── lens/
│   └── AuctionStateLens.sol
├── libraries/
│   ├── BidLib.sol
│   ├── CheckpointAccountingLib.sol
│   ├── CheckpointLib.sol
│   ├── ConstantsLib.sol
│   ├── CurrencyLibrary.sol
│   ├── FixedPoint96.sol
│   ├── MaxBidPriceLib.sol
│   ├── StepLib.sol
│   ├── ValidationHookLib.sol
│   └── ValueX7Lib.sol
└── periphery/
    └── validationHooks/
        ├── BaseERC1155ValidationHook.sol
        ├── GatedERC1155ValidationHook.sol
        └── ValidationHookIntrospection.sol
```

### Test Files (93 Solidity files)
```
test/
├── Assertions.t.sol
├── Auction.dos.t.sol
├── Auction.graduation.t.sol
├── Auction.invariant.t.sol
├── Auction.steps.t.sol
├── Auction.submitBid.t.sol
├── Auction.t.sol
├── AuctionFactory.t.sol
├── AuctionStepStorage.t.sol
├── BidStorage.t.sol
├── CheckpointStorage.t.sol
├── TickStorage.t.sol
├── btt/
│   ├── BttBase.sol
│   ├── auction/
│   ├── auctionFactory/
│   ├── auctionStepStorage/
│   ├── bidStorage/
│   ├── checkpointStorage/
│   ├── libraries/
│   │   ├── auctionStepLib/
│   │   ├── bidlib/
│   │   ├── checkpointAccountingLib/
│   │   ├── checkpointLib/
│   │   ├── maxBidPriceLib/
│   │   └── validationHookLib/
│   ├── mocks/
│   └── tokenCurrencyStorage/
│   └── tickstorage/
├── lens/
│   └── AuctionStateLens.t.sol
├── libraries/
│   ├── BidLib.t.sol
│   └── ValidationHookLib.t.sol
├── periphery/
│   └── validationHooks/
│       ├── BaseERC1155ValidationHook.t.sol
│       └── GatedERC1155ValidationHook.sol
├── unit/
│   ├── Auction.iterateOverTicks.t.sol
│   ├── Auction.iterateOverTicksAndFindClearingPrice.t.sol
│   ├── AuctionUnitTest.sol
│   └── sellTokensAtClearingPrice.t.sol
└── utils/
    ├── AuctionBaseTest.sol
    ├── AuctionParamsBuilder.sol
    ├── AuctionStepsBuilder.sol
    ├── Assertions.sol
    ├── FuzzStructs.sol
    ├── LiquidityAmountsUint256.sol
    ├── MockAuction.sol
    ├── MockBidStorage.sol
    ├── MockCheckpointStorage.sol
    ├── MockFundsRecipient.sol
    ├── MockReenteringValidationHook.sol
    ├── MockRevertingValidationHook.sol
    ├── MockStepStorage.sol
    ├── MockToken.sol
    ├── MockValidationHook.sol
    ├── MockValidationHookLib.sol
    ├── TickBitmap.sol
    └── TokenHandler.sol
```

## Target Structure

### Main Contract Destination
```
contracts/protocols/launchpads/uniswap/continuous-clearing/
```

### Dependencies Destination
```
contracts/protocols/launchpads/uniswap/continuous-clearing/dependencies/
```

### Test Destination
```
test/foundry/spec/protocols/launchpads/uniswap/continuous-clearing/
```

## Dependencies Analysis

### From `lib/continuous-clearing-auction/lib/`

| Dependency | Status in Crane | Action |
|------------|-----------------|--------|
| `forge-std` | EXISTS at `lib/forge-std` | SKIP - reuse existing |
| `forge-chronicles` | NOT PRESENT | PORT to dependencies |
| `forge-gas-snapshot` | NOT PRESENT | PORT to dependencies |
| `blocknumberish` | NOT PRESENT | PORT to dependencies |
| `permit2` | NOT PRESENT | PORT to dependencies |
| `solady` | NOT PRESENT | PORT to dependencies |
| `v4-periphery` | NOT PRESENT | PORT to dependencies |
| `openzeppelin-contracts` | NOT PRESENT | PORT to dependencies |
| `openzeppelin-contracts-upgradeable` | NOT PRESENT | PORT to dependencies (if needed) |

### Dependencies to Port (8 libraries)
1. **blocknumberish** - Block number abstraction utility
2. **forge-chronicles** - Forge logging/chronicles utility
3. **forge-gas-snapshot** - Gas snapshot utility for Forge
4. **permit2** - Uniswap Permit2 (src/ only, not test/)
5. **solady** - Minimalistic Solidity library
6. **v4-periphery** - Uniswap V4 Periphery (only needed interfaces)
7. **openzeppelin-contracts** - OpenZeppelin standard contracts
8. **openzeppelin-contracts-upgradeable** - OpenZeppelin upgradeable contracts (if needed)

## Implementation Steps

### Phase 1: Dependency Porting
1. Create `dependencies/` directory structure
2. Port `blocknumberish` (lib/blocknumberish/)
3. Port `forge-chronicles` (lib/forge-chronicles/)
4. Port `forge-gas-snapshot` (lib/forge-gas-snapshot/)
5. Port `permit2/src/` (lib/permit2/src/)
6. Port `solady/` (lib/solady/) - selective port of used files
7. Port `v4-periphery/` (lib/v4-periphery/) - selective port of used interfaces
8. Port `openzeppelin-contracts/` (lib/openzeppelin-contracts/) - selective port of used contracts
9. Port `openzeppelin-contracts-upgradeable/` (lib/openzeppelin-contracts-upgradeable/) - if needed

### Phase 2: Main Contract Porting
1. Create directory structure under `continuous-clearing/`
2. Port all 33 source files preserving directory structure
3. Update import paths to use relative paths (NO remappings)

### Phase 3: Test Porting
1. Create test directory structure
2. Port all 93 test files
3. Update imports to reference ported dependencies
4. Port test utility files

### Phase 4: Configuration
1. Add forge fmt ignore patterns for dependencies
2. Add skip patterns for dependencies in foundry.toml lint
3. Verify compilation
4. Run tests to ensure functional equivalence

## Import Path Strategy (NO REMAPPINGS)

All imports within the ported code must use **relative paths**. No custom remappings will be added to `foundry.toml`.

### Import Path Transformations

| Original Import | New Import (Relative) |
|-----------------|----------------------|
| `continuous-clearing-auction/src/...` | `./` (same directory) |
| `forge-std/src/...` | Use existing Crane remapping `forge-std/` |
| `@openzeppelin/contracts/...` | `./dependencies/openzeppelin-contracts/contracts/` |
| `@openzeppelin/contracts-upgradeable/...` | `./dependencies/openzeppelin-contracts-upgradeable/contracts/` |
| `permit2/...` | `./dependencies/permit2/src/` |
| `solady/...` | `./dependencies/solady/src/` |
| `v4-periphery/...` | `./dependencies/v4-periphery/` |
| `blocknumberish/...` | `./dependencies/blocknumberish/src/` |
| `forge-chronicles/...` | `./dependencies/forge-chronicles/src/` |
| `forge-gas-snapshot/...` | `./dependencies/forge-gas-snapshot/src/` |

### Example Transformations

**Before (original):**
```solidity
import {Permit2} from "permit2/src/Permit2.sol";
import {SafeCast} from "solady/src/utils/SafeCast.sol";
import {ContinuousClearingAuction} from "continuous-clearing-auction/src/ContinuousClearingAuction.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
```

**After (ported):**
```solidity
import {Permit2} from "./dependencies/permit2/src/Permit2.sol";
import {SafeCast} from "./dependencies/solady/src/utils/SafeCast.sol";
import {ContinuousClearingAuction} from "./ContinuousClearingAuction.sol";
import {IERC20} from "./dependencies/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
```

### Crane's Existing Remappings (USE THESE)

Do NOT re-add these remappings. Use them as-is:
```
forge-std/=lib/forge-std/src/
@crane/contracts/=contracts/
```

**IMPORTANT**: OpenZeppelin contracts are NOT remapped. All OpenZeppelin imports must use relative paths via `./dependencies/openzeppelin-contracts/...`.

## Verification Checklist

- [ ] All source files compile without errors
- [ ] All test files compile without errors
- [ ] Tests pass with `forge test`
- [ ] No duplicate definitions (check existing Crane code)
- [ ] All imports use relative paths (no custom remappings)
- [ ] Integration tests work with original submodule

## Notes

- The original repo uses `solc = "0.8.26"`, but Crane uses `solc = "0.8.34"`
- Check for compatibility issues with newer Solidity version
- Some external dependencies (e.g., v4-periphery) may have their own complex dependencies
- Consider if Crane already has equivalent functionality (e.g., OpenZeppelin)
- **CRITICAL**: All imports MUST be converted to relative paths. Do not use remappings.
