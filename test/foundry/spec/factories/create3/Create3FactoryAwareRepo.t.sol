// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {Create3FactoryAwareRepo} from "@crane/contracts/factories/create3/Create3FactoryAwareRepo.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";

/**
 * @title Create3FactoryAwareHarness
 * @notice Exposes Create3FactoryAwareRepo library functions for testing.
 */
contract Create3FactoryAwareHarness {
    function initialize(ICreate3Factory factory_) external {
        Create3FactoryAwareRepo._initialize(factory_);
    }

    function initializeWithSlot(bytes32 slot, ICreate3Factory factory_) external {
        Create3FactoryAwareRepo._initialize(Create3FactoryAwareRepo._layout(slot), factory_);
    }

    function create3Factory() external view returns (ICreate3Factory) {
        return Create3FactoryAwareRepo._create3Factory();
    }

    function create3FactoryFromSlot(bytes32 slot) external view returns (ICreate3Factory) {
        return Create3FactoryAwareRepo._create3Factory(Create3FactoryAwareRepo._layout(slot));
    }

    function storageSlot() external pure returns (bytes32) {
        return Create3FactoryAwareRepo.STORAGE_SLOT;
    }
}

/**
 * @title Create3FactoryAwareRepo_Test
 * @notice Tests for Create3FactoryAwareRepo library.
 */
contract Create3FactoryAwareRepo_Test is Test {
    Create3FactoryAwareHarness internal harness;
    ICreate3Factory internal mockFactory;

    function setUp() public {
        harness = new Create3FactoryAwareHarness();
        mockFactory = ICreate3Factory(address(0xC3F4));
    }

    function test_storageSlot_isCorrectHash() public view {
        bytes32 expected = keccak256("crane.create3.factory.aware");
        assertEq(harness.storageSlot(), expected, "Storage slot should match expected hash");
    }

    function test_initialize_storesFactory() public {
        harness.initialize(mockFactory);
        assertEq(address(harness.create3Factory()), address(mockFactory), "Factory should be stored");
    }

    function test_initialize_canOverwrite() public {
        ICreate3Factory factory1 = ICreate3Factory(address(0x1111));
        ICreate3Factory factory2 = ICreate3Factory(address(0x2222));

        harness.initialize(factory1);
        harness.initialize(factory2);
        assertEq(address(harness.create3Factory()), address(factory2), "Factory should be overwritten");
    }

    function test_initializeWithSlot_storesAtCustomSlot() public {
        bytes32 customSlot = keccak256("custom.create3.slot");

        harness.initializeWithSlot(customSlot, mockFactory);

        assertEq(address(harness.create3Factory()), address(0), "Default slot should be empty");
        assertEq(
            address(harness.create3FactoryFromSlot(customSlot)),
            address(mockFactory),
            "Custom slot should have factory"
        );
    }

    function test_slotIsolation_differentSlotsAreIndependent() public {
        bytes32 slot1 = keccak256("c3.slot1");
        bytes32 slot2 = keccak256("c3.slot2");
        ICreate3Factory factory1 = ICreate3Factory(address(0x1111));
        ICreate3Factory factory2 = ICreate3Factory(address(0x2222));

        harness.initializeWithSlot(slot1, factory1);
        harness.initializeWithSlot(slot2, factory2);

        assertEq(address(harness.create3FactoryFromSlot(slot1)), address(factory1));
        assertEq(address(harness.create3FactoryFromSlot(slot2)), address(factory2));
    }

    function test_create3Factory_returnsZeroBeforeInit() public view {
        assertEq(address(harness.create3Factory()), address(0), "Should return zero before init");
    }

    function testFuzz_initialize_anyAddress(address factoryAddr) public {
        vm.assume(factoryAddr != address(0));
        harness.initialize(ICreate3Factory(factoryAddr));
        assertEq(address(harness.create3Factory()), factoryAddr);
    }
}
