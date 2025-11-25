// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BetterArrays as Arrays} from "src/utils/collections/BetterArrays.sol";

struct Bytes4Set {
    // 1-indexed to allow 0 to signify nonexistence
    mapping(bytes4 => uint256) indexes;
    bytes4[] values;
}

library Bytes4SetRepo {

    using Arrays for uint256;
    using Bytes4SetRepo for Bytes4Set;

    function _index(Bytes4Set storage set, uint256 index) internal view returns (bytes4 value) {
        set.values.length._isValidIndex(index);
        value = set.values[index];
    }

    function _contains(Bytes4Set storage set, bytes4 value) internal view returns (bool success) {
        return set.indexes[value] != 0;
    }

    function _indexOf(Bytes4Set storage set, bytes4 value) internal view returns (uint256 index) {
        unchecked {
            index = set.indexes[value] - 1;
        }
    }

    function _length(Bytes4Set storage set) internal view returns (uint256 length) {
        length = set.values.length;
    }

    function _add(Bytes4Set storage set, bytes4[] memory values) internal {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _add(set, values[iteration]);
        }
    }

    function _add(Bytes4Set storage set, bytes4 value) internal {
        if (!_contains(set, value)) {
            set.values.push(value);
            set.indexes[value] = set.values.length;
        }
    }

    function _remove(Bytes4Set storage set, bytes4 value) internal {
        uint256 valueIndex = set.indexes[value];

        if (valueIndex != 0) {
            uint256 index = valueIndex - 1;
            bytes4 last = set.values[set.values.length - 1];

            // move last value to now-vacant index

            set.values[index] = last;
            set.indexes[last] = index + 1;

            // clear last index

            set.values.pop();
            delete set.indexes[value];
        }
    }

    function _remove(Bytes4Set storage set, bytes4[] memory values) internal {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _remove(set, values[iteration]);
        }
    }

    function _asArray(Bytes4Set storage set) internal view returns (bytes4[] memory rawSet) {
        rawSet = set.values;
    }

    /**
     * @dev Provides the storage pointer os the underlying array of value.
     * @dev DO NOT alter values via this pointer.
     * @dev ONLY use to minimize memory usage when passing a reference internally for gas efficiency.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @return values The members of the set copied to memory as an array.
     */
    function _values(Bytes4Set storage set) internal view returns (bytes4[] storage values) {
        values = set.values;
    }

    function _wipeSet(Bytes4Set storage set) internal returns (bool success) {
        // for (uint256 cursor = 0; cursor < set.values.length; cursor++) {
        //     delete set.indexes[set.values[cursor]];
        //     // TODO Refactor to pop entries off array to reduce size.
        // }
        for (uint256 cursor = set.values.length; cursor > 0; --cursor) {
            bytes4 value = set.values[cursor -1];
            delete set.indexes[value];
            set.values.pop();
        }
        return true;
    }

    function _lastDestruct(Bytes4Set storage set) internal returns (bytes4 lastValue) {
        lastValue = set.values[set.values.length - 1];
        delete set.indexes[lastValue];
        set.values.pop();
    }
}
