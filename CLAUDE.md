# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Test Commands

```bash
# Compile contracts
forge build

# Run all Foundry tests
forge test

# Run a specific test file
forge test --match-path test/foundry/spec/utils/math/constProdUtils/ConstProdUtils_purchaseQuote_Camelot.t.sol

# Run tests matching a pattern
forge test --match-test testPurchaseQuote

# Run tests with verbosity (show traces)
forge test -vvv

# Run Hardhat tests
npx hardhat test

# Run both test suites
npm run test-all

# Format Solidity code
forge fmt
```

## Architecture Overview

Crane is a Diamond-first (ERC2535) Solidity development framework for building modular, upgradeable smart contracts.

### Core Pattern: Facet-Target-Repo

Every feature follows a three-tier architecture:

| Layer | File Pattern | Purpose |
|-------|--------------|---------|
| **Repo** | `*Repo.sol` | Storage library with assembly-based slot binding. Defines `Storage` struct and dual `_layout()` functions. No state variables. |
| **Target** | `*Target.sol` | Implementation contract with business logic. Uses Repo for storage access. Inherits interfaces. |
| **Facet** | `*Facet.sol` | Diamond facet. Extends Target and implements `IFacet` for metadata (name, interfaces, selectors). |

### Storage Slot Pattern

All Repos use the Diamond storage pattern with dual function overloads:

```solidity
library ExampleRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256(abi.encode("crane.feature.name"));

    struct Storage {
        mapping(address => bool) isOperator;
    }

    // Parameterized version - allows custom slot
    function _layout(bytes32 slot) internal pure returns (Storage storage layout) {
        assembly { layout.slot := slot }
    }

    // Default version - uses STORAGE_SLOT
    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    // Every function has TWO overloads:
    // 1. Parameterized: takes Storage as first param
    function _isOperator(Storage storage layout, address query) internal view returns (bool) {
        return layout.isOperator[query];
    }

    // 2. Default: calls parameterized with _layout()
    function _isOperator(address query) internal view returns (bool) {
        return _isOperator(_layout(), query);
    }
}
```

### Additional Patterns

**`*Modifiers.sol`** - Abstract contracts with reusable modifiers that delegate to Repo guard functions:
```solidity
abstract contract OperableModifiers {
    modifier onlyOperator() {
        OperableRepo._onlyOperator();  // Repo has _onlyXxx() guard functions
        _;
    }
}
```

**`*Service.sol`** - Stateless library for complex business logic. Uses structs to avoid stack-too-deep:
```solidity
library CamelotV2Service {
    using ConstProdUtils for uint256;
    using SafeERC20 for IERC20;

    struct SwapParams {  // Struct to bundle parameters
        ICamelotV2Router router;
        uint256 amountIn;
        IERC20 tokenIn;
    }

    function _swap(SwapParams memory params) internal { ... }
}
```

**`*AwareRepo.sol`** - Dependency injection for external contract references:
```solidity
library BalancerV3VaultAwareRepo {
    bytes32 internal constant STORAGE_SLOT = keccak256("protocols.dexes.balancer.v3.vault.aware");

    struct Storage {
        IVault balancerV3Vault;
    }

    function _initialize(IVault vault) internal { _layout().balancerV3Vault = vault; }
    function _balancerV3Vault() internal view returns (IVault) { return _layout().balancerV3Vault; }
}
```

### IFacet Interface

All facets implement `IFacet` from `/contracts/interfaces/IFacet.sol`:
```solidity
function facetName() external view returns (string memory name);
function facetInterfaces() external view returns (bytes4[] memory interfaces);
function facetFuncs() external view returns (bytes4[] memory funcs);
function facetMetadata() external view returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions);
```

## Directory Structure

```
contracts/
├── access/           # Access control (operable/, reentrancy/, ERC8023/)
├── factories/        # Diamond and Create3 factories
├── interfaces/       # All contract interfaces
├── introspection/    # ERC165, ERC2535 (Diamond), ERC8109
├── protocols/dexes/  # Protocol integrations
│   ├── aerodrome/v1/
│   ├── balancer/v3/
│   ├── camelot/v2/
│   └── uniswap/v2/
├── test/             # Test utilities, stubs, comparators
├── tokens/           # Token implementations
└── utils/            # Math, collections, cryptography utilities

test/foundry/spec/    # Foundry tests organized by feature
```

### Protocol Integration Structure

Each DEX follows:
```
protocols/dexes/{protocol}/{version}/
├── *AwareRepo.sol   # Dependency injection for router/factory/vault
├── services/        # Business logic libraries
├── stubs/           # Mock implementations for testing
└── test/bases/      # TestBase_*.sol shared test setup
```

## Code Style

Follow the template in `/contracts/StyleGuide.sol`:

### Section Headers
```solidity
/* -------------------------------------------------------------------------- */
/*                             Section Name                                   */
/* -------------------------------------------------------------------------- */
```

Or shorter form:
```solidity
/* ------ Feature Name ------ */
```

### Import Organization
Group imports by source: External libs, Crane interfaces, Crane contracts

### Function Organization
Constructor → Receive → Fallback → External → Public → Internal → Private

### Naming Conventions

| Pattern | Usage | Example |
|---------|-------|---------|
| `_layout()` | Storage access | `_layout()`, `_layout(bytes32 slot)` |
| `_initialize()` | Storage setup | `_initialize(address owner)` |
| `_functionName()` | Internal Repo functions | `_isOperator()`, `_setOperator()` |
| `_onlyXxx()` | Guard functions in Repos | `_onlyOwner()`, `_onlyOperator()` |
| `onlyXxx` | Modifiers | `onlyOwner`, `onlyOperator` |
| `layout` | Storage parameter name | `Storage storage layout` |

### Storage Slot Naming

Use hierarchical dot-notation:
- `"crane.access.operable"` - Crane core features
- `"protocols.dexes.balancer.v3.vault.aware"` - Protocol integrations
- `"eip.erc.8023"` - EIP implementations

## Key Files

- `/contracts/introspection/ERC2535/ERC2535Repo.sol` - Diamond storage management
- `/contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol` - Diamond proxy factory
- `/contracts/access/operable/` - Operator-based access control (complete Facet-Target-Repo example)
- `/contracts/access/ERC8023/` - Two-step ownership transfer (EIP-8023)
- `/contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol` - Service pattern example
- `/contracts/utils/math/ConstProdUtils.sol` - Constant product AMM calculations
- `/contracts/test/CraneTest.sol` - Base test contract for Crane tests

## Testing

- Test files: `*.t.sol` in `test/foundry/spec/`
- Test base classes: `TestBase_*.sol` provide shared setup
- Stubs in `/contracts/test/stubs/` demonstrate patterns (Greeter example)
- Comparators in `/contracts/test/comparators/` for assertion helpers

## Configuration

- Solidity 0.8.30 with viaIR enabled (required for complex tests)
- Optimizer runs: 1 (for contract size limits)
- EVM version: Prague
- Import remappings defined in `foundry.toml`
