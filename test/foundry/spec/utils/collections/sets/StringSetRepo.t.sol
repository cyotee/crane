// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// solhint-disable no-global-import
// solhint-disable state-visibility
// solhint-disable func-name-mixedcase
/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";
// import "daosys/test/BetterTest.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "src/utils/collections/sets/StringSetRepo.sol";

contract StringSetRepoTest is Test {
    using StringSetRepo for StringSet;

    StringSet testInstance;

    function test_index(string[] calldata values) public {
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            testInstance.values.push(values[cursor]);
            testInstance.indexes[values[cursor]] = testInstance.values.length;
        }
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            assertEq(values[cursor], testInstance._index(testInstance.indexes[values[cursor]] - 1));
        }
    }

    function test_contains(string[] calldata values) public {
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            testInstance.values.push(values[cursor]);
            testInstance.indexes[values[cursor]] = testInstance.values.length;
        }
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            assert(testInstance._contains(values[cursor]));
        }
    }

    function test_indexOf(string[] calldata values) public {
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

    function test_length(string[] calldata values) public {
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            testInstance.values.push(values[cursor]);
            testInstance.indexes[values[cursor]] = testInstance.values.length;
        }
        assertEq(values.length, testInstance._length());
    }

    function test_add(string calldata value) public {
        testInstance._add(value);
        assertEq(value, testInstance.values[testInstance.indexes[value] - 1]);
    }

    function test_add(string[] calldata values) public {
        testInstance._add(values);
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            assertEq(values[cursor], testInstance.values[testInstance.indexes[values[cursor]] - 1]);
        }
    }

    function test_addExclusive(string memory value) public {
        testInstance._addExclusive(value);
        assertEq(value, testInstance.values[testInstance.indexes[value] - 1]);
    }

    // function test_addExclusive(
    //     string[] memory values
    // ) public {
    //     for(uint256 cursor = 0; values.length > cursor; cursor++) {
    //         for(uint256 cursor1 = 0; values.length > cursor1; cursor1++) {
    //             if(cursor != cursor1) {
    //                 vm.assume(values[cursor] != values[cursor1]);
    //             }
    //         }
    //     }
    //     testInstance._addExclusive(values);
    //     for(uint256 cursor = 0; values.length > cursor; cursor++) {
    //         assertEq(
    //             values[cursor],
    //             testInstance.values[testInstance.indexes[values[cursor]] - 1]
    //         );
    //     }
    // }

    function test_remove(string calldata value) public {
        testInstance.values.push(value);
        testInstance.indexes[value] = testInstance.values.length;
        assert(testInstance._contains(value));
        testInstance._remove(value);
        assert(!testInstance._contains(value));
    }

    function test_remove(string[] calldata values) public {
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
