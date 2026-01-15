// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {ErrorMsg, ComparatorLogger} from "@crane/contracts/test/comparators/ComparatorLogger.sol";
import {SetComparatorResults, SetComparatorLogger} from "@crane/contracts/test/comparators/SetComparatorLogger.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";

/**
 * @notice Request struct for bytes4 set comparison operations
 * @param expected The array of expected bytes4 values
 * @param actual The array of actual bytes4 values to compare against
 * @param errorMsg Error message configuration for failure reporting
 */
struct Bytes4ComparatorRequest {
    bytes4[] expected;
    bytes4[] actual;
    ErrorMsg errorMsg;
}

/**
 * @notice Storage layout for the Bytes4SetComparator testing infrastructure
 * @dev Uses isolated storage per comparison operation to avoid conflicts
 * @param recordedExpected Persistent storage for expected values keyed by subject address and function selector
 * @param tempExpected Temporary set used during comparison to detect duplicates in expected array
 * @param actual Temporary set used during comparison to store actual values
 */
struct Bytes4SetComparatorLayout {
    mapping(address subject => mapping(bytes4 func => Bytes4Set expected)) recordedExpected;
    Bytes4Set tempExpected;
    Bytes4Set actual;
}

/**
 * @title Bytes4SetComparatorRepo
 * @notice Storage management for the Bytes4SetComparator testing infrastructure
 * @dev Provides isolated storage slots for comparison operations to prevent test interference.
 *      Uses a hash-based slot derivation to ensure each comparison operation gets unique storage.
 */
library Bytes4SetComparatorRepo {
    using Bytes4SetRepo for Bytes4Set;
    using BetterAddress for address;

    /// @dev Offset used to derive unique storage slots for comparison operations
    bytes32 private constant STORAGE_RANGE_OFFSET = keccak256(abi.encode(type(Bytes4SetComparatorRepo).name));

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (Bytes4SetComparatorLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }

    /**
     * @notice Gets the storage layout for a specific comparison operation
     * @dev XORs the actual hash with the storage offset for slot isolation
     * @param actualHash Hash of the actual array being compared
     * @return Storage layout bound to the derived slot
     */
    function _b4SetCompare(bytes32 actualHash) internal pure returns (Bytes4SetComparatorLayout storage) {
        return _layout((actualHash ^ STORAGE_RANGE_OFFSET));
    }

    /**
     * @notice Records expected bytes4 values for a subject and function
     * @dev Used in expect_* pattern to store expectations before validation
     * @param subject The contract address being tested
     * @param func The function selector being tested
     * @param expected The expected bytes4 values
     */
    function _recExpectedBytes4(address subject, bytes4 func, bytes4[] memory expected) internal {
        _b4SetCompare(subject._toBytes32()).recordedExpected[subject][func]._add(expected);
    }

    /**
     * @notice Retrieves recorded expected bytes4 values
     * @dev Used in hasValid_* pattern to retrieve stored expectations
     * @param subject The contract address being tested
     * @param func The function selector being tested
     * @return The stored expected bytes4 set
     */
    function _recedExpectedBytes4(address subject, bytes4 func) internal view returns (Bytes4Set storage) {
        return _b4SetCompare(subject._toBytes32()).recordedExpected[subject][func];
    }

    /**
     * @notice Gets the temporary expected set for a comparison operation
     * @dev Used during comparison to detect duplicates in expected array
     * @param actualHash Hash of the actual array being compared
     * @return The temporary expected set
     */
    function _tempExpectedBytes4(bytes32 actualHash) internal view returns (Bytes4Set storage) {
        return _b4SetCompare(actualHash).tempExpected;
    }

    /**
     * @notice Gets the actual set for a comparison operation
     * @dev Used during comparison to store actual values
     * @param actualHash Hash of the actual array being compared
     * @return The actual values set
     */
    function _actualBytes4(bytes32 actualHash) internal view returns (Bytes4Set storage) {
        return _b4SetCompare(actualHash).actual;
    }
}

/**
 * @title Bytes4SetComparator
 * @notice Library for comparing arrays of bytes4 values with detailed error reporting
 * @dev Performs bidirectional set comparison to detect:
 *      - Missing expected values (values in expected but not in actual)
 *      - Unexpected actual values (values in actual but not in expected)
 *      - Duplicate values in the expected array
 *      - Length mismatches between sets
 *
 *      The comparison is bidirectional:
 *      1. First direction: For each expected value, check if it exists in actual
 *         (tracks `expectedMisses` - expected values not found in actual)
 *      2. Second direction: For each actual value, check if it exists in expected
 *         (tracks `actualMisses` - unexpected values found in actual)
 *
 *      This ensures that the sets are equivalent, not just that one is a subset of the other.
 */
