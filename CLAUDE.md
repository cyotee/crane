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

**`*DFPkg.sol`** - Diamond Factory Package bundles facets into deployable packages:
```solidity
// Interface defines structs for constructor and deployment args
interface IERC20DFPkg {
    struct PkgInit {           // Constructor arguments (immutable facet references)
        IFacet erc20Facet;
    }
    struct PkgArgs {           // Deployment arguments (per-instance config)
        string name;
        string symbol;
        uint8 decimals;
    }
}

contract ERC20DFPkg is IERC20DFPkg, IDiamondFactoryPackage {
    IFacet immutable ERC20_FACET;

    constructor(PkgInit memory pkgInit) {
        ERC20_FACET = pkgInit.erc20Facet;
    }

    function packageName() public pure returns (string memory);
    function facetCuts() public view returns (IDiamond.FacetCut[] memory);
    function diamondConfig() public view returns (DiamondConfig memory);
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32);
    function initAccount(bytes memory initArgs) public;  // Called via delegatecall on proxy
    function postDeploy(address account) public returns (bool);
}
```

**`*FactoryService.sol`** - Libraries that encapsulate CREATE3 deployment logic for related facets and packages:
```solidity
library IntrospectionFacetFactoryService {
    using BetterEfficientHashLib for bytes;
    Vm constant vm = Vm(VM_ADDRESS);

    // Deploy a facet - salt derived from type name
    function deployERC165Facet(
        ICreate3Factory create3Factory
    ) internal returns (IFacet erc165Facet) {
        erc165Facet = create3Factory.deployFacet(
            type(ERC165Facet).creationCode,
            abi.encode(type(ERC165Facet).name)._hash()  // Deterministic salt
        );
        vm.label(address(erc165Facet), type(ERC165Facet).name);  // Label for traces
    }

    // Deploy a package - includes constructor args
    function deployDiamondCutDFPkg(
        ICreate3Factory create3Factory,
        IFacet multiStepOwnableFacet,
        IFacet diamondCutFacet
    ) internal returns (IDiamondCutFacetDFPkg diamondCutDFPkg) {
        diamondCutDFPkg = IDiamondCutFacetDFPkg(address(
            create3Factory.deployPackageWithArgs(
                type(DiamondCutFacetDFPkg).creationCode,
                abi.encode(IDiamondCutFacetDFPkg.PkgInit({
                    diamondCutFacet: diamondCutFacet,
                    multiStepOwnableFacet: multiStepOwnableFacet
                })),
                abi.encode(type(DiamondCutFacetDFPkg).name)._hash()
            )
        ));
        vm.label(address(diamondCutDFPkg), type(DiamondCutFacetDFPkg).name);
    }
}
```

Key conventions for FactoryService libraries:
- Group related deployments (e.g., `AccessFacetFactoryService`, `IntrospectionFacetFactoryService`)
- Salt from type name: `abi.encode(type(X).name)._hash()`
- Always `vm.label()` deployed contracts for debugging
- Use `deployFacet()` for facets, `deployPackageWithArgs()` for packages

### Guard Functions Pattern

Repos contain `_onlyXxx()` guard functions with the actual access control logic. Modifiers are thin wrappers that delegate to these guards:

```solidity
// In Repo - contains the actual check logic
function _onlyOperator(Storage storage layout) internal view {
    if (!_isOperator(layout, msg.sender) && !_isFunctionOperator(layout, msg.sig, msg.sender)) {
        revert IOperable.NotOperator(msg.sender);
    }
}

function _onlyOperator() internal view {
    _onlyOperator(_layout());
}

// In Modifiers - thin delegation wrapper
modifier onlyOperator() {
    OperableRepo._onlyOperator();
    _;
}
```

This pattern centralizes all logic in the Repo and allows guard functions to be called directly from other Repo functions.

## Diamond Package Deployment Pattern

The framework uses a two-factory system for deterministic cross-chain deployments:

### Factory Hierarchy

```
Create3Factory                    # Deploys facets, packages, and any contract
    └── DiamondPackageCallBackFactory   # Deploys Diamond proxy instances from packages
```

