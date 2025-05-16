# Crane Framework Documentation

## Introduction

The Crane Framework is a Solidity development framework designed to simplify the creation of modular and upgradeable smart contracts using the Diamond Proxy pattern (EIP-2535). It provides tools and libraries to streamline contract development, including an on-chain package-based factory for deploying new Diamond Proxies. This documentation serves as a comprehensive guide for developers to understand, use, and contribute to the framework.

## Key Features

- **Diamond Proxy Pattern**: Enables modular contracts with separate facets for different functionalities.
- **On-Chain Factory**: Facilitates deployment of new Diamond Proxies with pre-configured or custom facets.
- **Developer Tools**: Includes scripts and utilities for testing, deployment, and contract management.
- **Behavior Testing Pattern**: Provides robust testing utilities for validating contract interfaces and functionality.

## Benefits

- Overcomes Solidity's 24KB contract size limit through modularity.
- Supports upgradeability without redeploying entire contracts.
- Simplifies deployment with an on-chain factory.
- Ensures consistent implementation through behavior-based testing.

## Getting Started

### Prerequisites

- Basic knowledge of Solidity and Ethereum smart contract development.
- Familiarity with the Ethereum Virtual Machine (EVM).
- Installed tools: Node.js, npm, and a Solidity development environment like Hardhat or Foundry.

### Development Environment Setup