library Bytes4SetComparator {
    using Bytes4SetRepo for Bytes4Set;
    using Bytes4SetComparatorRepo for bytes32;
    using BetterEfficientHashLib for bytes;
    using SetComparatorLogger for SetComparatorResults;

    /**
     * @notice Compares two bytes4 arrays with logging and error reporting
     * @dev Entry point for comparisons that need formatted error messages.
     *      Performs bidirectional comparison (see library NatSpec) and logs results.
     * @param expected The expected bytes4 values (must not contain duplicates)
     * @param actual The actual bytes4 values to compare against
     * @param errorPrefix Prefix for error messages (e.g., "MyContract:myFunction::")
     * @param errorSuffix Suffix for error messages (e.g., "interface IDs")
     * @return True if expected and actual contain the same values, false otherwise
     */
    function _compare(
        bytes4[] memory expected,
        bytes4[] memory actual,
        string memory errorPrefix,
        string memory errorSuffix
    ) internal returns (bool) {
        // Log arrays
        console.log("Expected values:", expected);
        console.log("Actual values:", actual);

        bool matches = _logCompare(
            Bytes4ComparatorRequest({
                expected: expected, actual: actual, errorMsg: ErrorMsg({prefix: errorPrefix, suffix: errorSuffix})
            })
        );
        // console.log("Bytes4SetComparator:_compare:: Exiting function.");
        return matches;
    }

    /**
     * @notice Compares arrays and logs results with error message formatting
     * @dev Wrapper that combines comparison logic with logging.
     *      TODO: Add version accepting storage pointer to expected.
     * @param request The comparison request containing expected, actual, and error message details
     * @return matches True if the sets are equivalent
     */
    function _logCompare(Bytes4ComparatorRequest memory request) internal returns (bool matches) {
        SetComparatorResults memory result = _compare(request.expected, request.actual);
        matches = result._logResult(request.errorMsg);
    }

    /**
     * @notice Core comparison function that performs bidirectional set validation
     * @dev Performs a full bidirectional comparison between expected and actual arrays.
     *      Both `expectedMisses` and `actualMisses` are tracked separately in the result.
     *
     *      **Failure Conditions:**
     *      1. Duplicate values in expected array: If expected contains duplicates, the comparison
     *         fails immediately. Duplicates are detected by comparing the input array length
     *         against the set length after adding all values.
     *      2. Missing expected values (expectedMisses > 0): Values that were expected but
     *         not found in the actual array. Indicates missing functionality.
     *      3. Unexpected actual values (actualMisses > 0): Values found in actual but
     *         not in expected. Indicates extra/undeclared functionality.
     *      4. Length mismatch: Caught implicitly when expectedMisses or actualMisses > 0.
     *
     *      TODO: Add version accepting storage pointer to expected.
     *
     * @param expected The expected bytes4 values (duplicates will cause failure)
     * @param actual The actual bytes4 values to compare against
     * @return result A SetComparatorResults struct containing:
     *         - actualArgLength: Length of the input actual array
     *         - expectedCheckLength: Length of expected set after deduplication
     *         - actualCheckLength: Length of actual set after deduplication
     *         - expectedMisses: Count of expected values not found in actual
     *         - actualMisses: Count of actual values not found in expected
     */
    function _compare(bytes4[] memory expected, bytes4[] memory actual)
        internal
        returns (SetComparatorResults memory result)
    {
        bytes32 ah = abi.encode(actual)._hash();
        result.actualArgLength = actual.length;
        // console.log("Storing expected to detect duplicates.");
        Bytes4SetComparatorRepo._tempExpectedBytes4(ah)._add(expected);
        // console.log("Checking for duplicates.");
        if (expected.length != Bytes4SetComparatorRepo._tempExpectedBytes4(ah)._length()) {
            console.log(
                "Bytes4Set expectations MUST NOT contain duplicates. Provide expectations as FIRST argument.", expected
            );
            // Calculate absolute difference to avoid underflow
            unchecked {
                uint256 expectedLen = expected.length;
                uint256 tempLen = Bytes4SetComparatorRepo._tempExpectedBytes4(ah)._length();
                result.expectedMisses = expectedLen >= tempLen ? expectedLen - tempLen : tempLen - expectedLen;
                result.actualMisses = actual.length;
            }
            return result;
        }
        Bytes4SetComparatorRepo._actualBytes4(ah)._add(actual);
        result.actualCheckLength = Bytes4SetComparatorRepo._actualBytes4(ah)._length();
        result.expectedCheckLength = Bytes4SetComparatorRepo._tempExpectedBytes4(ah)._length();
        for (
            uint256 expectedCursor = 0;
            expectedCursor < Bytes4SetComparatorRepo._tempExpectedBytes4(ah)._length();
            expectedCursor++
        ) {
            if (!Bytes4SetComparatorRepo._actualBytes4(ah)
                    ._contains(Bytes4SetComparatorRepo._tempExpectedBytes4(ah)._index(expectedCursor))) {
                result.expectedMisses++;
            }
        }
        for (
            uint256 actualCursor = 0;
            actualCursor < Bytes4SetComparatorRepo._actualBytes4(ah)._length();
            actualCursor++
        ) {
            if (!Bytes4SetComparatorRepo._tempExpectedBytes4(ah)
                    ._contains(Bytes4SetComparatorRepo._actualBytes4(ah)._index(actualCursor))) {
                result.actualMisses++;
            }
        }
        console.log("Bytes4SetComparator:_compare:: Exiting function.");
        return result;
    }
}