### Deployment Flow

**Step 1: Initialize factories** (typically in test `setUp()` or deployment script)
```solidity
(ICreate3Factory factory, IDiamondPackageCallBackFactory diamondFactory) =
    InitDevService.initEnv(address(this));
```

**Step 2: Deploy facets via Create3Factory**
```solidity
IFacet erc20Facet = factory.deployFacet(
    type(ERC20Facet).creationCode,
    abi.encode(type(ERC20Facet).name)._hash()  // Salt from name hash
);
```

**Step 3: Deploy package with facet references**
```solidity
IERC20DFPkg erc20Pkg = IERC20DFPkg(address(
    factory.deployPackageWithArgs(
        type(ERC20DFPkg).creationCode,
        abi.encode(IERC20DFPkg.PkgInit({ erc20Facet: erc20Facet })),  // Constructor args
        abi.encode(type(ERC20DFPkg).name)._hash()  // Salt
    )
));
```

**Step 4: Deploy Diamond proxy instances**
```solidity
// Option A: Via package's deploy() helper
IERC20 token = erc20Pkg.deploy(diamondFactory, "Token", "TKN", 18, 1000e18, recipient, bytes32(0));

// Option B: Via factory directly
address proxy = diamondFactory.deploy(pkg, abi.encode(pkgArgs));
```

### Key Components

| Component | Purpose |
|-----------|---------|
| `Create3Factory` | Deploys any contract with deterministic addresses via CREATE3 |
| `DiamondPackageCallBackFactory` | Deploys Diamond proxies, calls `initAccount()` via delegatecall |
| `IDiamondFactoryPackage` | Interface for packages - bundles facets + initialization logic |
| `InitDevService` | Library to bootstrap the factory system in tests |

### Deployment Sequence Diagram

See `/contracts/interfaces/IDiamondFactoryPackage.sol` for the full ASCII sequence diagram showing:
1. User calls `factory.deploy(pkg, pkgArgs)`
2. Factory calculates deterministic address via `pkg.calcSalt()`
3. Factory deploys `MinimalDiamondCallBackProxy` via CREATE2
4. Proxy calls back to factory's `initAccount()`
5. Factory delegatecalls `pkg.initAccount()` to initialize storage
6. Factory calls `pkg.postDeploy()` for any post-deployment hooks

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

Use import aliases (defined in `foundry.toml` and `remappings.txt`):
- `@crane/` - Crane framework contracts (e.g., `@crane/contracts/access/operable/OperableRepo.sol`)
- `@solady/` - Solady library
- `@openzeppelin/` - OpenZeppelin contracts
- `forge-std/` - Foundry test utilities

### Function Organization
Constructor → Receive → Fallback → External → Public → Internal → Private

### Naming Conventions

| Pattern | Usage | Example |
|---------|-------|---------|
| `_layout()` | Storage access | `_layout()`, `_layout(bytes32 slot_)` |
| `_initialize()` | Storage setup | `_initialize(address owner_)` |
| `_functionName()` | Internal Repo functions | `_isOperator()`, `_setOperator()` |
| `_onlyXxx()` | Guard functions in Repos | `_onlyOwner()`, `_onlyOperator()` |
| `onlyXxx` | Modifiers | `onlyOwner`, `onlyOperator` |
| `layout` | Storage parameter name | `Storage storage layout` |
| `param_` | Function parameters | `owner_`, `slot_`, `name_` |

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
- `/contracts/tokens/ERC20/ERC20DFPkg.sol` - Diamond Factory Package example
- `/contracts/access/AccessFacetFactoryService.sol` - FactoryService pattern example
- `/contracts/introspection/IntrospectionFacetFactoryService.sol` - FactoryService with package deployment
- `/contracts/interfaces/IDiamondFactoryPackage.sol` - DFPkg interface with deployment flow diagram
- `/contracts/InitDevService.sol` - Factory initialization for tests/scripts
- `/contracts/factories/create3/Create3Factory.sol` - CREATE3 factory with facet/package registry

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
