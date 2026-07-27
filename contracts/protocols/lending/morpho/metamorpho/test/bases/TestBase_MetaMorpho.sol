// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {TestBase_MorphoBlue} from
    "@crane/contracts/protocols/lending/morpho/blue/test/bases/TestBase_MorphoBlue.sol";
import {IMetaMorphoV1_1} from
    "@crane/contracts/external/morpho/metamorpho-v1.1/interfaces/IMetaMorphoV1_1.sol";
import {MetaMorphoV1_1} from "@crane/contracts/external/morpho/metamorpho-v1.1/MetaMorphoV1_1.sol";
import {MetaMorphoV1_1Factory} from
    "@crane/contracts/external/morpho/metamorpho-v1.1/MetaMorphoV1_1Factory.sol";
import {Id, MarketParams} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";
import {MarketParamsLib} from "@crane/contracts/external/morpho/blue/libraries/MarketParamsLib.sol";

// tag::TestBase_MetaMorpho[]
/**
 * @title TestBase_MetaMorpho
 * @notice Hermetic MetaMorpho V1.1 vault over TestBase_MorphoBlue markets.
 */
abstract contract TestBase_MetaMorpho is TestBase_MorphoBlue {
    using MarketParamsLib for MarketParams;

    MetaMorphoV1_1Factory internal metaMorphoFactory;
    IMetaMorphoV1_1 internal vault;

    address internal CURATOR;
    address internal ALLOCATOR;
    uint256 internal constant VAULT_TIMELOCK = 1 weeks;

    function setUp() public virtual override {
        TestBase_MorphoBlue.setUp();

        CURATOR = makeAddr("CURATOR");
        ALLOCATOR = makeAddr("ALLOCATOR");

        metaMorphoFactory = new MetaMorphoV1_1Factory(address(morpho));
        vm.label(address(metaMorphoFactory), "MetaMorphoV1_1Factory");

        vault = IMetaMorphoV1_1(
            address(
                metaMorphoFactory.createMetaMorpho(
                    OWNER, VAULT_TIMELOCK, address(loanToken), "MetaMorpho Test", "mmTEST", bytes32(uint256(1))
                )
            )
        );
        vm.label(address(vault), "MetaMorphoVault");

        vm.startPrank(OWNER);
        vault.setCurator(CURATOR);
        vault.setIsAllocator(ALLOCATOR, true);
        vm.stopPrank();

        // Enable market with cap via curator + owner accept after timelock=0 path:
        // setCap is curator; for non-zero cap when market already on Morpho.
        vm.prank(CURATOR);
        vault.submitCap(marketParams, type(uint184).max);
        // Timelock is VAULT_TIMELOCK; warp and accept
        vm.warp(block.timestamp + VAULT_TIMELOCK + 1);
        vault.acceptCap(marketParams);

        Id[] memory supplyQueue = new Id[](1);
        supplyQueue[0] = marketId;
        vm.prank(ALLOCATOR);
        vault.setSupplyQueue(supplyQueue);
    }
}
// end::TestBase_MetaMorpho[]
