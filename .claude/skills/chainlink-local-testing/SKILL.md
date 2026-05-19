---
name: chainlink-local-testing
description: This skill should be used when the user asks about "Chainlink Local", "test Chainlink locally", "CCIPLocalSimulator", "CCIPLocalSimulatorFork", "MockV3Aggregator", "Chainlink data feed mocks", "Foundry Chainlink tests", or needs guidance on integrating Chainlink services in local or forked tests.
license: MIT
---

# Chainlink Local Testing

Use Chainlink Local when you want deterministic, local-first tests for Chainlink-dependent integrations before running public testnet or mainnet-fork validation.

## What Chainlink Local Gives You

- Local simulation mode with pre-deployed CCIP test contracts
- Forked simulation mode with network detail registry and routing helpers
- Data feed mocks such as MockV3Aggregator and MockOffchainAggregator
- Test helpers for LINK funding and cross-chain message routing in tests

## Foundry Setup

If Chainlink Local is installed with Forge, add this remapping:

```txt
@chainlink/local/=lib/chainlink-local/
```

You can place it in remappings.txt or foundry.toml remappings.

## Core Contracts to Use in Tests

| Purpose | Contract | Path |
|---------|----------|------|
| Local CCIP simulator | CCIPLocalSimulator | @chainlink/local/src/ccip/CCIPLocalSimulator.sol |
| Forked CCIP simulator | CCIPLocalSimulatorFork | @chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol |
| Local data feed mock | MockV3Aggregator | @chainlink/local/src/data-feeds/MockV3Aggregator.sol |
| Advanced feed mock | MockOffchainAggregator | @chainlink/local/src/data-feeds/MockOffchainAggregator.sol |

## Pattern A: Local No-Fork CCIP Tests

Use this for fast unit/integration tests in a single local Anvil state.

```solidity
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CCIPLocalSimulator} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import {IRouterClient, LinkToken, BurnMintERC677Helper} from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";

contract ChainlinkLocalNoForkTest is Test {
    CCIPLocalSimulator internal sim;
    IRouterClient internal router;
    LinkToken internal link;
    BurnMintERC677Helper internal ccipBnM;
    BurnMintERC677Helper internal ccipLnM;

    address internal alice;
    address internal bob;
    uint64 internal destSelector;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        sim = new CCIPLocalSimulator();

        (
            uint64 chainSelector,
            IRouterClient sourceRouter,
            ,
            ,
            LinkToken linkToken,
            BurnMintERC677Helper tokenBnM,
            BurnMintERC677Helper tokenLnM
        ) = sim.configuration();

        destSelector = chainSelector;
        router = sourceRouter;
        link = linkToken;
        ccipBnM = tokenBnM;
        ccipLnM = tokenLnM;
    }
}
```

## Pattern B: Forked CCIP Tests

Use this to test with realistic chain state and route messages across forks.

```solidity
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {CCIPLocalSimulatorFork, Register} from "@chainlink/local/src/ccip/CCIPLocalSimulatorFork.sol";

contract ChainlinkLocalForkTest is Test {
    CCIPLocalSimulatorFork internal simFork;
    uint256 internal sourceFork;
    uint256 internal destinationFork;

    function setUp() public {
        string memory sourceRpc = vm.envString("ARBITRUM_SEPOLIA_RPC_URL");
        string memory destinationRpc = vm.envString("ETHEREUM_SEPOLIA_RPC_URL");

        destinationFork = vm.createSelectFork(destinationRpc);
        sourceFork = vm.createFork(sourceRpc);

        simFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(simFork));

        vm.selectFork(sourceFork);
        Register.NetworkDetails memory source = simFork.getNetworkDetails(block.chainid);
        assertTrue(source.routerAddress != address(0));
    }
}
```

In forked tests, use simFork.switchChainAndRouteMessage(destinationFork) after ccipSend to emulate delivery on the destination fork.

## Pattern C: Data Feed Mock Tests

Use mock feeds for price-driven logic without CCIP dependencies.

```solidity
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockV3Aggregator} from "@chainlink/local/src/data-feeds/MockV3Aggregator.sol";

contract DataFeedMockTest is Test {
    MockV3Aggregator internal feed;

    function setUp() public {
        feed = new MockV3Aggregator(8, 2000e8);
    }

    function test_priceUpdate() public {
        (, int256 answer,,,) = feed.latestRoundData();
        assertEq(answer, 2000e8);

        feed.updateAnswer(2100e8);
        (, int256 next,,,) = feed.latestRoundData();
        assertEq(next, 2100e8);
    }
}
```

## Test Design Checklist

1. Pick mode early: no-fork for speed, fork for realism.
2. Keep simulator instances in test setup, not production code paths.
3. For fork tests, persist simulator contracts with vm.makePersistent.
4. Use requestLinkFromFaucet for LINK-fee test scenarios.
5. Validate fee mode explicitly: LINK token vs native (feeToken address(0)).
6. Assert both sender debits and receiver credits around routed operations.

## Common Mistakes

- Forgetting @chainlink/local remapping after installation
- Not calling vm.makePersistent in forked mode
- Using chain selector where chain id is required (and vice versa)
- Skipping route step in forked CCIP tests
- Treating mock feed decimals as 18 when the mock is configured for 8

## Useful Docs

- https://docs.chain.link/chainlink-local
- https://docs.chain.link/chainlink-local/build/ccip/foundry/local-simulator
- https://docs.chain.link/chainlink-local/build/ccip/foundry/local-simulator-fork
- https://docs.chain.link/chainlink-local/llms-full.txt

## See Also

- skill:crane-chainlink-local-testing
- skill:forge-testing
- skill:crane-testing
- skill:chainlink-vrf-architecture
