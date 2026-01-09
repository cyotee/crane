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

## Git Worktree Workflow (git-wt)

This project uses `git-wt` to simplify working with multiple branches simultaneously via git worktrees. Each worktree is an independent working directory with its own branch.

### Commands

```bash
# List all worktrees
git wt

# Create new worktree for a branch (or switch to existing)
git wt <branch-name>

# Delete worktree and branch (with safety checks)
git wt -d <branch-name>

# Force delete worktree and branch
git wt -D <branch-name>
```

### Configuration

Configure via `git config`:

```bash
# Set custom worktree base directory (default: ../{repo}-wt)
git config wt.basedir /path/to/worktrees

# Copy .gitignore-excluded files to new worktrees
git config wt.copyignored true

# Copy untracked files to new worktrees
git config wt.copyuntracked true

# Copy uncommitted changes to new worktrees
git config wt.copymodified true

# Run hook after creating worktree (e.g., install deps)
# NOTE: New worktrees may have uninitialized submodules; initialize them first.
git config wt.hook "git submodule update --init --recursive && forge build"
```

### Recommended Workflow

When working on a feature or fix that requires isolation:

```bash
# Create worktree for feature branch
git wt feature/new-vault-strategy

# If the repo uses submodules, initialize them in the new worktree
git submodule update --init --recursive

# Work in the new worktree directory
# Changes are isolated from main worktree

# When done, delete the worktree
git wt -d feature/new-vault-strategy
```

This is useful for:
- Running long tests in one worktree while developing in another
- Comparing behavior between branches side-by-side
- Isolating experimental changes without stashing

## Librarian (Documentation Search)

Librarian is a local CLI tool that fetches and searches up-to-date developer documentation. Use it to get real context from official docs instead of relying on potentially outdated training data.

### Core Commands

```bash
# Search documentation (hybrid keyword + semantic search)
librarian search --library vercel/next.js "middleware"
librarian search --library openzeppelin/contracts "ERC20"
librarian search --library balancer/docs "swap"

# Search modes
librarian search --library <lib> --mode word "query"    # keyword only
librarian search --library <lib> --mode vector "query"  # semantic only
librarian search --library <lib> --version 5.x "query"  # specific version

# Get full document content
librarian get --library <lib> docs/path/to/file.md
librarian get --library <lib> --doc 69 --slice 19:73    # specific lines

# Find library and list available versions
librarian library "solidity"
librarian library "foundry"
```

### Managing Documentation Sources

```bash
# Add GitHub repo as source
librarian add https://github.com/owner/repo --docs docs --ref main
librarian add https://github.com/foundry-rs/foundry --version 1.x

# Add website documentation
librarian add https://docs.soliditylang.org
librarian add https://docs.balancer.fi --depth 3 --pages 500

# Ingest/update documentation
librarian ingest                    # process all sources
librarian ingest --force            # re-process existing
librarian ingest --embed            # generate semantic embeddings

# Manage sources
librarian source list               # view configured sources
librarian source remove 1           # delete a source
librarian seed                      # add built-in seed libraries
```

### Utility Commands

```bash
librarian detect      # identify project versions in current directory
librarian status      # show document counts and statistics
librarian cleanup     # remove inactive documentation
librarian mcp         # run as MCP server for AI agent integration
```

## NatSpec & Documentation Comment Standard

Crane uses NatSpec + AsciiDoc include-tags to keep docs accurate and extractable.

### AsciiDoc include-tags (required)

When a symbol is documented, wrap it with include-tags so our docs can `include::` exact snippets:

```solidity
// tag::MySymbol[]
// ... code to include in docs ...
// end::MySymbol[]
```

The tag markers must match exactly (no extra spaces inside `[]`).

### Custom NatSpec tags (required where applicable)

- **Functions:**
  - `@custom:signature` canonical signature string, e.g. `transfer(address,uint256)`
  - `@custom:selector` bytes4 selector of the signature
