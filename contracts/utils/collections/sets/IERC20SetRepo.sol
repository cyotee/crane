// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    Array
} from "../../collections/Array.sol";   
import {
    IERC20
} from "../../../tokens/erc20/interfaces/IERC20.sol";

struct IERC20Set {
    // 1-indexed to allow 0 to signify nonexistence
    mapping( IERC20 => uint256 ) indexes;
    // Values in set.
    IERC20[] values;
}

/**
 * @title IERC20SetRepo - Struct and atomic operations for a set of IERC20 values;
 * @author cyotee doge <doge.cyotee>
 * @dev Distinct from OpenZepplin to allow for operations upon an array of the same type.
 */
library IERC20SetRepo {

    using Array for uint256;
    using IERC20SetRepo for IERC20Set;

    /**
     * @dev "Binds" a struct to a storage slot.
     * @param storageRange The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(
        bytes32 storageRange
    ) internal pure returns(IERC20Set storage layout_) {
        // storageRange ^= STORAGE_RANGE_OFFSET;
        assembly{layout_.slot := storageRange}
    }

    /**
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param index The index of the value to retrieve.
     * @return value The value stored under the provided index.
     */
    function _index(
        IERC20Set storage set,
        uint index
    ) internal view returns (IERC20 value) {
        require(set.values.length._isValidIndex(index));
        return set.values[index];
    }

    /**
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value of which to retrieve the index.
     * @return index The index of the value.
     */
    function _indexOf(
        IERC20Set storage set,
        IERC20 value
    ) internal view returns (uint index) {
        unchecked {
            return set.indexes[value] - 1;
        }
    }

    /**
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value for which to check presence.
     * @return isPresent Boolean indicating presence of value in set.
     */
    function _contains(
        IERC20Set storage set,
        IERC20 value
    ) internal view returns (bool isPresent) {
        return set.indexes[value] != 0;
    }

    /**
     * @param set The storage pointer of the struct upon which this function should operate.
     * @return length The "length", quantity of entries, of the provided set.
     */
    function _length(
        IERC20Set storage set
    ) internal view returns (uint length) {
        return set.values.length;
    }

    /**
     * @dev Written to be idempotent.
     * @dev Sets care about ensuring desired state.
     * @dev Desired state is for IERC20 to be present in set.
     * @dev If IERC20 is present, desired state has been achieved.
     * @dev When the state change was achieved is irrelevant.
     * @dev If presence prior to addition is relevant, encapsulating logic should check for presence.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value to ensure is present in the provided set.
     * @return success Boolean indicating desired set state has been achieved.
     */
    function _add(
        IERC20Set storage set,
        IERC20 value
    ) internal returns (bool success) {
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
    function _add(
        IERC20Set storage set,
        IERC20[] memory values
    ) internal returns (bool success) {
        for(uint256 iteration = 0; iteration < values.length; iteration++) {
            _add(set, values[iteration]);
        }
        return true;
    }

    function _addExclusive(
        IERC20Set storage set,
        IERC20 value
    ) internal returns (bool success) {
        if (!_contains(set, value)) {
        set.values.push(value);
        set.indexes[value] = set.values.length;
        return true;
        }
        return false;
    }

    function _addExclusive(
        IERC20Set storage set,
        IERC20[] memory values
    ) internal returns (bool success) {
        for(uint256 iteration = 0; iteration < values.length; iteration++) {
        success = _addExclusive(set, values[iteration]);
        require(success == true, "IERC20Set: value already present.");
        }
    }

    /**
     * @dev Written to be idempotent.
     * @dev Sets care about ensuring desired state.
     * @dev Desired state is for IERC20 to not be present in the set.
     * @dev If IERC20 is not present, desired state has been achieved.
     * @dev When the state change was achieved is irrelevant.
     * @dev If lack of presence prior to addition is relevant, encapsulating logic should check for lakc of presence.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @param value The value to ensure is not present in the provided set.
     * @return success Boolean indicating desired set state has been achieved.
     */
    function _remove(
        IERC20Set storage set,
        IERC20 value
    ) internal returns (bool success) {
        uint valueIndex = set.indexes[value];

        if (valueIndex != 0) {
            uint index = valueIndex - 1;
            IERC20 last = set.values[set.values.length - 1];

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
    function _remove(
        IERC20Set storage set,
        IERC20[] memory values
    ) internal returns (bool success) {
        for(uint256 iteration = 0; iteration < values.length; iteration++) {
            _remove(set, values[iteration]);
        }
        success = true;
    }

    // /**
    //  * @dev Copies the set into memory as an array.
    //  * @param set The storage pointer of the struct upon which this function should operate.
    //  * @return array The members of the set copied to memory as an array.
    //  */
    // function _asArray(
    //     IERC20Set storage set
    // ) internal view returns (IERC20[] memory array) {
    //     array = set.values;
    // }

    /**
     * @dev Provides the storage pointer os the underlying array of value.
     * @dev DO NOT alter values via this pointer.
     * @dev ONLY use to minimize memory usage when passing a reference internally for gas efficiency.
     * @dev OR when passing the array as an external return.
     * @param set The storage pointer of the struct upon which this function should operate.
     * @return values The members of the set copied to memory as an array.
     */
    function _values(
        IERC20Set storage set
    ) internal view returns (IERC20[] storage values) {
        values = set.values;
    }

    error InvalidPageSize(uint256 start, uint256 end);

    function _range(
        IERC20Set storage set,
        uint256 start,
        uint256 end
    ) internal view returns(IERC20[] memory array) {
        if(end < start) {
            revert InvalidPageSize(start, end);
        }
        uint256 setLen = set._length();
        require(setLen._isValidIndex(start));
        require(setLen._isValidIndex(end));
        uint256 returnLen = end - start + 1;
        array = new IERC20[](returnLen);
        for(uint256 setCursor = start; setCursor <= end; setCursor++) {
            for(uint256 returnCursor = 0; returnCursor < returnLen; returnCursor++) {
                array[returnCursor] = set._index(setCursor);
            }
        }
    }

    function _sort(
        IERC20[] memory array
        // IERC20Set storage set
    ) internal pure returns (IERC20[] memory) {
        
        bool swapped;
        for (uint i = 1; i < array.length; i++) {
            swapped = false;
            for (uint j = 0; j < array.length - i; j++) {
                IERC20 next = array[j + 1];
                IERC20 actual = array[j];
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
        // Technically, this is reduntant because it sorts vias the memory pointer.
        return array;
    }
        
    function _sort(
        IERC20[] memory _arr,
        // IERC20Set storage set,
        uint256 unsortedLen
    ) internal {
        if (unsortedLen == 0 || unsortedLen == 1) {
            return;
        }

        for (uint256 i = 0; i < unsortedLen - 1; ) {
            if (address(_arr[i]) > address(_arr[i + 1])) {
                (_arr[i], _arr[i + 1]) = (_arr[i + 1], _arr[i]);
            }
            unchecked {
                ++i;
            }
        }
        _sort(_arr, unsortedLen - 1);
    }
 
    // function bubbleSort(uint256[] memory _arr, uint256 n) internal pure {
    //     //if n is zero or one, stop the sort 
    //     assembly {
    //         switch n
    //         case 0x00 {
    //             return(0, 0)
    //         }
    //         case 0x01 {
    //             return(0, 0)
    //         }
    //         for {
    //             let i := 0
    //         } lt(i, sub(n, 1)) {
    //             i := add(i, 0x01)
    //         } {
    //             /// The array _arr has been storred in memory already
    //             /// the first 32 byte of an array stored in memory is the length
    //             /// So to get to the first value of the array we have to add 32 bytes to it.
    //             /// Since we are in a lop, every iteration we need to add 32., e.g for the second add 64
    //             /// So to get the current value we have 32 * i + 32 → 32 * (i + 1) → which in
    //             /// assembly is mul(0x20, add(i, 1)) (simple brackets fractorisation)
    //             let x := mload(add(_arr, mul(0x20, add(i, 1))))
    //             /// to get  arr[i - 1], add 32 bytes to y
    //             let y := mload(add(add(_arr, mul(0x20, add(i, 1))), 0x20))
    //             if gt(x, y) {
    //                 mstore(add(add(_arr, mul(0x20, add(i, 1))), 0x20), x)
    //                 mstore(add(_arr, mul(0x20, add(i, 1))), y)
    //             }
    //         }
    //     }
    //     /// recurse
    //     bubbleSort(_arr, n - 1);
    // }
    
}