1. **Install Node.js and npm**: Download and install from [Node.js](https://nodejs.org/).

2. **Install Hardhat**:

   ```bash
   npm install --global hardhat
   ```

3. **Clone the Repository**:

   ```bash
   git clone https://github.com/cyotee/crane.git
   cd crane
   npm install
   ```

4. **Initialize a New Project**:

   ```bash
   npx hardhat init
   ```

## Concepts

### Diamond Proxy Pattern

The Diamond Proxy pattern is a design pattern for creating upgradeable smart contracts. It consists of:

- **Diamond Contract**: A proxy contract that routes function calls to appropriate facets.
- **Facets**: Separate contracts containing specific functionalities.
- **Storage Layout**: Uses patterns like Diamond Storage to manage state variables.

### Crane Framework Architecture

The Crane Framework includes:

- **Diamond Contract**: The main contract for routing calls.
- **Facets**: Modular contracts for specific features (e.g., ERC20, ERC721).
- **On-Chain Factory**: A smart contract for deploying new Diamond Proxies.
- **Development Tools**: Scripts for testing, deployment, and package management.
- **Behavior Contracts**: Reusable testing components for validating interface compliance.

## Framework Usage

### Creating a New Project

1. Initialize a new Hardhat project within the Crane repository:

   ```bash
   npx hardhat init
   ```

2. Configure hardhat.config.js to include Crane Framework dependencies.

### Writing Facets

Facets are individual contracts containing specific functionalities. Example:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ExampleFacet
/// @notice A facet for managing a simple counter
contract ExampleFacet {
    /// @notice Increments the counter
    function increment() external {
        // Implementation
    }
}
```

### Defining the Diamond Contract

The Diamond contract routes calls to facets. Example setup:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Diamond.sol";

/// @title CraneDiamond
/// @notice Main Diamond contract for the Crane Framework
contract CraneDiamond is Diamond {
    constructor(address _owner) Diamond(_owner) {}
}
```

### Using the On-Chain Factory

The on-chain factory deploys new Diamond Proxies. Example:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CraneFactory
/// @notice Factory for deploying Diamond Proxies
contract CraneFactory {
    /// @notice Deploys a new Diamond Proxy
    function deployDiamond(address _owner) external returns (address) {
        // Implementation
    }
}
```

### Factory Packages

Crane provides a package-based approach to facet deployment:

1. **Diamond Factory Packages (DFPkg)**: Pre-configured bundles of facets for common use cases
2. **Custom Packages**: Create your own packages for specific application needs

#### Factory Package Composition

Packages are designed to compose facets efficiently and promote reuse:

- **Base Packages**: Provide core functionality (e.g., ERC20Permit)
- **Extension Packages**: Extend base functionality by including base facets and adding additional features

For example, the ERC4626 package would include:

- ERC20 Facet (which includes ERC20Permit functionality)
- ERC4626 Facet (which adds vault functionality)

This composition allows reuse of the ERC20 facet without duplicating code.

### Upgrading Contracts

To upgrade a facet:

1. Deploy a new facet contract.
2. Update the Diamond contract's facet cut using the diamondCut function.

## Implementation Architecture

### Contract Hierarchy

Crane follows a hierarchical structure for implementation:

1. **Interfaces**: Define the contract APIs
2. **Storage**: Manage contract state
3. **Targets**: Implement core functionality
4. **Facets**: Expose functionality to Diamond Proxies
5. **Packages**: Combine facets for deployment

### Diamond Storage Pattern & Repo Libraries

The Crane Framework implements a robust storage pattern for Diamond contracts using specialized "Repo" libraries. This pattern prevents storage collisions in upgradeable contracts and provides a clean, consistent approach to state management.

#### Diamond Storage Components

1. **Layout Structs**: Define storage structure for each contract

   ```solidity
   struct GreeterLayout {
       string message;
   }
   ```

2. **Repo Libraries**: Provide storage slot binding functions

   ```solidity
   library GreeterRepo {
       function _layout(bytes32 slot_) internal pure returns(GreeterLayout storage layout_) {
           assembly{layout_.slot := slot_}
       }
   }
   ```

3. **Storage Contracts**: Implement the Diamond Storage pattern

   ```solidity
   contract GreeterStorage {
       using GreeterRepo for bytes32;
       
       bytes32 private constant LAYOUT_ID = keccak256(type(GreeterRepo).creationCode);
       bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
       bytes32 private constant STORAGE_RANGE = type(IGreeter).interfaceId;
       bytes32 private constant STORAGE_SLOT = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));
       
       function _greeter() internal pure virtual returns(GreeterLayout storage) {
           return STORAGE_SLOT._layout();
       }
   }
   ```

#### How It Works

1. **Unique Storage Slot Calculation**:
   - Each contract component gets a unique storage slot based on:
     - The Repo library type name (LAYOUT_ID)
     - The interface ID it implements (STORAGE_RANGE)
   - This creates collision-resistant storage namespaces

2. **Storage Access Pattern**:
   - Storage contracts provide accessor methods (e.g., `_greeter()`)
   - These methods use the Repo library to bind the layout struct to the correct storage slot
   - Target and Facet contracts inherit from Storage contracts to access state variables

3. **Initialization Methods**:
   - Storage contracts typically provide `_init*` methods to set initial state
   - These methods are called during Diamond initialization or facet cuts

#### Diamond Storage Benefits

- **Storage Safety**: Prevents collisions between different facets
- **Consistent Pattern**: Standardized approach across all components
- **Upgradeable**: Supports contract upgrades without state corruption
- **Composable**: Enables easy composition of multiple storage contracts

This pattern is used throughout the Crane framework, from core components like Diamond storage to specific implementations like ERC20, ERC2612, and other specialized contracts.

### Extension Pattern

For extending functionality (like ERC4626 extending ERC20):

1. Base functionality is implemented in its own Target
2. Extensions inherit from these Targets
3. Each extension has its own Facet
4. Packages compose these Facets together

For example:

```solidity
// ERC20Target implements ERC20 functionality
contract ERC20Target is ERC20Storage { /* ... */ }

// ERC4626Target extends ERC20 functionality
contract ERC4626Target is ERC20Target, ERC4626Storage { /* ... */ }

// Separate facets expose specific functionality
contract ERC20Facet is ERC20Target, IFacet { /* ... */ }
contract ERC4626Facet is ERC4626Target, IFacet { /* ... */ }

