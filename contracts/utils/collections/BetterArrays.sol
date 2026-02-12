// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Solady                                   */
/* -------------------------------------------------------------------------- */

import {LibSort} from "@crane/contracts/solady/utils/LibSort.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Panic} from "@crane/contracts/utils/Panic.sol";

/**
 * @title BetterArrays - Array Standard operations for all arrays.
 * @author cyotee doge <doge.cyotee>
 * @dev Provides array utilities including sorting, binary search, and unsafe access.
 *      Uses Solady's LibSort for gas-efficient sorting operations.
 */
library BetterArrays {
    /* ---------------------------------------------------------------------- */
    /*                              Storage Slots                             */
    /* ---------------------------------------------------------------------- */

    /// @dev Storage slot pointer for address values
    struct AddressSlot {
        address value;
    }

    /// @dev Storage slot pointer for bytes32 values
    struct Bytes32Slot {
        bytes32 value;
    }

    /// @dev Storage slot pointer for uint256 values
    struct Uint256Slot {
        uint256 value;
    }

    /// @dev Storage slot pointer for bytes values
    struct BytesSlot {
        bytes value;
    }

    /// @dev Storage slot pointer for string values
    struct StringSlot {
        string value;
    }

    /* ---------------------------------------------------------------------- */
    /*                             Sort Functions                             */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Sort an array of uint256 (in memory) following the provided comparator function.
     * @param array The array to sort in place
     * @param comp Comparator function
     * @return The sorted array
     */
    function _sort(uint256[] memory array, function(uint256, uint256) pure returns (bool) comp)
        internal
        pure
        returns (uint256[] memory)
    {
        // Solady's sort is ascending by default, we need custom implementation for custom comparators
        _quickSort(array, comp);
        return array;
    }

    /**
     * @dev Sort an array of uint256 in ascending order.
     * @param array The array to sort in place
     * @return The sorted array
     */
    function _sort(uint256[] memory array) internal pure returns (uint256[] memory) {
        LibSort.sort(array);
        return array;
    }

    /**
     * @dev Sort an array of address (in memory) following the provided comparator function.
     * @param array The array to sort in place
     * @param comp Comparator function
     * @return The sorted array
     */
    function _sort(address[] memory array, function(address, address) pure returns (bool) comp)
        internal
        pure
        returns (address[] memory)
    {
        _sort(_castToUint256Array(array), _castToUint256Comp(comp));
        return array;
    }

    /**
     * @dev Sort an array of address in ascending order.
     * @param array The array to sort in place
     * @return The sorted array
     */
    function _sort(address[] memory array) internal pure returns (address[] memory) {
        LibSort.sort(array);
        return array;
    }

    /**
     * @dev Sort an array of bytes32 (in memory) following the provided comparator function.
     * @param array The array to sort in place
     * @param comp Comparator function
     * @return The sorted array
     */
    function _sort(bytes32[] memory array, function(bytes32, bytes32) pure returns (bool) comp)
        internal
        pure
        returns (bytes32[] memory)
    {
        _sort(_castToUint256Array(array), _castToUint256Comp(comp));
        return array;
    }

    /**
     * @dev Sort an array of bytes32 in ascending order.
     * @param array The array to sort in place
     * @return The sorted array
     */
    function _sort(bytes32[] memory array) internal pure returns (bytes32[] memory) {
        LibSort.sort(array);
        return array;
    }

    /* ---------------------------------------------------------------------- */
    /*                         Binary Search Functions                        */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     * @param array Sorted array to search
     * @param element Value to search for
     * @return Index of first element >= target
     */
    function _findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        if (high == 0) {
            return 0;
        }

        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return low;
    }

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is returned.
     * @param array Sorted array to search
     * @param element Value to search for
     * @return Index of first element >= target
     */
    function _lowerBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (array[mid] < element) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }

        return low;
    }

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value strictly greater than `element`. If no such index exists (i.e. all
     * values in the array are less than or equal to `element`), the array length is returned.
     * @param array Sorted array to search
     * @param element Value to search for
     * @return Index of first element > target
     */
    function _upperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return low;
    }

    /**
     * @dev Same as lowerBound but for memory arrays.
     * @param array Sorted memory array to search
     * @param element Value to search for
     * @return Index of first element >= target
     */
    function _lowerBoundMemory(uint256[] memory array, uint256 element) internal pure returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (array[mid] < element) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }

        return low;
    }

    /**
     * @dev Same as upperBound but for memory arrays.
     * @param array Sorted memory array to search
     * @param element Value to search for
     * @return Index of first element > target
     */
    function _upperBoundMemory(uint256[] memory array, uint256 element) internal pure returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return low;
    }

    /* ---------------------------------------------------------------------- */
    /*                         Unsafe Access Functions                        */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function _unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (AddressSlot storage slot) {
        assembly {
            mstore(0, arr.slot)
            slot.slot := add(keccak256(0, 0x20), pos)
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function _unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (Bytes32Slot storage slot) {
        assembly {
            mstore(0, arr.slot)
            slot.slot := add(keccak256(0, 0x20), pos)
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function _unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (Uint256Slot storage slot) {
        assembly {
            mstore(0, arr.slot)
            slot.slot := add(keccak256(0, 0x20), pos)
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function _unsafeAccess(bytes[] storage arr, uint256 pos) internal pure returns (BytesSlot storage slot) {
        assembly {
            mstore(0, arr.slot)
            slot.slot := add(keccak256(0, 0x20), pos)
        }
    }

    /**
     * @dev Access an array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function _unsafeAccess(string[] storage arr, uint256 pos) internal pure returns (StringSlot storage slot) {
        assembly {
            mstore(0, arr.slot)
            slot.slot := add(keccak256(0, 0x20), pos)
        }
    }

    /**
     * @dev Access a memory array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function _unsafeMemoryAccess(address[] memory arr, uint256 pos) internal pure returns (address res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }

    /**
     * @dev Access a memory array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function _unsafeMemoryAccess(bytes32[] memory arr, uint256 pos) internal pure returns (bytes32 res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }

    /**
     * @dev Access a memory array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function _unsafeMemoryAccess(uint256[] memory arr, uint256 pos) internal pure returns (uint256 res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }

    /**
     * @dev Access a memory array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function _unsafeMemoryAccess(bytes[] memory arr, uint256 pos) internal pure returns (bytes memory res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }

    /**
     * @dev Access a memory array in an "unsafe" way. Skips solidity "index-out-of-range" check.
     * WARNING: Only use if you are certain `pos` is lower than the array length.
     */
    function _unsafeMemoryAccess(string[] memory arr, uint256 pos) internal pure returns (string memory res) {
        assembly {
            res := mload(add(add(arr, 0x20), mul(pos, 0x20)))
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                       Unsafe Set Length Functions                      */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Sets the array length. WARNING: This is an unsafe operation that will not verify
     * that the new length is within bounds and will not clean up storage.
     */
    function _unsafeSetLength(address[] storage array, uint256 len) internal {
        assembly {
            sstore(array.slot, len)
        }
    }

    /**
     * @dev Sets the array length. WARNING: This is an unsafe operation that will not verify
     * that the new length is within bounds and will not clean up storage.
     */
    function _unsafeSetLength(bytes32[] storage array, uint256 len) internal {
        assembly {
            sstore(array.slot, len)
        }
    }

    /**
     * @dev Sets the array length. WARNING: This is an unsafe operation that will not verify
     * that the new length is within bounds and will not clean up storage.
     */
    function _unsafeSetLength(uint256[] storage array, uint256 len) internal {
        assembly {
            sstore(array.slot, len)
        }
    }

    /**
     * @dev Sets the array length. WARNING: This is an unsafe operation that will not verify
     * that the new length is within bounds and will not clean up storage.
     */
    function _unsafeSetLength(bytes[] storage array, uint256 len) internal {
        assembly {
            sstore(array.slot, len)
        }
    }

    /**
     * @dev Sets the array length. WARNING: This is an unsafe operation that will not verify
     * that the new length is within bounds and will not clean up storage.
     */
    function _unsafeSetLength(string[] storage array, uint256 len) internal {
        assembly {
            sstore(array.slot, len)
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                              Custom Logic                              */
    /* ---------------------------------------------------------------------- */

    /**
     * @param length The length of the array for which `invalidIndex` is out of bounds.
     * @param invalidIndex The index that is out of bounds for the array.
     */
    error IndexOutOfBounds(uint256 length, uint256 invalidIndex, uint256 errorCode);

    error EndBeforeStart(uint256 start, uint256 end);

    /**
     * @dev Reverts with custom error if provided index would be out of bounds of provided length.
     * @dev Facilitates usage of custom error within a require statement.
     * @param length The length of the array against which the index is being checked.
     * @param index The index to confirm is contained within the provided length.
     */
    function _isValidIndex(uint256 length, uint256 index) internal pure returns (bool isValid) {
        if (length <= index) {
            revert BetterArrays.IndexOutOfBounds(length, index, Panic.ARRAY_OUT_OF_BOUNDS);
        }
        return true;
    }

    /**
     * @dev Copies an array to a new array of the specified length.
     * @dev New length must be greater than or equal to the original length.
     * @param values The array to be copied to a new array of greater length.
     * @param newLength The length of the new array.
     */
    function _toLength(address[] memory values, uint256 newLength) internal pure returns (address[] memory newValues) {
        if (newLength < values.length) {
            revert BetterArrays.EndBeforeStart(values.length, newLength);
        }
        newValues = new address[](newLength);
        for (uint256 cursor = 0; cursor < values.length; cursor++) {
            newValues[cursor] = values[cursor];
        }
    }

    /**
     * @dev Copies a fixed-size array to a new dynamic array of the specified length.
     */
    function _toLength(address[5] memory values, uint256 newLength) internal pure returns (address[] memory newValues) {
        if (newLength < values.length) {
            revert BetterArrays.EndBeforeStart(values.length, newLength);
        }
        newValues = new address[](newLength);
        for (uint256 cursor = 0; cursor < values.length; cursor++) {
            newValues[cursor] = values[cursor];
        }
    }

    /**
     * @dev Copies a fixed-size array to a new dynamic array of the specified length.
     */
    function _toLength(address[10] memory values, uint256 newLength)
        internal
        pure
        returns (address[] memory newValues)
    {
        if (newLength < values.length) {
            revert BetterArrays.EndBeforeStart(values.length, newLength);
        }
        newValues = new address[](newLength);
        for (uint256 cursor = 0; cursor < values.length; cursor++) {
            newValues[cursor] = values[cursor];
        }
    }

    /**
     * @dev Copies a fixed-size array to a new dynamic array of the specified length.
     */
    function _toLength(address[100] memory values, uint256 newLength)
        internal
        pure
        returns (address[] memory newValues)
    {
        if (newLength < values.length) {
            revert BetterArrays.EndBeforeStart(values.length, newLength);
        }
        newValues = new address[](newLength);
        for (uint256 cursor = 0; cursor < values.length; cursor++) {
            newValues[cursor] = values[cursor];
        }
    }

    /**
     * @dev Copies a fixed-size array to a new dynamic array of the specified length.
     */
    function _toLength(address[1000] memory values, uint256 newLength)
        internal
        pure
        returns (address[] memory newValues)
    {
        if (newLength < values.length) {
            revert BetterArrays.EndBeforeStart(values.length, newLength);
        }
        newValues = new address[](newLength);
        for (uint256 cursor = 0; cursor < values.length; cursor++) {
            newValues[cursor] = values[cursor];
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                           Private Helpers                              */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev QuickSort implementation for custom comparators
     */
    function _quickSort(uint256[] memory array, function(uint256, uint256) pure returns (bool) comp) private pure {
        if (array.length <= 1) return;
        _quickSortInner(array, 0, array.length - 1, comp);
    }

    function _quickSortInner(
        uint256[] memory array,
        uint256 left,
        uint256 right,
        function(uint256, uint256) pure returns (bool) comp
    ) private pure {
        if (left >= right) return;

        uint256 pivot = array[(left + right) / 2];
        uint256 i = left;
        uint256 j = right;

        while (i <= j) {
            while (comp(array[i], pivot)) i++;
            while (comp(pivot, array[j])) j--;
            if (i <= j) {
                (array[i], array[j]) = (array[j], array[i]);
                i++;
                if (j > 0) j--;
            }
        }

        if (left < j) _quickSortInner(array, left, j, comp);
        if (i < right) _quickSortInner(array, i, right, comp);
    }

    /// @dev Cast address array to uint256 array
    function _castToUint256Array(address[] memory input) private pure returns (uint256[] memory output) {
        assembly {
            output := input
        }
    }

    /// @dev Cast bytes32 array to uint256 array
    function _castToUint256Array(bytes32[] memory input) private pure returns (uint256[] memory output) {
        assembly {
            output := input
        }
    }

    /// @dev Cast address comparator to uint256 comparator
    function _castToUint256Comp(
        function(address, address) pure returns (bool) input
    ) private pure returns (function(uint256, uint256) pure returns (bool) output) {
        assembly {
            output := input
        }
    }

    /// @dev Cast bytes32 comparator to uint256 comparator
    function _castToUint256Comp(
        function(bytes32, bytes32) pure returns (bool) input
    ) private pure returns (function(uint256, uint256) pure returns (bool) output) {
        assembly {
            output := input
        }
    }
}
