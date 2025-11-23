// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

struct Bytes32Set {
    // 1-indexed to allow 0 to signify nonexistence
    mapping(bytes32 => uint256) indexes;
    bytes32[] values;
}

/**
 * @title Bytes32SetRepo - Struct and atomic operations for a set of 32 byte values
 * @author cyotee doge <doge.cyotee>
 */
library Bytes32SetRepo {
    using Bytes32SetRepo for Bytes32Set;

    /**
     * @dev Will rrevert is provided index is out of bounds.
     * @param set The sotrage struct upon which this function will operate.
     * @param index The index of the value to be loaded from storage.
     * @return value The value from the set at the provided index.
     */
    function _index(Bytes32Set storage set, uint256 index) internal view returns (bytes32 value) {
        require(set.values.length > index, "Bytes32Set: index out of bounds");
        value = set.values[index];
    }

    function _contains(Bytes32Set storage set, bytes32 value) internal view returns (bool success) {
        success = set.indexes[value] != 0;
    }

    function _indexOf(Bytes32Set storage set, bytes32 value) internal view returns (uint256 index) {
        unchecked {
            index = set.indexes[value] - 1;
        }
    }

    function _length(Bytes32Set storage set) internal view returns (uint256 length) {
        length = set.values.length;
    }

    function _add(Bytes32Set storage set, bytes32 value) internal returns (bool success) {
        if (!_contains(set, value)) {
            set.values.push(value);
            set.indexes[value] = set.values.length;
        }
        success = true;
    }

    function _addExclusive(Bytes32Set storage set, bytes32 value) internal returns (bool success) {
        if (!_contains(set, value)) {
            set.values.push(value);
            set.indexes[value] = set.values.length;
            return true;
        }
        return false;
    }

    function _add(Bytes32Set storage set, bytes32[] memory values) internal returns (bool success) {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _add(set, values[iteration]);
        }
        success = true;
    }

    function _addExclusive(Bytes32Set storage set, bytes32[] memory values) internal returns (bool success) {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            success = _addExclusive(set, values[iteration]);
            require(success == true, "AddressSet: value already present.");
        }
    }

    function _remove(Bytes32Set storage set, bytes32 value) internal returns (bool success) {
        uint256 valueIndex = set.indexes[value];

        if (valueIndex != 0) {
            uint256 index = valueIndex - 1;
            bytes32 last = set.values[set.values.length - 1];

            // move last value to now-vacant index

            set.values[index] = last;
            set.indexes[last] = index + 1;

            // clear last index

            set.values.pop();
            delete set.indexes[value];
        }
        success = true;
    }

    function _remove(Bytes32Set storage set, bytes32[] memory values) internal returns (bool success) {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _remove(set, values[iteration]);
        }
        success = true;
    }

    function _values(Bytes32Set storage set) internal view returns (bytes32[] storage rawSet) {
        rawSet = set.values;
    }
}