// Package combines facets
contract ERC4626Package is IDiamondFactoryPackage {
    function facetCuts() public view returns(IDiamond.FacetCut[] memory) {
        // Include both ERC20Facet and ERC4626Facet
    }
}
```

## Testing Framework

### Behavior Testing Pattern

Crane implements a powerful behavior-based testing pattern to validate contract interfaces and functionality:

#### Key Components

- **Base Behavior Contract**: Provides common utilities for error formatting and subject tracking
- **Interface-Specific Behaviors**: Specialized behaviors for validating specific interfaces
- **Testing Workflow Functions**:
  - `expect_X`: Sets the expected behavior for a subject
  - `isValid_X`: Validates a specific aspect against expectations
  - `hasValid_X`: Performs complete validation of a subject's compliance

#### Usage Patterns

1. **Direct Matcher Approach (Preferred)**

   ```solidity
   assertTrue(
       isValid_IFacet_facetInterfaces(
           facet,
           expectedInterfaces,
           facet.facetInterfaces()
       ),
       "Facet should expose the correct interface IDs"
   );
   ```

2. **Expectation Declaration Pattern (Complex Scenarios)**

   ```solidity
   // Record expectation
   expect_IFacet_facetInterfaces(subject, expectedInterfaces);
   
   // Test action
   performAction();
   
   // Verify expectations
   assertTrue(hasValid_IFacet_facetInterfaces(subject), 
       "State should match expectations after action");
   ```

### Testing Architecture

Crane uses a hierarchical stub approach for testing:

#### Stub Inheritance

Test stubs inherit the target implementation, making them easy to deploy and test:

```solidity
// For testing ERC20
contract ERC20Stub is ERC20Target {
    constructor(address owner) { /* initialization */ }
}

// For testing ERC4626
contract ERC4626Stub is ERC4626Target {
    constructor(address owner) { /* initialization */ }
}
```

#### Multi-level Testing Strategy

For testing:

1. **Unit Testing**: Use stubs that inherit from Targets to test core functionality
2. **Integration Testing**: Use facets to test diamond integration
3. **Package Testing**: Test complete package deployments

For example, when testing ERC4626:

- Unit test with a stub that inherits from ERC4626Target
- Integration test with the ERC4626Facet
- Deploy and test the full ERC4626 Package that composes both ERC20 and ERC4626 facets

#### Library Testing Strategy

For testing libraries with Foundry, a more direct approach is preferred:

1. **Direct Library Testing**: Test libraries without requiring stubs

   ```solidity
   // Example of direct library testing
   contract ExampleLibraryTest is Test {
       function testLibraryFunction() public {
           // Call library function directly with explicit library name
           uint result = ExampleLibrary.calculate(100);
           assertEq(result, 200);
       }
   }
   ```

2. **Explicit Library References**: Avoid using declarations and instead reference the library explicitly

   ```solidity
   // Prefer this approach
   MyLibrary.someFunction(x, y);
   
   // Instead of this approach
   using MyLibrary for uint256;
   x.someFunction(y);
   ```

3. **Coverage Considerations**: When testing mathematical functions:
   - Focus on boundary cases and edge conditions
   - Test practical usage scenarios rather than trying to reimplement the math
   - Use different calculation paths to verify results when possible
   - Document cases where alternative calculation methods aren't feasible

This approach improves test clarity, simplifies implementation, and makes it easier to understand which library functions are being tested.

#### Fixture Pattern for Test Environment Setup

Crane implements a sophisticated Fixture pattern to streamline test setup and maintain consistent deployment configurations:

1. **Purpose of Fixtures**:
   - Encapsulate contract deployment logic and configuration
   - Provide cached instances of common contracts
   - Manage cross-chain and environment-specific deployments
   - Simplify complex test setup with reusable components
   - Track and label deployed contracts for debugging

2. **Core Fixture Components**:

   ```solidity
   contract Fixture {
       // Register deployed instances by chain ID and contract type
       function registerInstance(uint256 chainid, bytes32 initCodeHash, address target) public;
       
       // Retrieve instances by chain ID and contract type
       function chainInstance(uint256 chainid, bytes32 initCodeHash) public view returns (address);
       
       // Declaration helpers for tracking deployed contracts
       function declare(string memory builderKey, string memory label, address subject) public;
   }
   ```

3. **CraneFixture Implementation**:

   ```solidity
   contract CraneFixture is Fixture {
       // Provides access to core framework contracts
       function factory() public returns (Create2CallBackFactoryTarget);
       function diamondFactory() public returns (IDiamondPackageCallBackFactory);
       function ownableFacet() public returns (OwnableFacet);
       // ... other framework contracts
   }
   ```

4. **Using Fixtures in Tests**:

   ```solidity
   contract MyTest is CraneTest {
       function setUp() public {
           // CraneTest inherits CraneFixture, providing access to all framework contracts
           address myToken = erc20MintBurnPkg().deployERC20(...);
           
           // Fixtures handle caching to avoid redundant deployments
           assert(address(ownableFacet()) != address(0));
       }
   }
   ```

5. **Benefits of the Fixture Pattern**:
   - **Deployment Efficiency**: Contracts are deployed once and cached
   - **Cross-Environment Support**: Handles different networks automatically
   - **Simplified Test Setup**: Complex deployment logic is abstracted away
   - **Consistent Configuration**: Ensures tests use the same contract instances
   - **Better Debugging**: Deployed contracts are labeled and tracked
   - **Reduced Test Code**: Avoids repetitive deployment logic in multiple tests

This pattern is especially valuable for testing diamond proxy implementations, as it manages the complexity of deploying multiple facets and packages while providing a clean interface for tests to access the necessary components.

#### Standard Conventions

- ERC20 functionality always includes ERC20Permit
- Stubs inherit from the most specific Target that provides required functionality
- Packages reuse existing facets rather than duplicating functionality

## Development Tools

### Testing Tools

Use Hardhat or Foundry to write and run tests:

```bash
# Hardhat
npx hardhat test

