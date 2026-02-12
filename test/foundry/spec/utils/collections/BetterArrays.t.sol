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

    function toLengthDynamic(uint256 originalLen, uint256 newLen) external pure returns (address[] memory) {
        address[] memory contracts = new address[](originalLen);
        for (uint256 i = 0; i < originalLen; i++) {
            contracts[i] = address(uint160(i + 1));
        }
        return BetterArrays._toLength(contracts, newLen);
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

    /* -------------------------------------------------------------------------- */
    /*                               Sort Tests                                   */
    /* -------------------------------------------------------------------------- */

    function test_sort_uint256_sortsAscending() public pure {
        uint256[] memory arr = new uint256[](5);
        arr[0] = 5;
        arr[1] = 2;
        arr[2] = 8;
        arr[3] = 1;
        arr[4] = 9;

        uint256[] memory sorted = BetterArrays._sort(arr);

        assertEq(sorted[0], 1);
        assertEq(sorted[1], 2);
        assertEq(sorted[2], 5);
        assertEq(sorted[3], 8);
        assertEq(sorted[4], 9);
    }

    function _descendingUint256(uint256 a, uint256 b) internal pure returns (bool) {
        return a > b;
    }

    function test_sort_uint256_withComparator_sortsDescending() public pure {
        uint256[] memory arr = new uint256[](5);
        arr[0] = 5;
        arr[1] = 2;
        arr[2] = 8;
        arr[3] = 1;
        arr[4] = 9;

        uint256[] memory sorted = BetterArrays._sort(arr, _descendingUint256);

        assertEq(sorted[0], 9);
        assertEq(sorted[1], 8);
        assertEq(sorted[2], 5);
        assertEq(sorted[3], 2);
        assertEq(sorted[4], 1);
    }

    function test_sort_address_sortsAscending() public pure {
        address[] memory arr = new address[](3);
        arr[0] = address(0x3);
        arr[1] = address(0x1);
        arr[2] = address(0x2);

        address[] memory sorted = BetterArrays._sort(arr);

        assertEq(sorted[0], address(0x1));
        assertEq(sorted[1], address(0x2));
        assertEq(sorted[2], address(0x3));
    }

    function test_sort_bytes32_sortsAscending() public pure {
        bytes32[] memory arr = new bytes32[](3);
        arr[0] = bytes32(uint256(3));
        arr[1] = bytes32(uint256(1));
        arr[2] = bytes32(uint256(2));

        bytes32[] memory sorted = BetterArrays._sort(arr);

        assertEq(sorted[0], bytes32(uint256(1)));
        assertEq(sorted[1], bytes32(uint256(2)));
        assertEq(sorted[2], bytes32(uint256(3)));
    }

    function test_sort_emptyArray_returnsEmpty() public pure {
        uint256[] memory arr = new uint256[](0);
        uint256[] memory sorted = BetterArrays._sort(arr);
        assertEq(sorted.length, 0);
    }

    function test_sort_singleElement_returnsSame() public pure {
        uint256[] memory arr = new uint256[](1);
        arr[0] = 42;
        uint256[] memory sorted = BetterArrays._sort(arr);
        assertEq(sorted.length, 1);
        assertEq(sorted[0], 42);
    }

    /* -------------------------------------------------------------------------- */
    /*                       Additional Memory Access Tests                       */
    /* -------------------------------------------------------------------------- */

    function test_unsafeMemoryAccess_address() public pure {
        address[] memory arr = new address[](2);
        arr[0] = address(0x1);
        arr[1] = address(0x2);

        assertEq(BetterArrays._unsafeMemoryAccess(arr, 0), address(0x1));
        assertEq(BetterArrays._unsafeMemoryAccess(arr, 1), address(0x2));
    }

    function test_unsafeMemoryAccess_uint256() public pure {
        uint256[] memory arr = new uint256[](2);
        arr[0] = 100;
        arr[1] = 200;

        assertEq(BetterArrays._unsafeMemoryAccess(arr, 0), 100);
        assertEq(BetterArrays._unsafeMemoryAccess(arr, 1), 200);
    }

    function test_unsafeMemoryAccess_bytes() public pure {
        bytes[] memory arr = new bytes[](2);
        arr[0] = hex"1234";
        arr[1] = hex"5678";

        assertEq(BetterArrays._unsafeMemoryAccess(arr, 0), hex"1234");
        assertEq(BetterArrays._unsafeMemoryAccess(arr, 1), hex"5678");
    }

    function test_unsafeMemoryAccess_string() public pure {
        string[] memory arr = new string[](2);
        arr[0] = "hello";
        arr[1] = "world";

        assertEq(BetterArrays._unsafeMemoryAccess(arr, 0), "hello");
        assertEq(BetterArrays._unsafeMemoryAccess(arr, 1), "world");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Edge Case Tests                                   */
    /* -------------------------------------------------------------------------- */

    function test_toLength_dynamic_sameLength() public pure {
        address[] memory arr = new address[](3);
        arr[0] = address(0x1);
        arr[1] = address(0x2);
        arr[2] = address(0x3);

        address[] memory copied = BetterArrays._toLength(arr, 3);

        assertEq(copied.length, 3);
        assertEq(copied[0], address(0x1));
        assertEq(copied[1], address(0x2));
        assertEq(copied[2], address(0x3));
    }

    function test_toLength_dynamic_revert_smallerLength() public {
        BetterArraysCaller caller = new BetterArraysCaller();
        vm.expectRevert(abi.encodeWithSelector(BetterArrays.EndBeforeStart.selector, 5, 3));
        caller.toLengthDynamic(5, 3);
    }

    function test_isValidIndex_zeroLength_reverts() public {
        BetterArraysCaller caller = new BetterArraysCaller();
        vm.expectRevert();
        caller.isValidIndex(0, 0);
    }

    function test_bounds_memory_emptyArray() public pure {
        uint256[] memory arr = new uint256[](0);
        assertEq(BetterArrays._lowerBoundMemory(arr, 5), 0);
        assertEq(BetterArrays._upperBoundMemory(arr, 5), 0);
    }

    function test_bounds_memory_singleElement() public pure {
        uint256[] memory arr = new uint256[](1);
        arr[0] = 5;

        assertEq(BetterArrays._lowerBoundMemory(arr, 3), 0);
        assertEq(BetterArrays._lowerBoundMemory(arr, 5), 0);
        assertEq(BetterArrays._lowerBoundMemory(arr, 7), 1);

        assertEq(BetterArrays._upperBoundMemory(arr, 3), 0);
        assertEq(BetterArrays._upperBoundMemory(arr, 5), 1);
        assertEq(BetterArrays._upperBoundMemory(arr, 7), 1);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Fuzz Tests                                   */
    /* -------------------------------------------------------------------------- */

    function testFuzz_sort_uint256_isSorted(uint256[5] memory values) public pure {
        uint256[] memory arr = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            arr[i] = values[i];
        }

        uint256[] memory sorted = BetterArrays._sort(arr);

        for (uint256 i = 1; i < sorted.length; i++) {
            assertTrue(sorted[i - 1] <= sorted[i], "Array should be sorted ascending");
        }
    }

    function testFuzz_toLength_expandsCorrectly(uint8 originalLen, uint8 extraLen) public pure {
        vm.assume(originalLen <= 50);
        uint256 newLen = uint256(originalLen) + uint256(extraLen);

        address[] memory arr = new address[](originalLen);
        for (uint256 i = 0; i < originalLen; i++) {
            arr[i] = address(uint160(i + 1));
        }

        address[] memory expanded = BetterArrays._toLength(arr, newLen);

        assertEq(expanded.length, newLen);
        for (uint256 i = 0; i < originalLen; i++) {
            assertEq(expanded[i], address(uint160(i + 1)));
        }
    }

    function testFuzz_unsafeMemoryAccess_uint256(uint256[10] memory values, uint8 index) public pure {
        index = uint8(bound(index, 0, 9));

        uint256[] memory arr = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            arr[i] = values[i];
        }

        assertEq(BetterArrays._unsafeMemoryAccess(arr, index), values[index]);
    }

    function testFuzz_lowerBound_findsCorrectPosition(uint256[5] memory values, uint256 target) public pure {
        // Sort the values first
        uint256[] memory arr = new uint256[](5);
        for (uint256 i = 0; i < 5; i++) {
            arr[i] = values[i];
        }
        arr = BetterArrays._sort(arr);

        uint256 lb = BetterArrays._lowerBoundMemory(arr, target);

        // Verify: all elements before lb are < target
        for (uint256 i = 0; i < lb; i++) {
            assertTrue(arr[i] < target, "Elements before lowerBound should be less than target");
        }
        // Verify: if lb < length, element at lb is >= target
        if (lb < arr.length) {
            assertTrue(arr[lb] >= target, "Element at lowerBound should be >= target");
        }
    }
}

