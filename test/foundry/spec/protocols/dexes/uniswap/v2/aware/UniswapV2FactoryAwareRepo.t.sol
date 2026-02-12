// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {UniswapV2FactoryAwareRepo} from "@crane/contracts/protocols/dexes/uniswap/v2/aware/UniswapV2FactoryAwareRepo.sol";
import {IUniswapV2Factory} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";

/**
 * @title UniswapV2FactoryAwareHarness
 * @notice Exposes UniswapV2FactoryAwareRepo library functions for testing.
 */
contract UniswapV2FactoryAwareHarness {
    function initialize(IUniswapV2Factory factory_) external {
        UniswapV2FactoryAwareRepo._initialize(factory_);
    }

    function initializeWithSlot(bytes32 slot, IUniswapV2Factory factory_) external {
        UniswapV2FactoryAwareRepo._initialize(UniswapV2FactoryAwareRepo._layout(slot), factory_);
    }

    function uniswapV2Factory() external view returns (IUniswapV2Factory) {
        return UniswapV2FactoryAwareRepo._uniswapV2Factory();
    }

    function uniswapV2FactoryFromSlot(bytes32 slot) external view returns (IUniswapV2Factory) {
        return UniswapV2FactoryAwareRepo._uniswapV2Factory(UniswapV2FactoryAwareRepo._layout(slot));
    }

    function storageSlot() external pure returns (bytes32) {
        return UniswapV2FactoryAwareRepo.STORAGE_SLOT;
    }
}

/**
 * @title UniswapV2FactoryAwareRepo_Test
 * @notice Tests for UniswapV2FactoryAwareRepo library.
 */
contract UniswapV2FactoryAwareRepo_Test is Test {
    UniswapV2FactoryAwareHarness internal harness;
    IUniswapV2Factory internal mockFactory;

    function setUp() public {
        harness = new UniswapV2FactoryAwareHarness();
        mockFactory = IUniswapV2Factory(address(0x1234));
    }

    function test_storageSlot_isCorrectHash() public view {
        bytes32 expected = keccak256("crane.uniswap.v2.factory.aware");
        assertEq(harness.storageSlot(), expected, "Storage slot should match expected hash");
    }

    function test_initialize_storesFactory() public {
        harness.initialize(mockFactory);
        assertEq(address(harness.uniswapV2Factory()), address(mockFactory), "Factory should be stored");
    }

    function test_initialize_canOverwrite() public {
        IUniswapV2Factory factory1 = IUniswapV2Factory(address(0x1111));
        IUniswapV2Factory factory2 = IUniswapV2Factory(address(0x2222));

        harness.initialize(factory1);
        assertEq(address(harness.uniswapV2Factory()), address(factory1));

        harness.initialize(factory2);
        assertEq(address(harness.uniswapV2Factory()), address(factory2), "Factory should be overwritten");
    }

    function test_initializeWithSlot_storesAtCustomSlot() public {
        bytes32 customSlot = keccak256("custom.slot");

        harness.initializeWithSlot(customSlot, mockFactory);

        assertEq(address(harness.uniswapV2Factory()), address(0), "Default slot should be empty");
        assertEq(
            address(harness.uniswapV2FactoryFromSlot(customSlot)),
            address(mockFactory),
            "Custom slot should have factory"
        );
    }

    function test_slotIsolation_differentSlotsAreIndependent() public {
        bytes32 slot1 = keccak256("slot1");
        bytes32 slot2 = keccak256("slot2");
        IUniswapV2Factory factory1 = IUniswapV2Factory(address(0x1111));
        IUniswapV2Factory factory2 = IUniswapV2Factory(address(0x2222));

        harness.initializeWithSlot(slot1, factory1);
        harness.initializeWithSlot(slot2, factory2);

        assertEq(address(harness.uniswapV2FactoryFromSlot(slot1)), address(factory1));
        assertEq(address(harness.uniswapV2FactoryFromSlot(slot2)), address(factory2));
    }

    function test_uniswapV2Factory_returnsZeroBeforeInit() public view {
        assertEq(address(harness.uniswapV2Factory()), address(0), "Should return zero before init");
    }

    function testFuzz_initialize_anyAddress(address factoryAddr) public {
        vm.assume(factoryAddr != address(0));
        harness.initialize(IUniswapV2Factory(factoryAddr));
        assertEq(address(harness.uniswapV2Factory()), factoryAddr);
    }
}
