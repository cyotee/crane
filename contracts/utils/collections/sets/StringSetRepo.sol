// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {InvalidPageSize} from "@crane/contracts/GeneralErrors.sol";
import {BetterArrays as Arrays} from "@crane/contracts/utils/collections/BetterArrays.sol";

// tag::StringSet[]
struct StringSet {
    // 1-indexed to allow 0 to signify nonexistence
    mapping(string => uint256) indexes;
    // Values in set.
    string[] values;
}
// end::StringSet[]

// tag::StringSetRepo[]
/**
 * @title StringSetRepo - Struct and atomic operations for a set of string values.
 * @author cyotee doge <doge.cyotee>
 * @dev Distinct from OpenZeppelin to allow for operations upon an array of the same type.
 * @dev Pure struct-passing utility Repo (no own STORAGE_SLOT / _layout binding); functions take StringSet storage directly.
 * @dev 1-indexed to allow 0 to signify nonexistence (in the `indexes` mapping).
 * @dev Used (via `using StringSetRepo for StringSet;`) across comparators (StringSetComparator), handlers, and other collection consumers.
 */
library StringSetRepo {
    using Arrays for uint256;
    using StringSetRepo for StringSet;

    // tag::_index(StringSet-uint256)[]
    /**
     * @dev Returns the value stored at the provided index (1-based).
     * @dev Will revert if the index is not used (via BetterArrays).
     * @param set The StringSet storage struct upon which this function operates.
     * @param index The (1-based) index of the value to retrieve.
     * @return value The value stored under the provided index.
     */
    function _index(StringSet storage set, uint256 index) internal view returns (string memory value) {
        set.values.length._isValidIndex(index);
        return set.values[index];
    }
    // end::_index(StringSet-uint256)[]

    // tag::_indexOf(StringSet-string)[]
    /**
     * @dev Returns the index of the provided value.
     * @dev Will return 2**256-1 if the value is not present.
     * @dev Using underflow to prevent reversion if value is not present.
     * @param set The StringSet storage struct upon which this function operates.
     * @param value The value of which to retrieve the index.
     * @return index The (1-based) index of the value (or max uint on absence).
     */
    function _indexOf(StringSet storage set, string memory value) internal view returns (uint256 index) {
        unchecked {
            return set.indexes[value] - 1;
        }
    }
    // end::_indexOf(StringSet-string)[]

    // tag::_contains(StringSet-string)[]
    /**
     * @dev Returns boolean indicating if the value is present in the set.
     * @param set The StringSet storage struct upon which this function operates.
     * @param value The value for which to check presence.
     * @return isPresent Boolean indicating presence of value in set.
     */
    function _contains(StringSet storage set, string memory value) internal view returns (bool isPresent) {
        return set.indexes[value] != 0;
    }
    // end::_contains(StringSet-string)[]

    // tag::_length(StringSet)[]
    /**
     * @dev Returns the length of the provided set.
     * @param set The StringSet storage struct upon which this function operates.
     * @return length_ The "length", quantity of entries, of the provided set.
     */
    function _length(StringSet storage set) internal view returns (uint256 length_) {
        return set.values.length;
    }
    // end::_length(StringSet)[]

    // tag::_add(StringSet-string)[]
    /**
     * @dev Written to be idempotent.
     * @dev Sets care about ensuring desired state.
     * @dev Desired state is for the value to be present in set.
     * @dev If the value is present, desired state has been achieved.
     * @dev When the state change was achieved is irrelevant.
     * @dev If presence prior to addition is relevant, encapsulating logic should check for presence.
     * @param set The StringSet storage struct upon which this function operates.
     * @param value The value to ensure is present in the provided set.
     * @return success Boolean indicating desired set state has been achieved.
     */
    function _add(StringSet storage set, string memory value) internal returns (bool success) {
        if (!set._contains(value)) {
            set.values.push(value);
            set.indexes[value] = set.values.length;
        }
        return true;
    }
    // end::_add(StringSet-string)[]

    // tag::_add(StringSet-string[])[]
    /**
     * @dev Idempotently adds an array of values to the provided set.
     * @param set The StringSet storage struct upon which this function operates.
     * @param values The array of values to ensure are present in the provided set.
     * @return success Boolean indicating desired set state has been achieved.
     */
    function _add(StringSet storage set, string[] memory values) internal returns (bool success) {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            set._add(values[iteration]);
        }
        return true;
    }
    // end::_add(StringSet-string[])[]

    // tag::_remove(StringSet-string)[]
    /**
     * @dev Written to be idempotent.
     * @dev Sets care about ensuring desired state.
     * @dev Desired state is for value to not be present in the set.
     * @dev If value is not present, desired state has been achieved.
     * @dev When the state change was achieved is irrelevant.
     * @dev If lack of presence prior to removal is relevant, encapsulating logic should check for lack of presence.
     * @param set The StringSet storage struct upon which this function operates.
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
    // end::_remove(StringSet-string)[]

    // tag::_remove(StringSet-string[])[]
    /**
     * @dev Idempotently removes an array of values from the provided set.
     * @param set The StringSet storage struct upon which this function operates.
     * @param values The array of values to ensure are not present in the provided set.
     */
    function _remove(StringSet storage set, string[] memory values) internal {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _remove(set, values[iteration]);
        }
    }
    // end::_remove(StringSet-string[])[]

    // tag::_asArray(StringSet)[]
    /**
     * @dev Copies the set into memory as an array.
     * @param set The StringSet storage struct upon which this function operates.
     * @return array The members of the set copied to memory as an array.
     */
    function _asArray(StringSet storage set) internal view returns (string[] memory array) {
        array = set.values;
    }
    // end::_asArray(StringSet)[]

    // tag::_values(StringSet)[]
    /**
     * @dev Provides the storage pointer of the underlying array of value.
     * @dev DO NOT alter values via this pointer.
     * @dev ONLY use to minimize memory usage when passing a reference internally for gas efficiency.
     * @dev OR when passing the array as an external return.
     * @param set The StringSet storage struct upon which this function operates.
     * @return values The members of the set copied to memory as an array.
     */
    function _values(StringSet storage set) internal view returns (string[] storage values) {
        values = set.values;
    }
    // end::_values(StringSet)[]

    // tag::_range(StringSet-uint256-uint256)[]
    /**
     * @dev Returns a range of values from the set as an array.
     * @param set The StringSet storage struct upon which this function operates.
     * @param start The starting index of the range (inclusive, 1-based).
     * @param end The ending index of the range (inclusive, 1-based).
     * @return array The array of values in the specified range.
     */
    function _range(StringSet storage set, uint256 start, uint256 end) internal view returns (string[] memory array) {
        if (end < start) {
            revert InvalidPageSize(start, end);
        }
        uint256 setLen = set._length();
        setLen._isValidIndex(start);
        setLen._isValidIndex(end);
        uint256 returnLen = end - start + 1;
        array = new string[](returnLen);
        uint256 returnCursor = 0;
        for (uint256 setCursor = start; setCursor <= end; setCursor++) {
            array[returnCursor] = set._index(setCursor);
            unchecked {
                ++returnCursor;
            }
        }
    }
    // end::_range(StringSet-uint256-uint256)[]
}
// end::StringSetRepo[]
