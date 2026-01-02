// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {DiamondPackageCallBackFactoryAwareRepo, DiamondPackageCallBackFactoryAwareLayout} from "@crane/contracts/factories/diamondPkg/DiamondPackageCallBackFactoryAwareRepo.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

/**
 * @title DiamondPackageCallBackFactoryAwareHarness
 * @notice Exposes DiamondPackageCallBackFactoryAwareRepo library functions for testing.
 */
contract DiamondPackageCallBackFactoryAwareHarness {
    function initialize(IDiamondPackageCallBackFactory factory_) external {
        DiamondPackageCallBackFactoryAwareRepo._initialize(factory_);
    }

    function initializeWithSlot(bytes32 slot, IDiamondPackageCallBackFactory factory_) external {
        DiamondPackageCallBackFactoryAwareRepo._initialize(
            DiamondPackageCallBackFactoryAwareRepo._layout(slot),
            factory_
        );
    }

    function diamondPackageCallBackFactory() external view returns (IDiamondPackageCallBackFactory) {
        return DiamondPackageCallBackFactoryAwareRepo._diamondPackageCallBackFactory();
    }

    function diamondPackageCallBackFactoryFromSlot(bytes32 slot)
        external
        view
        returns (IDiamondPackageCallBackFactory)
    {
        return DiamondPackageCallBackFactoryAwareRepo._diamondPackageCallBackFactory(
            DiamondPackageCallBackFactoryAwareRepo._layout(slot)
        );
    }

    function storageSlot() external pure returns (bytes32) {
        return DiamondPackageCallBackFactoryAwareRepo.STORAGE_SLOT;
    }
}

/**
 * @title DiamondPackageCallBackFactoryAwareRepo_Test
 * @notice Tests for DiamondPackageCallBackFactoryAwareRepo library.
 */
contract DiamondPackageCallBackFactoryAwareRepo_Test is Test {
    DiamondPackageCallBackFactoryAwareHarness internal harness;
    IDiamondPackageCallBackFactory internal mockFactory;

    function setUp() public {
        harness = new DiamondPackageCallBackFactoryAwareHarness();
        mockFactory = IDiamondPackageCallBackFactory(address(0xD1A4));
    }

    function test_storageSlot_isCorrectHash() public view {
        bytes32 expected = keccak256("crane.diamond.package.callback.factory.aware");
        assertEq(harness.storageSlot(), expected, "Storage slot should match expected hash");
    }

    function test_initialize_storesFactory() public {
        harness.initialize(mockFactory);
        assertEq(
            address(harness.diamondPackageCallBackFactory()),
            address(mockFactory),
            "Factory should be stored"
        );
    }

    function test_initialize_canOverwrite() public {
        IDiamondPackageCallBackFactory factory1 = IDiamondPackageCallBackFactory(address(0x1111));
        IDiamondPackageCallBackFactory factory2 = IDiamondPackageCallBackFactory(address(0x2222));

        harness.initialize(factory1);
        harness.initialize(factory2);
        assertEq(
            address(harness.diamondPackageCallBackFactory()),
            address(factory2),
            "Factory should be overwritten"
        );
    }

    function test_initializeWithSlot_storesAtCustomSlot() public {
        bytes32 customSlot = keccak256("custom.diamond.slot");

        harness.initializeWithSlot(customSlot, mockFactory);

        assertEq(address(harness.diamondPackageCallBackFactory()), address(0), "Default slot should be empty");
        assertEq(
            address(harness.diamondPackageCallBackFactoryFromSlot(customSlot)),
            address(mockFactory),
            "Custom slot should have factory"
        );
    }

    function test_slotIsolation_differentSlotsAreIndependent() public {
        bytes32 slot1 = keccak256("diamond.slot1");
        bytes32 slot2 = keccak256("diamond.slot2");
        IDiamondPackageCallBackFactory factory1 = IDiamondPackageCallBackFactory(address(0x1111));
        IDiamondPackageCallBackFactory factory2 = IDiamondPackageCallBackFactory(address(0x2222));

        harness.initializeWithSlot(slot1, factory1);
        harness.initializeWithSlot(slot2, factory2);

        assertEq(address(harness.diamondPackageCallBackFactoryFromSlot(slot1)), address(factory1));
        assertEq(address(harness.diamondPackageCallBackFactoryFromSlot(slot2)), address(factory2));
    }

    function test_diamondPackageCallBackFactory_returnsZeroBeforeInit() public view {
        assertEq(
            address(harness.diamondPackageCallBackFactory()),
            address(0),
            "Should return zero before init"
        );
    }

    function testFuzz_initialize_anyAddress(address factoryAddr) public {
        vm.assume(factoryAddr != address(0));
        harness.initialize(IDiamondPackageCallBackFactory(factoryAddr));
        assertEq(address(harness.diamondPackageCallBackFactory()), factoryAddr);
    }
}