- **Errors:**
  - `@custom:signature` canonical error signature, e.g. `NotOwner(address)`
  - `@custom:selector` bytes4 selector of the error signature
- **Events:**
  - `@custom:signature` canonical event signature, e.g. `OwnershipTransferred(address,address)`
  - `@custom:topic0` bytes32 topic0 hash of the event signature (events do not have bytes4 selectors)
- **ERC-165 interfaces:**
  - `@custom:interfaceid` bytes4 interface id computed as XOR of all function selectors

### How to compute values (use `cast`)

```bash
# Function selector (bytes4)
cast sig "transfer(address,uint256)"

# Error selector (bytes4)
cast sig "NotOwner(address)"

# Event topic0 (bytes32)
cast keccak "OwnershipTransferred(address,address)"
```

For interface ids, prefer verifying with Solidity when possible:

```solidity
type(IMyInterface).interfaceId
```

Or compute manually by XOR-ing all function selectors.

### Tests/handlers (required when referenced)

If a handler/test contract is part of the documented API or referenced in docs, it must also have clear NatSpec and include-tags around the documented symbols.

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

### Test Directory Structure

Test infrastructure lives in `contracts/`, test specs live in `test/`:

```
contracts/                              # Test infrastructure lives WITH the code
├── access/ERC8023/
│   ├── MultiStepOwnableRepo.sol
│   ├── MultiStepOwnableFacet.sol
│   ├── TestBase_IMultiStepOwnable.sol  # TestBase next to implementation
│   └── ...
├── introspection/ERC165/
│   ├── ERC165Facet.sol
│   ├── TestBase_IERC165.sol            # TestBase for behavior testing
│   └── Behavior_IERC165.sol            # Behavior library for validation
├── protocols/dexes/camelot/v2/
│   ├── services/CamelotV2Service.sol
│   └── test/bases/                     # Protocol TestBases in test/bases/
│       └── TestBase_CamelotV2.sol
├── tokens/ERC20/
│   ├── ERC20Facet.sol
│   ├── TestBase_ERC20.sol              # Invariant testing base
│   └── TestBase_ERC20Permit.sol
└── test/
    ├── stubs/                          # Example implementations
    │   └── greeter/
    ├── comparators/                    # Assertion helpers
    └── behaviors/                      # Shared behavior utilities

test/foundry/spec/                      # Actual test specs mirror contracts/
├── access/ERC8023/                     # Mirrors contracts/access/ERC8023/
│   └── MultiStepOwnable.t.sol
├── introspection/ERC165/
│   └── ERC165Facet.t.sol
├── tokens/ERC20/
│   └── ERC20DFPkg_IERC20.t.sol
├── utils/math/constProdUtils/
│   └── ConstProdUtils_*.t.sol
└── protocols/dexes/balancer/v3/
    └── ...
```

**Key Conventions:**
- `TestBase_*.sol` and `Behavior_*.sol` live in `contracts/` alongside the code they test
- Protocol test bases go in `contracts/protocols/.../test/bases/`
- Actual test specs (`*.t.sol`) go in `test/foundry/spec/` mirroring `contracts/` structure
- Stubs, comparators, and shared utilities go in `contracts/test/`

### TestBase Pattern

Two types of TestBase contracts:

**1. Protocol Setup TestBase** - Sets up protocol infrastructure with inheritance chains:
```solidity
// Builds up dependencies via inheritance
abstract contract TestBase_CamelotV2 is TestBase_Weth9 {
    ICamelotFactory internal camelotV2Factory;
    ICamelotV2Router internal camelotV2Router;

    function setUp() public virtual override {
        TestBase_Weth9.setUp();  // Call parent setUp
        if (address(camelotV2Factory) == address(0)) {
            camelotV2Factory = new CamelotFactory(feeToSetter);
        }
        if (address(camelotV2Router) == address(0)) {
            camelotV2Router = new CamelotRouter(address(camelotV2Factory), address(weth));
        }
    }
}
```

