// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BetterArrays as Arrays} from "contracts/utils/collections/BetterArrays.sol";

struct StringSet {
    // 1-indexed to allow 0 to signify nonexistence
    mapping(string => uint256) indexes;
    string[] values;
}

/**
 * @title StringSetRepo - Struct and atomic operations for a set of string values
 * @author cyotee doge <doge.cyotee>
 * @dev Distinct from OpenZeppelin to allow for operations upon an array of the same type.
 */
library StringSetRepo {
    using Arrays for uint256;
    using StringSetRepo for StringSet;

    /**
     * @dev Returns the value stored at the provided index.
     * @dev Will return a default value if the index is not used.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param index The index of the value to retrieve.
     * @return value The value stored under the provided index.
     */
    function _index(StringSet storage set, uint256 index) internal view returns (string memory) {
        set.values.length._isValidIndex(index);
        return set.values[index];
    }

    /**
     * @dev Returns the index of the provided value.
     * @dev Will return 2**256-1 if the value is not present.
     * @dev Using underflow to prevent reversion if value is not present.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value of which to retrieve the index.
     * @return index The index of the value.
     */
    function _indexOf(StringSet storage set, string memory value) internal view returns (uint256) {
        unchecked {
            return set.indexes[value] - 1;
        }
    }

    /**
     * @dev Returns boolean indicating if the value is present in the set.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value for which to check presence.
     * @return isPresent Boolean indicating presence of value in set.
     */
    function _contains(StringSet storage set, string memory value) internal view returns (bool isPresent) {
        isPresent = set.indexes[value] != 0;
    }

    /**
     * @dev Returns the length of the provided set.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @return length The "length", quantity of entries, of the provided set.
     */
    function _length(StringSet storage set) internal view returns (uint256) {
        return set.values.length;
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
    function _add(StringSet storage set, string memory value) internal {
        if (!_contains(set, value)) {
            // console.log("Storing string %s", value);
            set.values.push(value);
            set.indexes[value] = set.values.length;
        }
    }

    /**
     * @dev Idempotently adds an array of values to the provided set.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param values The array of values to ensure are present in the provided set.
     */
    function _add(StringSet storage set, string[] memory values) internal {
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
    function _remove(StringSet storage set, string memory value) internal returns (bool) {
        uint256 valueIndex = set.indexes[value];

        if (valueIndex != 0) {
            uint256 index = valueIndex - 1;
            string memory last = set.values[set.values.length - 1];

            // move last value to now-vacant index

            set.values[index] = last;
            set.indexes[last] = index + 1;

            // clear last index

            set.values.pop();
            delete set.indexes[value];
        }

        return true;
    }

    /**
     * @dev Provides the storage pointer os the underlying array of value.
     * @dev DO NOT alter values via this pointer.
     * @dev ONLY use to minimize memory usage when passing a reference internally for gas efficiency.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @return values The members of the set copied to memory as an array.
     */
    function _values(StringSet storage set) internal view returns (string[] storage values) {
        values = set.values;
    }
}
