// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BetterArrays as Arrays} from "src/utils/collections/BetterArrays.sol";

struct AddressSet {
    // 1-indexed to allow 0 to signify nonexistence
    mapping(address => uint256) indexes;
    // Values in set.
    address[] values;
}

/**
 * @title AddressSetRepo - Struct and atomic operations for a set of address values;
 * @author cyotee doge <doge.cyotee>
 * @dev Distinct from OpenZeppelin to allow for operations upon an array of the same type.
 */
library AddressSetRepo {
    using Arrays for uint256;
    using AddressSetRepo for AddressSet;

    /**
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param index The index of the value to retrieve.
     * @return value The value stored under the provided index.
     */
    function _index(AddressSet storage set, uint256 index) internal view returns (address value) {
        set.values.length._isValidIndex(index);
        return set.values[index];
    }

    /**
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value of which to retrieve the index.
     * @return index The index of the value.
     */
    function _indexOf(AddressSet storage set, address value) internal view returns (uint256 index) {
        unchecked {
            return set.indexes[value] - 1;
        }
    }

    /**
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value for which to check presence.
     * @return isPresent Boolean indicating presence of value in set.
     */
    function _contains(AddressSet storage set, address value) internal view returns (bool isPresent) {
        return set.indexes[value] != 0;
    }

    /**
     * @param set The storage pointer of the struct upon which this function should operate.
     * @return length_ The "length", quantity of entries, of the provided set.
     */
    function length(AddressSet storage set) internal view returns (uint256 length_) {
        return set.values.length;
    }

    /**
     * @param set The storage pointer of the struct upon which this function should operate.
     * @return length_ The "length", quantity of entries, of the provided set.
     */
    function _length(AddressSet storage set) internal view returns (uint256 length_) {
        return set.values.length;
    }

    /**
     * @dev Written to be idempotent.
     * @dev Sets care about ensuring desired state.
     * @dev Desired state is for address to be present in set.
     * @dev If address is present, desired state has been achieved.
     * @dev When the state change was achieved is irrelevant.
     * @dev If presence prior to addition is relevant, encapsulating logic should check for presence.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value to ensure is present in the provided set.
     * @return success Boolean indicating desired set state has been achieved.
     */
    function _add(AddressSet storage set, address value) internal returns (bool success) {
        if (!_contains(set, value)) {
            set.values.push(value);
            set.indexes[value] = set.values.length;
        }
        return true;
    }

    /**
     * @dev Idempotently adds an array of values to the provided set.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param values The array of values to ensure are present in the provided set.
     * @return success Boolean indicating desired set state has been achieved.
     */
    function _add(AddressSet storage set, address[] memory values) internal returns (bool success) {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _add(set, values[iteration]);
        }
        return true;
    }

    function _addExclusive(AddressSet storage set, address value) internal returns (bool success) {
        if (!_contains(set, value)) {
            set.values.push(value);
            set.indexes[value] = set.values.length;
            return true;
        }
        return false;
    }

    function _addExclusive(AddressSet storage set, address[] memory values) internal returns (bool success) {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            success = _addExclusive(set, values[iteration]);
            require(success == true, "AddressSet: value already present.");
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
     * @return success Boolean indicating desired set state has been achieved.
     */
    function _remove(AddressSet storage set, address value) internal returns (bool success) {
        uint256 valueIndex = set.indexes[value];

        if (valueIndex != 0) {
            uint256 index = valueIndex - 1;
            address last = set.values[set.values.length - 1];

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
     * @dev Idempotently removes an array of values to the provided set.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param values The array of values to ensure are not present in the provided set.
     * @return success Boolean indicating desired set state has been achieved.
     */
    function _remove(AddressSet storage set, address[] memory values) internal returns (bool success) {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _remove(set, values[iteration]);
        }
        success = true;
    }

    /**
     * @dev Copies the set into memory as an array.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @return array The members of the set copied to memory as an array.
     */
    function _asArray(AddressSet storage set) internal view returns (address[] memory array) {
        array = set.values;
    }

    /**
     * @dev Provides the storage pointer of the underlying array of value.
     * @dev DO NOT alter values via this pointer.
     * @dev ONLY use to minimize memory usage when passing a reference internally for gas efficiency.
     * @dev OR when passing the array as an external return.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @return values The members of the set copied to memory as an array.
     */
    function _values(AddressSet storage set) internal view returns (address[] storage values) {
        values = set.values;
    }

    error InvalidPageSize(uint256 start, uint256 end);

    function _range(AddressSet storage set, uint256 start, uint256 end) internal view returns (address[] memory array) {
        if (end < start) {
            revert InvalidPageSize(start, end);
        }
        uint256 setLen = set._length();
        // require();
        setLen._isValidIndex(start);
        // require();
        setLen._isValidIndex(end);
        uint256 returnLen = end - start + 1;
        array = new address[](returnLen);
        for (uint256 setCursor = start; setCursor <= end; setCursor++) {
            for (uint256 returnCursor = 0; returnCursor < returnLen; returnCursor++) {
                array[returnCursor] = set._index(setCursor);
            }
        }
    }

    function _sort(address[] memory array) internal pure returns (address[] memory) {
        bool swapped;
        for (uint256 i = 1; i < array.length; i++) {
            swapped = false;
            for (uint256 j = 0; j < array.length - i; j++) {
                address next = array[j + 1];
                address actual = array[j];
                if (next < actual) {
                    array[j] = next;
                    array[j + 1] = actual;
                    swapped = true;
                }
            }
            if (!swapped) {
                return array;
            }
        }

        return array;
    }

    function _sort(address[] memory _arr, uint256 unsortedLen) internal pure {
        if (unsortedLen == 0 || unsortedLen == 1) {
            return;
        }

        for (uint256 i = 0; i < unsortedLen - 1;) {
            if (_arr[i] > _arr[i + 1]) {
                (_arr[i], _arr[i + 1]) = (_arr[i + 1], _arr[i]);
            }
            unchecked {
                ++i;
            }
        }
        _sort(_arr, unsortedLen - 1);
    }
}