**2. Behavior TestBase** - Defines expected behavior via virtual functions:
```solidity
abstract contract TestBase_IFacet is Test {
    IFacet internal testFacet;

    function setUp() public virtual {
        testFacet = facetTestInstance();  // Implemented by inheritor
    }

    // Virtual functions - inheritors return expected values
    function facetTestInstance() public virtual returns (IFacet);
    function controlFacetInterfaces() public view virtual returns (bytes4[] memory);
    function controlFacetFuncs() public view virtual returns (bytes4[] memory);

    // Test functions validate actual vs expected
    function test_IFacet_FacetInterfaces() public {
        assertTrue(Behavior_IFacet.areValid_IFacet_facetInterfaces(
            testFacet, controlFacetInterfaces(), testFacet.facetInterfaces()
        ));
    }
}
```

### Behavior Libraries (`Behavior_*.sol`)

Libraries that encapsulate validation logic for interface compliance testing. Named `Behavior_I{Interface}`:

```solidity
library Behavior_IERC165 {
    using UInt256 for uint256;
    Vm constant vm = Vm(VM_ADDRESS);

    // Behavior name for logging
    function _Behavior_IERC165Name() internal pure returns (string memory) {
        return type(Behavior_IERC165).name;
    }

    // Error message helpers
    function funcSig_IERC165_supportsInterFace() public pure returns (string memory) {
        return "supportsInterFace(bytes4)";
    }

    // expect_* - Store expected values in ComparatorRepo
    function expect_IERC165_supportsInterface(IERC165 subject, bytes4[] memory expectedInterfaces_) public {
        console.logBehaviorEntry(_Behavior_IERC165Name(), "expect_IERC165_supportsInterface");
        Bytes4SetComparatorRepo._recExpectedBytes4(
            address(subject), IERC165.supportsInterface.selector, expectedInterfaces_
        );
        console.logBehaviorExit(_Behavior_IERC165Name(), "expect_IERC165_supportsInterface");
    }

    // isValid_* - Compare expected vs actual directly
    function isValid_IERC165_supportsInterfaces(IERC165 subject, bool expected, bool actual)
        public view returns (bool valid)
    {
        valid = expected == actual;
        if (!valid) {
            console.logBehaviorError(...);
        }
        return valid;
    }

    // hasValid_* - Validate against stored expectations
    function hasValid_IERC165_supportsInterface(IERC165 subject) public view returns (bool isValid_) {
        console.logBehaviorEntry(_Behavior_IERC165Name(), "hasValid_IERC165_supportsInterface");
        // Iterate stored expectations and validate each
        for (uint256 i = 0; i < expectedCount; i++) {
            bytes4 interfaceId = _expected_IERC165_supportsInterface(subject)._index(i);
            isValid_ = isValid_ && subject.supportsInterface(interfaceId);
        }
        console.logBehaviorExit(_Behavior_IERC165Name(), "hasValid_IERC165_supportsInterface");
    }
}
```

**Behavior Function Types:**
| Pattern | Purpose | Example |
|---------|---------|---------|
| `expect_*` | Store expected values | `expect_IERC165_supportsInterface(subject, interfaces)` |
| `isValid_*` / `areValid_*` | Compare expected vs actual directly | `isValid_IERC165_supportsInterfaces(subject, true, actual)` |
| `hasValid_*` | Validate against stored expectations | `hasValid_IERC165_supportsInterface(subject)` |

**Supporting Components:**
- `ComparatorRepo` - Stores expected values keyed by (address, selector)
- `Comparator` - Performs comparison with detailed error output
- `console.logBehavior*` - Structured logging for test debugging

### TestBase Inheritance Chain Example
```
CraneTest                          # Factory setup (create3Factory, diamondFactory)
    └── TestBase_Weth9             # WETH deployment
        └── TestBase_CamelotV2     # Camelot factory + router
            └── TestBase_CamelotV2_Pools  # Pool creation helpers
                └── YourTest.t.sol  # Actual test contract
```

