// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// solhint-disable no-global-import
// solhint-disable state-visibility
// solhint-disable func-name-mixedcase
/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";
// import "daosys/test/BetterTest.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/utils/collections/sets/Bytes32SetRepo.sol";

contract Bytes32SetRepoTest is Test {
    using Bytes32SetRepo for Bytes32Set;

    Bytes32Set testInstance;

    function test_index(bytes32[] calldata values) public {
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            testInstance.values.push(values[cursor]);
            testInstance.indexes[values[cursor]] = testInstance.values.length;
        }
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            assertEq(values[cursor], testInstance._index(testInstance.indexes[values[cursor]] - 1));
        }
    }

    function test_indexOf(bytes32[] calldata values) public {
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            testInstance.values.push(values[cursor]);
            testInstance.indexes[values[cursor]] = testInstance.values.length;
        }
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            assertEq(
                // cursor,
                testInstance.indexes[values[cursor]] - 1,
                testInstance._indexOf(values[cursor])
            );
        }
    }

    function test_contains(bytes32[] calldata values) public {
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            testInstance.values.push(values[cursor]);
            testInstance.indexes[values[cursor]] = testInstance.values.length;
        }
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            assert(testInstance._contains(values[cursor]));
        }
    }

    function test_length(bytes32[] calldata values) public {
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            testInstance.values.push(values[cursor]);
            testInstance.indexes[values[cursor]] = testInstance.values.length;
        }
        assertEq(values.length, testInstance._length());
    }

    function test_add(bytes32 value) public {
        testInstance._add(value);
        assertEq(value, testInstance.values[testInstance.indexes[value] - 1]);
    }

    function test_add(bytes32[] calldata values) public {
        testInstance._add(values);
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            assertEq(values[cursor], testInstance.values[testInstance.indexes[values[cursor]] - 1]);
        }
    }

    function test_remove(bytes32 value) public {
        testInstance.values.push(value);
        testInstance.indexes[value] = testInstance.values.length;
        assert(testInstance._contains(value));
        testInstance._remove(value);
        assert(!testInstance._contains(value));
    }

    function test_remove(bytes32[] calldata values) public {
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            testInstance.values.push(values[cursor]);
            testInstance.indexes[values[cursor]] = testInstance.values.length;
        }
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            assert(testInstance._contains(values[cursor]));
        }
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            testInstance._remove(values[cursor]);
            assert(!testInstance._contains(values[cursor]));
        }
    }
}
