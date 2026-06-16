// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {InvalidPageSize} from "@crane/contracts/GeneralErrors.sol";
import {BetterArrays as Arrays} from "@crane/contracts/utils/collections/BetterArrays.sol";

// tag::Bytes4Set[]
struct Bytes4Set {
    // 1-indexed to allow 0 to signify nonexistence
    mapping(bytes4 => uint256) indexes;
    // Values in set.
    bytes4[] values;
}
// end::Bytes4Set[]

// tag::Bytes4SetRepo[]
/**
 * @title Bytes4SetRepo - Struct and atomic operations for a set of bytes4 values.
 * @author cyotee doge <doge.cyotee>
 * @dev Distinct from OpenZeppelin to allow for operations upon an array of the same type.
 * @dev Pure struct-passing utility Repo (no own STORAGE_SLOT / _layout binding); functions take Bytes4Set storage directly.
 * @dev 1-indexed to allow 0 to signify nonexistence (in the `indexes` mapping).
 * @dev Used (via `using Bytes4SetRepo for Bytes4Set;`) across introspection (e.g. ERC165/ERC2535/ERC8109), comparators (Bytes4SetComparator), handlers, Create3Factory, registries, and other collection consumers.
 */
library Bytes4SetRepo {
    using Arrays for uint256;
    using Bytes4SetRepo for Bytes4Set;

    // tag::_index(Bytes4Set-uint256)[]
    /**
     * @dev Returns the value stored at the provided index (1-based).
     * @dev Will revert if the index is not used (via BetterArrays).
     * @param set The Bytes4Set storage struct upon which this function operates.
     * @param index The (1-based) index of the value to retrieve.
     * @return value The value stored under the provided index.
     */
    function _index(Bytes4Set storage set, uint256 index) internal view returns (bytes4 value) {
        set.values.length._isValidIndex(index);
        return set.values[index];
    }
    // end::_index(Bytes4Set-uint256)[]

    // tag::_indexOf(Bytes4Set-bytes4)[]
    /**
     * @dev Returns the index of the provided value.
     * @dev Will return 2**256-1 if the value is not present.
     * @dev Using underflow to prevent reversion if value is not present.
     * @param set The Bytes4Set storage struct upon which this function operates.
     * @param value The value of which to retrieve the index.
     * @return index The (1-based) index of the value (or max uint on absence).
     */
    function _indexOf(Bytes4Set storage set, bytes4 value) internal view returns (uint256 index) {
        unchecked {
            return set.indexes[value] - 1;
        }
    }
    // end::_indexOf(Bytes4Set-bytes4)[]

    // tag::_contains(Bytes4Set-bytes4)[]
    /**
     * @dev Returns boolean indicating if the value is present in the set.
     * @param set The Bytes4Set storage struct upon which this function operates.
     * @param value The value for which to check presence.
     * @return isPresent Boolean indicating presence of value in set.
     */
    function _contains(Bytes4Set storage set, bytes4 value) internal view returns (bool isPresent) {
        return set.indexes[value] != 0;
    }
    // end::_contains(Bytes4Set-bytes4)[]

    // tag::_length(Bytes4Set)[]
    /**
     * @dev Returns the length of the provided set.
     * @param set The Bytes4Set storage struct upon which this function operates.
     * @return length_ The "length", quantity of entries, of the provided set.
     */
    function _length(Bytes4Set storage set) internal view returns (uint256 length_) {
        return set.values.length;
    }
    // end::_length(Bytes4Set)[]

    // tag::_add(Bytes4Set-bytes4)[]
    /**
     * @dev Written to be idempotent.
     * @dev Sets care about ensuring desired state.
     * @dev Desired state is for the value to be present in set.
     * @dev If the value is present, desired state has been achieved.
     * @dev When the state change was achieved is irrelevant.
     * @dev If presence prior to addition is relevant, encapsulating logic should check for presence.
     * @param set The Bytes4Set storage struct upon which this function operates.
     * @param value The value to ensure is present in the provided set.
     * @return success Boolean indicating desired set state has been achieved.
     */
    function _add(Bytes4Set storage set, bytes4 value) internal returns (bool success) {
        if (!set._contains(value)) {
            set.values.push(value);
            set.indexes[value] = set.values.length;
        }
        return true;
    }
    // end::_add(Bytes4Set-bytes4)[]

    // tag::_add(Bytes4Set-bytes4[])[]
    /**
     * @dev Idempotently adds an array of values to the provided set.
     * @param set The Bytes4Set storage struct upon which this function operates.
     * @param values The array of values to ensure are present in the provided set.
     * @return success Boolean indicating desired set state has been achieved.
     */
    function _add(Bytes4Set storage set, bytes4[] memory values) internal returns (bool success) {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            set._add(values[iteration]);
        }
        return true;
    }
    // end::_add(Bytes4Set-bytes4[])[]

    // tag::_addAsc(Bytes4Set-bytes4)[]
    /**
     * @notice Insert a new bytes4 (or do nothing if already present)
     * @dev Keeps the `values` array sorted in ascending order.
     * @param set The Bytes4Set storage struct upon which this function operates.
     * @param value The bytes4 to insert into the set in ascending order.
     */
    function _addAsc(Bytes4Set storage set, bytes4 value) internal {
        if (set.indexes[value] != 0) {
            return; // already present
        }

        // Find the correct insertion point using binary search
        uint256 left = 1; // 1-indexed
        uint256 right = set.values.length;

        while (left <= right) {
            uint256 mid = (left + right) / 2;
            if (set.values[mid - 1] < value) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }
        // `left` is now the correct 1-indexed position

        set.values.push(bytes4(0)); // reserve space
        uint256 insertIdx = left - 1; // 0-indexed for array operations

        // Shift everything after the insertion point one position right
        for (uint256 i = set.values.length - 1; i > insertIdx; i--) {
            bytes4 moved = set.values[i - 1];
            set.values[i] = moved;
            set.indexes[moved] = i + 1; // update its index
        }

        // Insert the new value
        set.values[insertIdx] = value;
        set.indexes[value] = left;
    }
    // end::_addAsc(Bytes4Set-bytes4)[]

    // tag::_remove(Bytes4Set-bytes4)[]
    /**
     * @dev Written to be idempotent.
     * @dev Sets care about ensuring desired state.
     * @dev Desired state is for value to not be present in the set.
     * @dev If value is not present, desired state has been achieved.
     * @dev When the state change was achieved is irrelevant.
     * @dev If lack of presence prior to removal is relevant, encapsulating logic should check for lack of presence.
     * @param set The Bytes4Set storage struct upon which this function operates.
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
    // end::_remove(Bytes4Set-bytes4)[]

    // tag::_remove(Bytes4Set-bytes4[])[]
    /**
     * @dev Idempotently removes an array of values from the provided set.
     * @param set The Bytes4Set storage struct upon which this function operates.
     * @param values The array of values to ensure are not present in the provided set.
     */
    function _remove(Bytes4Set storage set, bytes4[] memory values) internal {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _remove(set, values[iteration]);
        }
    }
    // end::_remove(Bytes4Set-bytes4[])[]

    // tag::_removeAsc(Bytes4Set-bytes4)[]
    /**
     * @notice Remove a bytes4 while preserving ascending order
     * @param set The Bytes4Set storage struct upon which this function operates.
     * @param value The value to remove, reordering set to maintain ascending order.
     */
    function _removeAsc(Bytes4Set storage set, bytes4 value) internal {
        uint256 idx = set.indexes[value];
        if (idx == 0) return; // not present

        uint256 lastIndex = set.values.length;

        // Shift all elements after `idx-1` one position left
        for (uint256 i = idx; i < lastIndex; i++) {
            bytes4 nextVal = set.values[i];
            set.values[i - 1] = nextVal;
            set.indexes[nextVal] = i; // new 1-indexed position
        }

        // Clean up
        set.values.pop();
        delete set.indexes[value];
    }
    // end::_removeAsc(Bytes4Set-bytes4)[]

    // tag::_asArray(Bytes4Set)[]
    /**
     * @dev Copies the set into memory as an array.
     * @param set The Bytes4Set storage struct upon which this function operates.
     * @return array The members of the set copied to memory as an array.
     */
    function _asArray(Bytes4Set storage set) internal view returns (bytes4[] memory array) {
        array = set.values;
    }
    // end::_asArray(Bytes4Set)[]

    // tag::_values(Bytes4Set)[]
    /**
     * @dev Provides the storage pointer of the underlying array of value.
     * @dev DO NOT alter values via this pointer.
     * @dev ONLY use to minimize memory usage when passing a reference internally for gas efficiency.
     * @dev OR when passing the array as an external return.
     * @param set The Bytes4Set storage struct upon which this function operates.
     * @return values The members of the set copied to memory as an array.
     */
    function _values(Bytes4Set storage set) internal view returns (bytes4[] storage values) {
        values = set.values;
    }
    // end::_values(Bytes4Set)[]

    // tag::_range(Bytes4Set-uint256-uint256)[]
    /**
     * @dev Returns a range of values from the set as an array.
     * @param set The Bytes4Set storage struct upon which this function operates.
     * @param start The starting index of the range (inclusive, 1-based).
     * @param end The ending index of the range (inclusive, 1-based).
     * @return array The array of values in the specified range.
     */
    function _range(Bytes4Set storage set, uint256 start, uint256 end) internal view returns (bytes4[] memory array) {
        if (end < start) {
            revert InvalidPageSize(start, end);
        }
        uint256 setLen = set._length();
        setLen._isValidIndex(start);
        setLen._isValidIndex(end);
        uint256 returnLen = end - start + 1;
        array = new bytes4[](returnLen);
        uint256 returnCursor = 0;
        for (uint256 setCursor = start; setCursor <= end; setCursor++) {
            array[returnCursor] = set._index(setCursor);
            unchecked {
                ++returnCursor;
            }
        }
    }
    // end::_range(Bytes4Set-uint256-uint256)[]

    // tag::_sortAsc(Bytes4Set)[]
    /**
     * @notice Sort the set in ascending order in-place
     * @dev Fixes both `values` array and `indexes` mapping
     * @param set The Bytes4Set storage struct to sort.
     */
    function _sortAsc(Bytes4Set storage set) internal {
        uint256 len = set.values.length;
        if (len <= 1) return;

        // Step 1: Extract current values into memory array
        bytes4[] memory arr = new bytes4[](len);
        for (uint256 i = 0; i < len; i++) {
            arr[i] = set.values[i];
        }

        // Step 2: Sort the memory array (Insertion Sort - gas efficient for small/medium sizes)
        for (uint256 i = 1; i < len; i++) {
            bytes4 key = arr[i];
            uint256 j = i;
            while (j > 0 && arr[j - 1] > key) {
                arr[j] = arr[j - 1];
                j--;
            }
            arr[j] = key;
        }

        // Step 3: Write back sorted values and fix indexes
        for (uint256 i = 0; i < len; i++) {
            bytes4 val = arr[i];
            set.values[i] = val;
            set.indexes[val] = i + 1; // 1-indexed
        }
    }
    // end::_sortAsc(Bytes4Set)[]

    // tag::_quickSort(Bytes4Set)[]
    /**
     * @notice Sort the set in-place using QuickSort algorithm
     * @dev Fixes both `values` array and `indexes` mapping
     * @param set The Bytes4Set storage struct to sort.
     */
    function _quickSort(Bytes4Set storage set) internal {
        _quickSort(set, 0, int256(set.values.length) - 1);
    }
    // end::_quickSort(Bytes4Set)[]

    // tag::_quickSort(Bytes4Set-int256-int256)[]
    /**
     * @notice Internal QuickSort implementation
     * @param set The Bytes4Set storage struct to sort.
     * @param left The left index
     * @param right The right index
     */
    function _quickSort(Bytes4Set storage set, int256 left, int256 right) private {
        if (left >= right) return;

        bytes4[] storage values = set.values;
        int256 i = left;
        int256 j = right;
        bytes4 pivot = values[uint256(left + (right - left) / 2)];

        while (i <= j) {
            while (values[uint256(i)] < pivot) i++;
            while (values[uint256(j)] > pivot) j--;
            if (i <= j) {
                (values[uint256(i)], values[uint256(j)]) = (values[uint256(j)], values[uint256(i)]);
                set.indexes[values[uint256(i)]] = uint256(i + 1);
                set.indexes[values[uint256(j)]] = uint256(j + 1);
                i++;
                j--;
            }
        }

        if (left < j) _quickSort(set, left, j);
        if (i < right) _quickSort(set, i, right);
    }
    // end::_quickSort(Bytes4Set-int256-int256)[]

    // tag::_sort(bytes4[])[]
    /**
     * @dev Sorts an array of bytes4 in ascending order using Bubble Sort.
     * @param array The array of bytes4 to sort.
     * @return The sorted array of bytes4.
     */
    function _sort(bytes4[] memory array) internal pure returns (bytes4[] memory) {
        bool swapped;
        for (uint256 i = 1; i < array.length; i++) {
            swapped = false;
            for (uint256 j = 0; j < array.length - i; j++) {
                bytes4 next = array[j + 1];
                bytes4 actual = array[j];
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
    // end::_sort(bytes4[])[]

    // tag::_sort(bytes4[]-uint256)[]
    /**
     * @dev Helper function to recursively sort an array of bytes4 using Bubble Sort.
     * @param _arr The array of bytes4 to sort.
     * @param unsortedLen The length of the unsorted portion of the array.
     */
    function _sort(bytes4[] memory _arr, uint256 unsortedLen) internal pure {
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
    // end::_sort(bytes4[]-uint256)[]

    // tag::_wipeSet(Bytes4Set)[]
    /**
     * @dev Deletes all values and indexes from the set.
     * @dev Will provide the gas refund for setting a value to default.
     * @param set The Bytes4Set storage struct upon which this function operates.
     */
    function _wipeSet(Bytes4Set storage set) internal {
        for (uint256 cursor = set.values.length; cursor > 0; --cursor) {
            bytes4 value = set.values[cursor - 1];
            delete set.indexes[value];
            set.values.pop();
        }
    }
    // end::_wipeSet(Bytes4Set)[]
}
// end::Bytes4SetRepo[]