### Declarative Invariant Testing Pattern

For fuzz/invariant testing, use a Handler + TestBase pattern:

**1. Handler** - Wraps Subject Under Test (SUT), exposes fuzzable operations, tracks expected state:
```solidity
contract ERC20TargetStubHandler is Test {
    IERC20 public sut;
    mapping(bytes32 => uint256) internal _expectedAllowance;  // Track expected state

    function transfer(uint256 ownerSeed, uint256 toSeed, uint256 amount) external {
        address owner = addrFromSeed(ownerSeed);  // Normalize fuzz input
        address to = addrFromSeed(toSeed);

        uint256 bal = sut.balanceOf(owner);
        vm.prank(owner);

        if (amount > bal) {
            vm.expectRevert(...);  // Declare expected revert
            sut.transfer(to, amount);
            return;
        }

        vm.expectEmit(true, true, false, true);  // Declare expected event
        emit IERC20.Transfer(owner, to, amount);
        sut.transfer(to, amount);
    }
}
```

**2. TestBase** - Declares invariants and virtual deployment functions:
```solidity
abstract contract TestBase_ERC20 is Test {
    ERC20TargetStubHandler public handler;

    // Virtual function - inheritor provides the SUT
    function _deployToken(ERC20TargetStubHandler handler_) internal virtual returns (IERC20);

    function setUp() public virtual {
        handler = new ERC20TargetStubHandler();
        IERC20 token = _deployToken(handler);
        handler.attachToken(token);

        // Register handler for Foundry invariant fuzzing
        targetContract(address(handler));
        targetSelector(FuzzSelector({
            addr: address(handler),
            selectors: [handler.transfer.selector, handler.approve.selector]
        }));
    }

    // Invariant: totalSupply equals sum of all balances
    function invariant_totalSupply_equals_sumBalances() public view {
        address[] memory addrs = handler.asAddresses();
        uint256 sum = 0;
        for (uint256 i = 0; i < addrs.length; i++) {
            sum += handler.balanceOf(addrs[i]);
        }
        assertEq(sum, handler.totalSupply());
    }

    // Invariant: allowances match expected state tracked by handler
    function invariant_allowances_consistent() public view {
        for (uint256 i = 0; i < handler.pairCount(); i++) {
            (address owner, address spender, uint256 expected) = handler.pairAt(i);
            assertEq(handler.allowance(owner, spender), expected);
        }
    }
}
```

**Key Conventions:**
- Handler normalizes fuzz inputs: `addrFromSeed(seed)` maps to small address set
- Handler tracks expected state: `_expectedAllowance`, `_seen`, etc.
- Invariant functions named `invariant_*` for Foundry discovery
- Use `vm.expectRevert` / `vm.expectEmit` to declare expected behavior
- TestBase declares virtual `_deploy*` functions for SUT injection

### Key Testing Files
- `/contracts/test/CraneTest.sol` - Base with factory infrastructure
- `/contracts/factories/diamondPkg/TestBase_IFacet.sol` - Facet behavior testing
- `/contracts/factories/diamondPkg/Behavior_IFacet.sol` - Facet validation library
- `/contracts/introspection/ERC165/Behavior_IERC165.sol` - ERC165 validation library
- `/contracts/introspection/ERC165/TestBase_IERC165.sol` - ERC165 behavior testing
- `/contracts/test/comparators/Bytes4SetComparator.sol` - Set comparison with error output
- `/contracts/test/behaviors/BehaviorUtils.sol` - Shared behavior utilities
- `/contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol` - Protocol setup example
- `/contracts/tokens/ERC20/TestBase_ERC20.sol` - Declarative invariant testing example

## Configuration

- Solidity 0.8.30 with viaIR enabled (required for complex tests)
- Optimizer runs: 1 (for contract size limits)
- EVM version: Prague
- Import remappings defined in `foundry.toml`
