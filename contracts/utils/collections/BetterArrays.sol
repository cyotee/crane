// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Forge                                   */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {Arrays} from "@openzeppelin/contracts/utils/Arrays.sol";
import {Panic} from "@openzeppelin/contracts/utils/Panic.sol";
import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

/**
 * @title Array Standard operations for all arrays.
 * @author cyotee doge <doge.cyotee>
 */
library BetterArrays {
    using Arrays for address[];
    using Arrays for bytes[];
    using Arrays for bytes32[];
    using Arrays for string[];
    using Arrays for uint256[];

    /* ---------------------------------------------------------------------- */
    /*             Wrapper function to support drop-in replacement            */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Wrapper function for the OZ Arrays.sort function.
     */
    function _sort(uint256[] memory array, function(uint256, uint256) pure returns (bool) comp)
        internal
        pure
        returns (uint256[] memory)
    {
        return array.sort(comp);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.sort function.
     */
    function _sort(uint256[] memory array) internal pure returns (uint256[] memory) {
        return array.sort();
    }

    /**
     * @dev Wrapper function for the OZ Arrays.sort function.
     */
    function _sort(address[] memory array, function(address, address) pure returns (bool) comp)
        internal
        pure
        returns (address[] memory)
    {
        return array.sort(comp);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.sort function.
     */
    function _sort(address[] memory array) internal pure returns (address[] memory) {
        return array.sort();
    }

    /**
     * @dev Wrapper function for the OZ Arrays.sort function.
     */
    function _sort(bytes32[] memory array, function(bytes32, bytes32) pure returns (bool) comp)
        internal
        pure
        returns (bytes32[] memory)
    {
        return array.sort(comp);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.sort function.
     */
    function _sort(bytes32[] memory array) internal pure returns (bytes32[] memory) {
        return array.sort();
    }

    /**
     * @dev Wrapper function for the OZ Arrays.findUpperBound function.
     */
    function _findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        return array.findUpperBound(element);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.lowerBound function.
     */
    function _lowerBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        return array.lowerBound(element);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.upperBound function.
     */
    function _upperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        return array.upperBound(element);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.lowerBoundMemory function.
     */
    function _lowerBoundMemory(uint256[] memory array, uint256 element) internal pure returns (uint256) {
        return array.lowerBoundMemory(element);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.upperBoundMemory function.
     */
    function _upperBoundMemory(uint256[] memory array, uint256 element) internal pure returns (uint256) {
        return array.upperBoundMemory(element);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeAccess function.
     */
    function _unsafeAccess(address[] storage arr, uint256 pos) internal pure returns (StorageSlot.AddressSlot storage) {
        return arr.unsafeAccess(pos);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeAccess function.
     */
    function _unsafeAccess(bytes32[] storage arr, uint256 pos) internal pure returns (StorageSlot.Bytes32Slot storage) {
        return arr.unsafeAccess(pos);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeAccess function.
     */
    function _unsafeAccess(uint256[] storage arr, uint256 pos) internal pure returns (StorageSlot.Uint256Slot storage) {
        return arr.unsafeAccess(pos);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeAccess function.
     */
    function _unsafeAccess(bytes[] storage arr, uint256 pos) internal pure returns (StorageSlot.BytesSlot storage) {
        return arr.unsafeAccess(pos);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeAccess function.
     */
    function _unsafeAccess(string[] storage arr, uint256 pos) internal pure returns (StorageSlot.StringSlot storage) {
        return arr.unsafeAccess(pos);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeMemoryAccess function.
     */
    function _unsafeMemoryAccess(address[] memory arr, uint256 pos) internal pure returns (address res) {
        return arr.unsafeMemoryAccess(pos);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeMemoryAccess function.
     */
    function _unsafeMemoryAccess(bytes32[] memory arr, uint256 pos) internal pure returns (bytes32 res) {
        return arr.unsafeMemoryAccess(pos);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeMemoryAccess function.
     */
    function _unsafeMemoryAccess(uint256[] memory arr, uint256 pos) internal pure returns (uint256 res) {
        return arr.unsafeMemoryAccess(pos);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeMemoryAccess function.
     */
    function _unsafeMemoryAccess(bytes[] memory arr, uint256 pos) internal pure returns (bytes memory res) {
        return arr.unsafeMemoryAccess(pos);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeMemoryAccess function.
     */
    function _unsafeMemoryAccess(string[] memory arr, uint256 pos) internal pure returns (string memory res) {
        return arr.unsafeMemoryAccess(pos);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeSetLength function.
     */
    function _unsafeSetLength(address[] storage array, uint256 len) internal {
        return array.unsafeSetLength(len);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeSetLength function.
     */
    function _unsafeSetLength(bytes32[] storage array, uint256 len) internal {
        return array.unsafeSetLength(len);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeSetLength function.
     */
    function _unsafeSetLength(uint256[] storage array, uint256 len) internal {
        return array.unsafeSetLength(len);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeSetLength function.
     */
    function _unsafeSetLength(bytes[] storage array, uint256 len) internal {
        return array.unsafeSetLength(len);
    }

    /**
     * @dev Wrapper function for the OZ Arrays.unsafeSetLength function.
     */
    function _unsafeSetLength(string[] storage array, uint256 len) internal {
        return array.unsafeSetLength(len);
    }

    /* ---------------------------------------------------------------------- */
    /*                                New Logic                               */
    /* ---------------------------------------------------------------------- */

    /* ---------------------------------- ! --------------------------------- */

    /**
     * @param length The length of the array for which `invalidIndex` is out of bounds.
     * @param invalidIndex The index that is out of bounds for the array.
     */
    error IndexOutOfBounds(uint256 length, uint256 invalidIndex, uint256 errorCode);

    error EndBeforeStart(uint256 start, uint256 end);

    /**
     * @dev Reverts with custom error if provided index would be out of bounds of provided length.
     * @dev Facilitates usage of custom error within a require statement.
     * @param length The length of the array against which the index is being checked..
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
     * @dev New length must be greater than or equal to the original length.
     * @param values The fixed-size array to be copied to a new array of greater length.
     * @param newLength The length of the new array.
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
     * @dev New length must be greater than or equal to the original length.
     * @param values The fixed-size array to be copied to a new array of greater length.
     * @param newLength The length of the new array.
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
     * @dev New length must be greater than or equal to the original length.
     * @param values The fixed-size array to be copied to a new array of greater length
     * @param newLength The length of the new array.
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
     * @dev New length must be greater than or equal to the original length.
     * @param values The fixed-size array to be copied to a new array of greater length
     * @param newLength The length of the new array.
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
}
