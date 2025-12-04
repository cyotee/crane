// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {InvalidPageSize} from "@crane/contracts/GeneralErrors.sol";
import {BetterArrays as Arrays} from "@crane/contracts/utils/collections/BetterArrays.sol";

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
     * @dev Returns the value stored at the provided index.
     * @dev Will return a default value if the index is not used.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param index The index of the value to retrieve.
     * @return value The value stored under the provided index.
     */
    function _index(AddressSet storage set, uint256 index) internal view returns (address value) {
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
    function _indexOf(AddressSet storage set, address value) internal view returns (uint256 index) {
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
    function _contains(AddressSet storage set, address value) internal view returns (bool isPresent) {
        return set.indexes[value] != 0;
    }

    /**
     * @dev Returns the length of the provided set.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @return length_ The "length", quantity of entries, of the provided set.
     */
    function _length(AddressSet storage set) internal view returns (uint256 length_) {
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
     * @return success Boolean indicating desired set state has been achieved.
     */
    function _add(AddressSet storage set, address value) internal returns (bool success) {
        if (!set._contains(value)) {
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
            set._add(values[iteration]);
        }
        return true;
    }

    /**
     * @notice Insert a new address (or do nothing if already present)
     * @dev Keeps the `values` array sorted in ascending order
     * @param set The set upon which this function operates.
     * @param addr The address to insert into the set in ascending order.
     */
    function _addAsc(AddressSet storage set, address addr) internal {
        if (set.indexes[addr] != 0) {
            return; // already present
        }

        // Find the correct insertion point using binary search
        uint256 left = 1; // 1-indexed
        uint256 right = set.values.length;

        while (left <= right) {
            uint256 mid = (left + right) / 2;
            if (set.values[mid - 1] < addr) {
                left = mid + 1;
            } else {
                right = mid - 1;
            }
        }
        // `left` is now the correct 1-indexed position

        set.values.push(address(0)); // reserve space
        uint256 insertIdx = left - 1; // 0-indexed for array operations

        // Shift everything after the insertion point one position right
        for (uint256 i = set.values.length - 1; i > insertIdx; i--) {
            address moved = set.values[i - 1];
            set.values[i] = moved;
            set.indexes[moved] = i + 1; // update its index
        }

        // Insert the new value
        set.values[insertIdx] = addr;
        set.indexes[addr] = left;
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
    function _remove(AddressSet storage set, address value) internal {
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
    }

    /**
     * @dev Idempotently removes an array of values to the provided set.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param values The array of values to ensure are not present in the provided set.
     */
    function _remove(AddressSet storage set, address[] memory values) internal {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _remove(set, values[iteration]);
        }
    }

    /**
     * @notice Remove an address while preserving ascending order
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value to remove, reordering set to maintain ascending order.
     */
    function _removeAsc(AddressSet storage set, address value) internal {
        uint256 idx = set.indexes[value];
        if (idx == 0) return; // not present

        uint256 lastIndex = set.values.length;

        // Shift all elements after `idx-1` one position left
        for (uint256 i = idx; i < lastIndex; i++) {
            address nextAddr = set.values[i];
            set.values[i - 1] = nextAddr;
            set.indexes[nextAddr] = i; // new 1-indexed position
        }

        // Clean up
        set.values.pop();
        delete set.indexes[value];
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

    /**
     * @dev Returns a range of values from the set as an array.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param start The starting index of the range (inclusive).
     * @param end The ending index of the range (inclusive).
     * @return array The array of values in the specified range.
     */
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
        uint256 returnCursor = 0;
        for (uint256 setCursor = start; setCursor <= end; setCursor++) {
            array[returnCursor] = set._index(setCursor);
            unchecked {
                ++returnCursor;
            }
        }
    }

    /**
     * @notice Sort the set in ascending order in-place
     * @dev Fixes both `values` array and `indexes` mapping
     * @param set The set to sort
     */
    function _sortAsc(AddressSet storage set) internal {
        uint256 len = set.values.length;
        if (len <= 1) return;

        // Step 1: Extract current values into memory array
        address[] memory arr = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            arr[i] = set.values[i];
        }

        // Step 2: Sort the memory array (Insertion Sort - gas efficient for small/medium sizes)
        // You can replace with quicksort if you prefer, but insertion sort is simpler and fine up to ~500 elements
        for (uint256 i = 1; i < len; i++) {
            address key = arr[i];
            uint256 j = i;
            while (j > 0 && arr[j - 1] > key) {
                arr[j] = arr[j - 1];
                j--;
            }
            arr[j] = key;
        }

        // Step 3: Write back sorted values and fix indexes
        for (uint256 i = 0; i < len; i++) {
            address addr = arr[i];
            set.values[i] = addr;
            set.indexes[addr] = i + 1; // 1-indexed
        }
    }

    /**
     * @notice Sort the set in-place using QuickSort algorithm
     * @dev Fixes both `values` array and `indexes` mapping
     * @param set The set to sort
     */
    function _quickSort(AddressSet storage set) internal {
        _quickSort(set, 0, int256(set.values.length) - 1);
    }

    /**
     * @notice Internal QuickSort implementation
     * @param set The set to sort
     * @param left The left index
     * @param right The right index
     */
    function _quickSort(AddressSet storage set, int256 left, int256 right) private {
        if (left >= right) return;

        address[] storage values = set.values;
        int256 i = left;
        int256 j = right;
        address pivot = values[uint256(left + (right - left) / 2)];

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

    /**
     * @dev Sorts an array of addresses in ascending order using Bubble Sort.
     * @param array The array of addresses to sort.
     * @return The sorted array of addresses.
     */
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

    /**
     * @dev Helper function to recursively sort an array of addresses using Bubble Sort.
     * @param _arr The array of addresses to sort.
     * @param unsortedLen The length of the unsorted portion of the array.
     */
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
