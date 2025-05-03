Crane Framework Documentation
Introduction
The Crane Framework is a Solidity development framework designed to simplify the creation of modular and upgradeable smart contracts using the Diamond Proxy pattern. It provides tools and libraries to streamline contract development, including an on-chain package-based factory for deploying new Diamond Proxies. This documentation serves as a comprehensive guide for developers to understand, use, and contribute to the framework.
Key Features

Diamond Proxy Pattern: Enables modular contracts with separate facets for different functionalities.
On-Chain Factory: Facilitates deployment of new Diamond Proxies with pre-configured or custom facets.
Developer Tools: Includes scripts and utilities for testing, deployment, and contract management.

Benefits

Overcomes Solidity's 24KB contract size limit through modularity.
Supports upgradeability without redeploying entire contracts.
Simplifies deployment with an on-chain factory.

Getting Started
Prerequisites

Basic knowledge of Solidity and Ethereum smart contract development.
Familiarity with the Ethereum Virtual Machine (EVM).
Installed tools: Node.js, npm, and a Solidity development environment like Hardhat or Truffle.

Development Environment Setup

Install Node.js and npm: Download and install from Node.js.
Install Hardhat:npm install --global hardhat


Clone the Repository:git clone https://github.com/cyotee/crane.git
cd crane
npm install


Initialize a New Project:npx hardhat init



Concepts
Diamond Proxy Pattern
The Diamond Proxy pattern is a design pattern for creating upgradeable smart contracts. It consists of:

Diamond Contract: A proxy contract that routes function calls to appropriate facets.
Facets: Separate contracts containing specific functionalities.
Storage Layout: Uses patterns like Diamond Storage to manage state variables.

Crane Framework Architecture
The Crane Framework includes:

Diamond Contract: The main contract for routing calls.
Facets: Modular contracts for specific features (e.g., ERC20, ERC721).
On-Chain Factory: A smart contract for deploying new Diamond Proxies.
Development Tools: Scripts for testing, deployment, and package management.

Framework Usage
Creating a New Project

Initialize a new Hardhat project within the Crane repository:npx hardhat init


Configure hardhat.config.js to include Crane Framework dependencies.

Writing Facets
Facets are individual contracts containing specific functionalities. Example:
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

Defining the Diamond Contract
The Diamond contract routes calls to facets. Example setup:
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Diamond.sol";

/// @title CraneDiamond
/// @notice Main Diamond contract for the Crane Framework
contract CraneDiamond is Diamond {
    constructor(address _owner) Diamond(_owner) {}
}

Using the On-Chain Factory
The on-chain factory deploys new Diamond Proxies. Example:
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

Upgrading Contracts
To upgrade a facet:

Deploy a new facet contract.
Update the Diamond contract's facet cut using the diamondCut function.

Development Tools
Testing
Use Hardhat to write and run tests:
npx hardhat test

Deployment
Deploy to a local testnet:
npx hardhat run scripts/deploy.js --network localhost

Best Practices
Secure Coding

Use OpenZeppelin Contracts for battle-tested implementations.
Avoid reentrancy vulnerabilities.

Gas Optimization

Minimize storage operations.
Use efficient data structures.

Versioning

Maintain versioned facets for compatibility.
Document changes in facet upgrades.

Troubleshooting
Common Issues

Deployment Failure: Ensure sufficient gas and correct network configuration.
Facet Not Found: Verify facet addresses in the Diamond contract.

Debugging

Use Hardhat's console.log for debugging.
Check transaction logs for errors.

Contributing
Contribution Guidelines

Follow the Solidity Style Guide.
Use NatSpec comments for all functions and contracts.

Pull Request Process

Fork the repository.
Create a feature branch.
Submit a pull request with detailed descriptions.

Reference
Configuration Options

hardhat.config.js: Network settings, compiler version.
Factory parameters: Owner address, facet configurations.

Appendices
Glossary

Diamond Proxy: A contract that routes calls to facets.
Facet: A contract containing specific functionalities.
On-Chain Factory: A contract for deploying Diamond Proxies.

Additional Resources

Solidity Documentation
EIP-2535: Diamonds
Hardhat Documentation

Community Channels

GitHub Issues

