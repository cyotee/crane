// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/utils/collections/BetterArrays.sol";

contract BetterArraysCaller {
    function isValidIndex(uint256 length, uint256 index) external pure returns (bool) {
        return BetterArrays._isValidIndex(length, index);
    }

    function toLengthFixed10(uint256 newLen) external pure returns (address[] memory) {
        address[10] memory contracts;
        for (uint256 i = 0; i < 10; i++) {
            contracts[i] = address(uint160(i + 1));
        }
        return BetterArrays._toLength(contracts, newLen);
    }

    function toLengthFixed100(uint256 newLen) external pure returns (address[] memory) {
        address[100] memory contracts;
        for (uint256 i = 0; i < 100; i++) {
            contracts[i] = address(uint160(i + 1));
        }
        return BetterArrays._toLength(contracts, newLen);
    }

    function toLengthFixed1000(uint256 newLen) external pure returns (address[] memory) {
        address[1000] memory contracts;
        for (uint256 i = 0; i < 1000; i++) {
            contracts[i] = address(uint160(i + 1));
        }
        return BetterArrays._toLength(contracts, newLen);
    }
}

contract BetterArraysTest is Test {
    using BetterArrays for uint256[];
    using BetterArrays for address[];
    using BetterArrays for bytes32[];

    // 1. _isValidIndex success
    function test_isValidIndex_valid(uint256 length, uint256 index) public pure {
        // limit ranges to avoid vm.bound overflow in fuzzing — use modulo to keep values small
        length = (length % 256) + 1; // length in [1,256]
        // index in [0, length-1]
        index = index % length;
        bool ok = BetterArrays._isValidIndex(length, index);
        assertTrue(ok);
    }

    // 2. _isValidIndex revert when index is out of bounds
    function test_isValidIndex_revert(uint256 length, uint256 index) public {
        // limit ranges to avoid vm.bound overflow in fuzzing — use modulo to keep values small
        length = (length % 256) + 1; // length in [1,256]
        // produce index >= length but not huge
        index = length + (index % 256);
        BetterArraysCaller caller = new BetterArraysCaller();
        vm.expectRevert();
        caller.isValidIndex(length, index);
    }

    // 3. _toLength for fixed-size address[5]
    function test_toLength_fixed5() public pure {
        address[5] memory contracts = [address(0x1), address(0x2), address(0x3), address(0x4), address(0x5)];
        address[] memory out = BetterArrays._toLength(contracts, 7);
        assertEq(out.length, 7);
        assertEq(out[0], address(0x1));
        assertEq(out[4], address(0x5));
        // newly allocated slots should be zero
        assertEq(out[5], address(0));
        assertEq(out[6], address(0));
    }

    // 3b. _toLength for fixed-size address[10]
    function test_toLength_fixed10_success() public {
        BetterArraysCaller caller = new BetterArraysCaller();
        address[] memory out = caller.toLengthFixed10(12);
        assertEq(out.length, 12);
        assertEq(out[0], address(0x1));
        assertEq(out[9], address(0xa));
        assertEq(out[10], address(0));
        assertEq(out[11], address(0));
    }

    function test_toLength_fixed10_revert() public {
        BetterArraysCaller caller = new BetterArraysCaller();
        vm.expectRevert();
        caller.toLengthFixed10(9);
    }

    // 3c. _toLength for fixed-size address[100]
    function test_toLength_fixed100_success() public {
        BetterArraysCaller caller = new BetterArraysCaller();
        address[] memory out = caller.toLengthFixed100(120);
        assertEq(out.length, 120);
        // spot-check a few entries
        assertEq(out[0], address(0x1));
        assertEq(out[50], address(uint160(51)));
        assertEq(out[99], address(uint160(100)));
        assertEq(out[100], address(0));
    }

    function test_toLength_fixed100_revert() public {
        BetterArraysCaller caller = new BetterArraysCaller();
        vm.expectRevert();
        caller.toLengthFixed100(99);
    }

    // 3d. _toLength for fixed-size address[1000] (success only)
    function test_toLength_fixed1000_success() public {
        BetterArraysCaller caller = new BetterArraysCaller();
        address[] memory out = caller.toLengthFixed1000(1010);
        assertEq(out.length, 1010);
        assertEq(out[0], address(0x1));
        assertEq(out[999], address(uint160(1000)));
        assertEq(out[1000], address(0));
    }

    // 4. _toLength for dynamic address[]
    function test_toLength_dynamic() public pure {
        address[] memory contracts = new address[](2);
        contracts[0] = address(0xabcdef);
        contracts[1] = address(0x123456);
        address[] memory out = BetterArrays._toLength(contracts, 4);
        assertEq(out.length, 4);
        assertEq(out[0], address(0xabcdef));
        assertEq(out[1], address(0x123456));
        assertEq(out[2], address(0));
        assertEq(out[3], address(0));
    }

    // 5. _unsafeMemoryAccess for bytes32[] memory
    function test_unsafeMemoryAccess() public pure {
        bytes32[] memory arr = new bytes32[](3);
        arr[0] = bytes32(uint256(1));
        arr[1] = bytes32(uint256(2));
        arr[2] = bytes32(uint256(3));
        bytes32 v1 = BetterArrays._unsafeMemoryAccess(arr, 1);
        assertEq(uint256(v1), 2);
    }

    // 6. _lowerBoundMemory and _upperBoundMemory for uint256[] memory
    function test_bounds_memory() public pure {
        uint256[] memory sorted = new uint256[](4);
        sorted[0] = 1;
        sorted[1] = 3;
        sorted[2] = 5;
        sorted[3] = 7;

        uint256 lb_5 = BetterArrays._lowerBoundMemory(sorted, 5);
        uint256 ub_5 = BetterArrays._upperBoundMemory(sorted, 5);
        assertEq(lb_5, 2);
        assertEq(ub_5, 3);

        uint256 lb_4 = BetterArrays._lowerBoundMemory(sorted, 4);
        uint256 ub_4 = BetterArrays._upperBoundMemory(sorted, 4);
        assertEq(lb_4, 2);
        assertEq(ub_4, 2);

        uint256 lb_8 = BetterArrays._lowerBoundMemory(sorted, 8);
        assertEq(lb_8, 4);
    }
}