# Foundry
forge test
```

### Deployment

Deploy to a local testnet:

```bash
npx hardhat run scripts/deploy.js --network localhost
```

## Best Practices

### Secure Coding

- Use OpenZeppelin Contracts for battle-tested implementations.
- Avoid reentrancy vulnerabilities.
- Follow the storage pattern to prevent storage collisions.

### Gas Optimization

- Minimize storage operations.
- Use efficient data structures.
- Consider facet grouping for commonly used functions.

### Versioning

- Maintain versioned facets for compatibility.
- Document changes in facet upgrades.
- Use semantic versioning for packages.

### Testing

- Use behavior contracts to validate interface compliance.
- Prefer direct matcher approach for simple test cases.
- Use expectation declaration for complex test scenarios.

## Troubleshooting

### Common Issues

- **Deployment Failure**: Ensure sufficient gas and correct network configuration.
- **Facet Not Found**: Verify facet addresses in the Diamond contract.
- **Storage Collisions**: Check storage layout and ensure proper namespacing.

### Debugging

- Use Hardhat's console.log for debugging.
- Check transaction logs for errors.
- Leverage behavior testing for detailed error reporting.

## Contributing

### Contribution Guidelines

- Follow the Solidity Style Guide.
- Use NatSpec comments for all functions and contracts.
- Add behavior tests for new interfaces.

### Pull Request Process

1. Fork the repository.
2. Create a feature branch.
3. Submit a pull request with detailed descriptions.

## Reference

### Configuration Options

- hardhat.config.js: Network settings, compiler version.
- Factory parameters: Owner address, facet configurations.

## Appendices

### Glossary

- **Diamond Proxy**: A contract that routes calls to facets.
- **Facet**: A contract containing specific functionalities.
- **On-Chain Factory**: A contract for deploying Diamond Proxies.
- **Behavior**: A testing contract that validates interface compliance.
- **Diamond Factory Package (DFPkg)**: A pre-configured bundle of facets.
- **Target**: Contract implementing core functionality without exposing it as a facet.
- **Stub**: Testing contract that inherits from a Target for unit testing.

### Additional Resources

- [Solidity Documentation](https://docs.soliditylang.org/)
- [EIP-2535: Diamonds](https://eips.ethereum.org/EIPS/eip-2535)
- [Hardhat Documentation](https://hardhat.org/getting-started/)
- [Foundry Documentation](https://book.getfoundry.sh/)

### Community Channels

- GitHub Issues

