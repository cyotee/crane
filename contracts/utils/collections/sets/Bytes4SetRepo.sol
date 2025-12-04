// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BetterArrays as Arrays} from "@crane/contracts/utils/collections/BetterArrays.sol";

struct Bytes4Set {
    // 1-indexed to allow 0 to signify nonexistence
    mapping(bytes4 => uint256) indexes;
    bytes4[] values;
}

/**
 * @title Bytes4SetRepo - Struct and atomic operations for a set of 4 byte values
 * @author cyotee doge <doge.cyotee>
 * @dev Distinct from OpenZeppelin to allow for operations upon an array of the same type.
 */
library Bytes4SetRepo {
    using Arrays for uint256;
    using Bytes4SetRepo for Bytes4Set;

    /**
     * @dev Returns the value stored at the provided index.
     * @dev Will return a default value if the index is not used.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param index The index of the value to retrieve.
     * @return value The value stored under the provided index.
     */
    function _index(Bytes4Set storage set, uint256 index) internal view returns (bytes4 value) {
        set.values.length._isValidIndex(index);
        value = set.values[index];
    }

    /**
     * @dev Returns the index of the provided value.
     * @dev Will return 2**256-1 if the value is not present.
     * @dev Using underflow to prevent reversion if value is not present.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value of which to retrieve the index.
     * @return index The index of the value.
     */
    function _indexOf(Bytes4Set storage set, bytes4 value) internal view returns (uint256 index) {
        unchecked {
            index = set.indexes[value] - 1;
        }
    }

    /**
     * @dev Returns boolean indicating if the value is present in the set.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value for which to check presence.
     * @return isPresent Boolean indicating presence of value in set.
     */
    function _contains(Bytes4Set storage set, bytes4 value) internal view returns (bool isPresent) {
        isPresent = set.indexes[value] != 0;
    }

    /**
     * @dev Returns the length of the provided set.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @return length The "length", quantity of entries, of the provided set.
     */
    function _length(Bytes4Set storage set) internal view returns (uint256 length) {
        length = set.values.length;
    }

    /**
     * @dev Written to be idempotent.
     * @dev Sets care about ensuring desired state.
     * @dev Desired state is for the value to be present in set.
     * @dev If the value is present, desired state has been achieved.
     * @dev When the state change was achieved is irrelevant.
     * @dev If presence prior to addition is relevant, encapsulating logic should check for presence.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value to ensure is present in the provided set.
     */
    function _add(Bytes4Set storage set, bytes4 value) internal {
        if (!_contains(set, value)) {
            set.values.push(value);
            set.indexes[value] = set.values.length;
        }
    }

    /**
     * @dev Idempotently adds an array of values to the provided set.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param values The array of values to ensure are present in the provided set.
     */
    function _add(Bytes4Set storage set, bytes4[] memory values) internal {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _add(set, values[iteration]);
        }
    }

    /**
     * @dev Written to be idempotent.
     * @dev Sets care about ensuring desired state.
     * @dev Desired state is for address to not be present in the set.
     * @dev If address is not present, desired state has been achieved.
     * @dev When the state change was achieved is irrelevant.
     * @dev If lack of presence prior to addition is relevant, encapsulating logic should check for lakc of presence.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value to ensure is not present in the provided set.
     */
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

    /**
     * @dev Idempotently removes an array of values to the provided set.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param values The array of values to ensure are not present in the provided set.
     */
    function _remove(Bytes4Set storage set, bytes4[] memory values) internal {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _remove(set, values[iteration]);
        }
    }

    /**
     * @dev Copies the set into memory as an array.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @return array The members of the set copied to memory as an array.
     */
    function _asArray(Bytes4Set storage set) internal view returns (bytes4[] memory array) {
        array = set.values;
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

    /**
     * @dev Deletes all values and indexese from the set.
     * @dev Will provide the gas refund for setting a value to default.
     * @param set The storage pointer os the struct upon which this function should operate.
     */
    function _wipeSet(Bytes4Set storage set) internal {
        for (uint256 cursor = set.values.length; cursor > 0; --cursor) {
            bytes4 value = set.values[cursor - 1];
            delete set.indexes[value];
            set.values.pop();
        }
    }
}
