// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BetterArrays as Arrays} from "@crane/contracts/utils/collections/BetterArrays.sol";

// tag::UInt256Set[]
struct UInt256Set {
    // 1-indexed to allow 0 to signify nonexistence
    mapping(uint256 => uint256) indexes;
    uint256[] values;
    uint256 maxValue;
}

// end::UInt256Set[]

// tag::UInt256SetRepo[]
/**
 * @title UInt256SetRepo - Struct and atomic operations for a set of uint256 values.
 * @author cyotee doge <doge.cyotee>
 * @dev Distinct from OpenZeppelin to allow for operations upon an array of the same type.
 * @dev Pure struct-passing utility Repo (no own STORAGE_SLOT / _layout binding); functions take UInt256Set storage directly.
 * @dev 1-indexed to allow 0 to signify nonexistence (in the `indexes` mapping).
 * @dev Tracks the largest value seen (via `maxValue`); note removals do not decrease it per preserved logic.
 * @dev Used (via `using UInt256SetRepo for UInt256Set;`) across comparators, handlers, and other collection consumers.
 */
library UInt256SetRepo {
    using Arrays for uint256;
    using UInt256SetRepo for UInt256Set;

    // tag::_index(UInt256Set-uint256)[]
    /**
     * @dev Returns the value stored at the provided index (1-based).
     * @dev Will revert if the index is not used (via BetterArrays).
     * @param set The UInt256Set storage struct upon which this function operates.
     * @param index The (1-based) index of the value to retrieve.
     * @return value The value stored under the provided index.
     */
    function _index(UInt256Set storage set, uint256 index) internal view returns (uint256) {
        set.values.length._isValidIndex(index);
        return set.values[index];
    }

    // end::_index(UInt256Set-uint256)[]

    // tag::_indexOf(UInt256Set-uint256)[]
    /**
     * @dev Returns the index of the provided value.
     * @dev Will return 2**256-1 if the value is not present.
     * @dev Using underflow to prevent reversion if value is not present.
     * @param set The UInt256Set storage struct upon which this function operates.
     * @param value The value of which to retrieve the index.
     * @return index The (1-based) index of the value (or max uint on absence).
     */
    function _indexOf(UInt256Set storage set, uint256 value) internal view returns (uint256) {
        unchecked {
            return set.indexes[value] - 1;
        }
    }

    // end::_indexOf(UInt256Set-uint256)[]

    // tag::_contains(UInt256Set-uint256)[]
    /**
     * @dev Returns boolean indicating if the value is present in the set.
     * @param set The UInt256Set storage struct upon which this function operates.
     * @param value The value for which to check presence.
     * @return isPresent Boolean indicating presence of value in set.
     */
    function _contains(UInt256Set storage set, uint256 value) internal view returns (bool) {
        return set.indexes[value] != 0;
    }

    // end::_contains(UInt256Set-uint256)[]

    // tag::_length(UInt256Set)[]
    /**
     * @dev Returns the length of the provided set.
     * @param set The UInt256Set storage struct upon which this function operates.
     * @return length_ The "length", quantity of entries, of the provided set.
     */
    function _length(UInt256Set storage set) internal view returns (uint256) {
        return set.values.length;
    }

    // end::_length(UInt256Set)[]

    // tag::_add(UInt256Set-uint256)[]
    /**
     * @dev Written to be idempotent.
     * @dev Sets care about ensuring desired state.
     * @dev Desired state is for the value to be present in set.
     * @dev If the value is present, desired state has been achieved.
     * @dev When the state change was achieved is irrelevant.
     * @dev If presence prior to addition is relevant, encapsulating logic should check for presence.
     * @param set The UInt256Set storage struct upon which this function operates.
     * @param value The value to ensure is present in the provided set.
     * @return success Boolean indicating desired set state has been achieved.
     */
    function _add(UInt256Set storage set, uint256 value) internal returns (bool) {
        if (!_contains(set, value)) {
            set.values.push(value);
            set.indexes[value] = set.values.length;
            if (set.maxValue < value) {
                set.maxValue = value;
            }
        }
        return true;
    }

    // end::_add(UInt256Set-uint256)[]

    // tag::_add(UInt256Set-uint256[])[]
    /**
     * @dev Idempotently adds an array of values to the provided set.
     * @param set The UInt256Set storage struct upon which this function operates.
     * @param values The array of values to ensure are present in the provided set.
     * @return success Boolean indicating desired set state has been achieved.
     */
    function _add(UInt256Set storage set, uint256[] memory values) internal returns (bool success) {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _add(set, values[iteration]);
        }
        success = true;
    }

    // end::_add(UInt256Set-uint256[])[]

    // tag::_remove(UInt256Set-uint256)[]
    /**
     * @dev Written to be idempotent.
     * @dev Sets care about ensuring desired state.
     * @dev Desired state is for value to not be present in the set.
     * @dev If value is not present, desired state has been achieved.
     * @dev When the state change was achieved is irrelevant.
     * @dev If lack of presence prior to removal is relevant, encapsulating logic should check for lack of presence.
     * @param set The UInt256Set storage struct upon which this function operates.
     * @param value The value to ensure is not present in the provided set.
     */
    function _remove(UInt256Set storage set, uint256 value) internal returns (bool) {
        uint256 valueIndex = set.indexes[value];

        if (valueIndex != 0) {
            uint256 index = valueIndex - 1;
            uint256 last = set.values[set.values.length - 1];

            // move last value to now-vacant index

            set.values[index] = last;
            set.indexes[last] = index + 1;

            // clear last index

            set.values.pop();
            delete set.indexes[value];
        }
        return true;
    }

    // end::_remove(UInt256Set-uint256)[]

    // tag::_remove(UInt256Set-uint256[])[]
    /**
     * @dev Idempotently removes an array of values to the provided set.
     * @param set The UInt256Set storage struct upon which this function operates.
     * @param values The array of values to ensure are not present in the provided set.
     */
    function _remove(UInt256Set storage set, uint256[] memory values) internal returns (bool success) {
        for (uint256 iteration = 0; iteration < values.length; iteration++) {
            _remove(set, values[iteration]);
        }
        success = true;
    }

    // end::_remove(UInt256Set-uint256[])[]

    // tag::_asArray(UInt256Set)[]
    /**
     * @dev Copies the set into memory as an array.
     * @param set The UInt256Set storage struct upon which this function operates.
     * @return array The members of the set copied to memory as an array.
     */
    function _asArray(UInt256Set storage set) internal view returns (uint256[] storage array) {
        array = set.values;
    }

    // end::_asArray(UInt256Set)[]

    // tag::_values(UInt256Set)[]
    /**
     * @dev Provides the storage pointer of the underlying array of value.
     * @dev DO NOT alter values via this pointer.
     * @dev ONLY use to minimize memory usage when passing a reference internally for gas efficiency.
     * @dev OR when passing the array as an external return.
     * @param set The UInt256Set storage struct upon which this function operates.
     * @return values The members of the set copied to memory as an array.
     */
    function _values(UInt256Set storage set) internal view returns (uint256[] storage values) {
        values = set.values;
    }

    // end::_values(UInt256Set)[]

    // tag::_max(UInt256Set)[]
    /**
     * @dev Returns the largest value contained (note: preserved logic; maxValue only increases, removals do not recompute).
     * @param set The UInt256Set storage struct upon which this function operates.
     * @return maxValue The largest value contained in the provided set.
     */
    function _max(UInt256Set storage set) internal view returns (uint256 maxValue) {
        maxValue = set.maxValue;
    }
    // end::_max(UInt256Set)[]
}
// end::UInt256SetRepo[]
