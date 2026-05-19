---
name: crane-chainlink-local-testing
description: This skill should be used when the user asks to "add Chainlink tests in Crane", "test Chainlink integration in Crane", "use Chainlink Local in Crane", "write CCIP simulator tests", "mock Chainlink data feeds in Crane tests", or needs Crane-specific guidance for Foundry tests using Chainlink Local.
license: MIT
---

# Crane Chainlink Local Testing

Use this skill to integrate Chainlink Local with Crane test architecture and naming conventions.

## Where to Put Tests in Crane

Follow Crane structure:

- Test infrastructure and reusable bases near protocol implementation in contracts/
- Test specs in test/foundry/spec/ mirroring contracts paths

Recommended locations for Chainlink-focused tests:

- contracts/protocols/oracles/chainlink/test/bases/
- test/foundry/spec/protocols/oracles/chainlink/

## Crane-Compatible TestBase Pattern

Create a protocol setup base for Chainlink Local dependencies:

```solidity
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CCIPLocalSimulator} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {IRouterClient, LinkToken, BurnMintERC677Helper} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";

abstract contract TestBase_ChainlinkLocal is Test {
    CCIPLocalSimulator internal chainlinkSim;

    uint64 internal chainSelector;
    IRouterClient internal sourceRouter;
    IRouterClient internal destinationRouter;
    LinkToken internal linkToken;
    BurnMintERC677Helper internal ccipBnM;
    BurnMintERC677Helper internal ccipLnM;

    function setUp() public virtual {
        chainlinkSim = new CCIPLocalSimulator();

        (
            chainSelector,
            sourceRouter,
            destinationRouter,
            ,
            linkToken,
            ccipBnM,
            ccipLnM
        ) = chainlinkSim.configuration();
    }
}
```

Then consume in spec tests:

```solidity
contract ChainlinkIntegration_Test is TestBase_ChainlinkLocal {
    function test_chainlinkLocal_configuration_nonZero() public view {
        assertTrue(address(sourceRouter) != address(0));
        assertTrue(address(destinationRouter) != address(0));
        assertTrue(address(linkToken) != address(0));
    }
}
```

## Forked Chainlink Pattern in Crane

For realistic multi-network scenarios, use CCIPLocalSimulatorFork.

```solidity
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";

abstract contract TestBase_ChainlinkLocalFork is Test {
    CCIPLocalSimulatorFork internal chainlinkForkSim;
    uint256 internal sourceFork;
    uint256 internal destinationFork;

    Register.NetworkDetails internal sourceDetails;
    Register.NetworkDetails internal destinationDetails;

    function setUp() public virtual {
        destinationFork = vm.createSelectFork(vm.envString("ETHEREUM_SEPOLIA_RPC_URL"));
        sourceFork = vm.createFork(vm.envString("ARBITRUM_SEPOLIA_RPC_URL"));

        chainlinkForkSim = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(chainlinkForkSim));

        vm.selectFork(sourceFork);
        sourceDetails = chainlinkForkSim.getNetworkDetails(block.chainid);

        vm.selectFork(destinationFork);
        destinationDetails = chainlinkForkSim.getNetworkDetails(block.chainid);
    }
}
```

## Using Data Feed Mocks in Crane Protocol Tests

For oracle-dependent math and guards, prefer MockV3Aggregator from Chainlink Local in unit tests:

- deterministic answers
- direct updateAnswer and updateRoundData controls
- no external RPC dependency

When testing production-like feed behavior on forks, compare expected ranges rather than exact values.

## Assertion Strategy

For CCIP token transfer flows:

1. Assert sender balance before send.
2. Send message through router.
3. Route message when forked with switchChainAndRouteMessage.
4. Assert sender debited and receiver credited.
5. Assert LINK or native fee path was used as intended.

For feed-driven flows:

1. Assert initial feed answer and decimals.
2. Update answer in mock.
3. Assert strategy/protocol output changed as expected.
4. Assert stale or invalid feed guards where relevant.

## Project Configuration Notes

If tests import @chainlink/local, ensure remappings are present in both:

- remappings.txt
- foundry.toml remappings array

Use the same version source across CI and local environments to avoid version drift in simulator behavior.

## Common Crane-Specific Pitfalls

- Putting reusable setup in test specs instead of TestBase contracts
- Mixing no-fork and fork assumptions in one test without explicit fork selection
- Forgetting vm.makePersistent for simulator in multi-fork tests
- Overcoupling protocol tests to live feed values when a mock test should cover logic first

## Key Reference Files in This Repo

- lib/chainlink-local/README.md
- lib/chainlink-local/src/ccip/CCIPLocalSimulator.sol
- lib/chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol
- lib/chainlink-local/src/data-feeds/MockV3Aggregator.sol
- lib/chainlink-local/src/test/data-feeds/BasicDataConsumerV3.sol

## See Also

- skill:chainlink-local-testing
- skill:crane-testing
- skill:forge-testing
- skill:crane-architecture
