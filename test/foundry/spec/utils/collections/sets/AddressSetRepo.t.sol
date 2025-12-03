// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/utils/collections/sets/AddressSetRepo.sol";

// Small caller wrapper to allow try/catch of library reverts from an external call
contract AddressSetRepoCaller {
    using AddressSetRepo for AddressSet;
    AddressSet internal s;

    function add(address a) external {
        s._add(a);
    }

    function range(uint256 start, uint256 end) external view returns (address[] memory) {
        return s._range(start, end);
    }
}

contract AddressSetRepoTest is Test {
    using AddressSetRepo for AddressSet;

    AddressSet testInstance;

    function test_index(address[] calldata values) public {
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            testInstance.values.push(values[cursor]);
            testInstance.indexes[values[cursor]] = testInstance.values.length;
        }
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            assertEq(values[cursor], testInstance._index(testInstance.indexes[values[cursor]] - 1));
        }
    }

    function test_contains(address[] calldata values) public {
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            testInstance.values.push(values[cursor]);
            testInstance.indexes[values[cursor]] = testInstance.values.length;
        }
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            assert(testInstance._contains(values[cursor]));
        }
    }

    function test_indexOf(address[] calldata values) public {
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

    function test_length(address[] calldata values) public {
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            testInstance.values.push(values[cursor]);
            testInstance.indexes[values[cursor]] = testInstance.values.length;
        }
        assertEq(values.length, testInstance._length());
    }

    function test_add(address value) public {
        testInstance._add(value);
        assertEq(value, testInstance.values[testInstance.indexes[value] - 1]);
    }

    function test_add(address[] calldata values) public {
        testInstance._add(values);
        for (uint256 cursor = 0; values.length > cursor; cursor++) {
            assertEq(values[cursor], testInstance.values[testInstance.indexes[values[cursor]] - 1]);
        }
    }

    function test_remove(address value) public {
        testInstance.values.push(value);
        testInstance.indexes[value] = testInstance.values.length;
        assert(testInstance._contains(value));
        testInstance._remove(value);
        assert(!testInstance._contains(value));
    }

    function test_remove(address[] calldata values) public {
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

    function test_addAsc_and_removeAsc() public {
        address a = address(0x10);
        address b = address(0x05);
        address c = address(0x20);

        testInstance._addAsc(a);
        testInstance._addAsc(b);
        testInstance._addAsc(c);

        // Expect ascending: b, a, c
        assertEq(testInstance.values.length, 3);
        assertEq(testInstance.values[0], b);
        assertEq(testInstance.values[1], a);
        assertEq(testInstance.values[2], c);

        // Indexes should be 1-indexed
        assertEq(testInstance.indexes[b], 1);
        assertEq(testInstance.indexes[a], 2);
        assertEq(testInstance.indexes[c], 3);

        // Removing `a` with _removeAsc should preserve ascending order
        testInstance._removeAsc(a);
        assertEq(testInstance.values.length, 2);
        assertEq(testInstance.values[0], b);
        assertEq(testInstance.values[1], c);
        assertEq(testInstance.indexes[b], 1);
        assertEq(testInstance.indexes[c], 2);
    }

    function test_sortAsc_and_quickSort() public {
        address[] memory addrs = new address[](6);
        addrs[0] = address(0x33);
        addrs[1] = address(0x01);
        addrs[2] = address(0x10);
        addrs[3] = address(0x02);
        addrs[4] = address(0xFF);
        addrs[5] = address(0x0A);

        for (uint256 i = 0; i < addrs.length; i++) {
            testInstance._add(addrs[i]);
        }

        testInstance._sortAsc();
        for (uint256 i = 1; i < testInstance.values.length; i++) {
            assert(testInstance.values[i - 1] <= testInstance.values[i]);
            assertEq(testInstance.indexes[testInstance.values[i - 1]], i);
        }

        delete testInstance;

        for (uint256 i = 0; i < addrs.length; i++) {
            testInstance._add(addrs[i]);
        }

        testInstance._quickSort();
        for (uint256 i = 1; i < testInstance.values.length; i++) {
            assert(testInstance.values[i - 1] <= testInstance.values[i]);
            assertEq(testInstance.indexes[testInstance.values[i]], i + 1);
        }
    }

    function test_asArray_values_range_and_indexOf_missing() public {
        address[] memory addrs = new address[](4);
        addrs[0] = address(0x11);
        addrs[1] = address(0x22);
        addrs[2] = address(0x33);
        addrs[3] = address(0x44);

        testInstance._add(addrs);

        address[] memory mem = testInstance._asArray();
        assertEq(mem.length, testInstance._length());
        for (uint256 i = 0; i < mem.length; i++) {
            assertEq(mem[i], testInstance.values[i]);
        }

        address[] storage vals = testInstance._values();
        assertEq(vals.length, testInstance._length());
        for (uint256 i = 0; i < vals.length; i++) {
            assertEq(vals[i], testInstance.values[i]);
        }

        address[] memory rng = testInstance._range(1, 2);
        assertEq(rng.length, 2);
        assertEq(rng[0], testInstance._index(1));
        assertEq(rng[1], testInstance._index(2));

        uint256 missingIdx = testInstance._indexOf(address(0xDEAD));
        assertEq(missingIdx, type(uint256).max);

        // invalid range should revert (end < start) when called externally
        AddressSetRepoCaller caller = new AddressSetRepoCaller();
        // populate caller's set too
        for (uint256 i = 0; i < addrs.length; i++) {
            caller.add(addrs[i]);
        }

        try caller.range(3, 1) returns (address[] memory) {
            // if it returns, that's a failure
            fail();
        } catch (bytes memory) {
            // expected revert
        }
    }

    function test_addAsc_idempotent() public {
        address x = address(0xABC);
        testInstance._addAsc(x);
        uint256 lenBefore = testInstance._length();
        testInstance._addAsc(x);
        assertEq(testInstance._length(), lenBefore);
    }
}
