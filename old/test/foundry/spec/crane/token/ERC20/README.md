# BetterERC20 Test Suite

This directory contains unit tests for the BetterERC20 and related contracts.

## Test Structure

- Each test contract inherits from a base test class that performs common setup
- Tests are organized by contract and function being tested
- Naming convention: `<ContractName>_<InterfaceName>_<functionName>Test.sol`
- Tests use view functions where possible to optimize gas usage 
- Tests are structured to test one specific function or behavior

## Base Test Classes

- `BetterERC20TargetTest.sol` - Base test for BetterERC20 tests
- `BetterERC20PermitTargetTest.sol` - Base test for BetterERC20Permit tests 

## Test Stubs

- `BetterERC20TargetStub.sol` - Test stub for BetterERC20 
- `BetterERC20PermitTargetStub.sol` - Test stub for BetterERC20Permit

## Running Tests

Tests can be run using the Foundry test command:

```bash
forge test --match-contract BetterERC20Target
```

To run tests for permit functionality: 

```bash
forge test --match-contract BetterERC20PermitTarget
``` 