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

// tag::Bytes4ComparatorRequest[]
/**
 * @notice Request struct for bytes4 set comparison operations.
 * @param expected The array of expected bytes4 values.
 * @param actual The array of actual bytes4 values to compare against.
 * @param errorMsg Error message configuration for failure reporting.
 */
struct Bytes4ComparatorRequest {
    bytes4[] expected;
    bytes4[] actual;
    ErrorMsg errorMsg;
}

// end::Bytes4ComparatorRequest[]

// tag::Bytes4SetComparatorLayout[]
/**
 * @notice Storage layout for the Bytes4SetComparator testing infrastructure.
 * @dev Uses isolated storage per comparison operation to avoid conflicts between tests.
 * @param recordedExpected Persistent storage for expected values keyed by subject address and function selector (as bytes4).
 * @param tempExpected Temporary set used during comparison to detect duplicates in expected array.
 * @param actual Temporary set used during comparison to store actual values.
 */
struct Bytes4SetComparatorLayout {
    mapping(address subject => mapping(bytes4 func => Bytes4Set expected)) recordedExpected;
    Bytes4Set tempExpected;
    Bytes4Set actual;
}

// end::Bytes4SetComparatorLayout[]

// tag::Bytes4SetComparatorRepo[]
/**
 * @title Bytes4SetComparatorRepo
 * @author cyotee doge <doge.cyotee>
 * @notice Storage management for the Bytes4SetComparator testing infrastructure.
 * @dev Provides isolated storage slots for comparison operations (via hash XOR offset) to prevent test interference.
 *      Used by Behavior libraries (e.g. Behavior_IFacet, Behavior_IERC165) and FacetsComparator for expect_/hasValid_ patterns via _recExpectedBytes4 / _recedExpectedBytes4 and during _compare for temp/actual.
 *      Modeled on AddressSetComparatorRepo and Bytes4SetRepo gold (rich NatSpec, exact // tag:: / end:: with hyphen overloads).
 *      All functions are internal; no public API surface or custom values required (per CENTRALLY_COMPUTED_NATSPEC_VALUES.md; no custom tags apply).
 */
library Bytes4SetComparatorRepo {
    using Bytes4SetRepo for Bytes4Set;
    using BetterAddress for address;

    /// @dev Offset used to derive unique storage slots for comparison operations (per-actual-hash isolation).
    bytes32 private constant STORAGE_RANGE_OFFSET = keccak256(abi.encode(type(Bytes4SetComparatorRepo).name));

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layoutStruct A struct from a Layout library bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Bytes4SetComparatorLayout storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_b4SetCompare(bytes32)[]
    /**
     * @notice Gets the storage layout for a specific comparison operation.
     * @dev XORs the actual hash with the storage offset for slot isolation.
     * @param actualHash Hash of the actual array being compared.
     * @return The layout bound to the derived slot.
     */
    function _b4SetCompare(bytes32 actualHash) internal pure returns (Bytes4SetComparatorLayout storage) {
        return _layoutStruct((actualHash ^ STORAGE_RANGE_OFFSET));
    }

    // end::_b4SetCompare(bytes32)[]

    // tag::_recExpectedBytes4(address-bytes4-bytes4[])[]
    /**
     * @notice Records an array of expected bytes4 for a subject and function (bytes4 key).
     * @dev Used in expect_* pattern to store expectations before validation. Idempotent via Bytes4SetRepo.
     * @param subject The contract address being tested.
     * @param func The function selector (as bytes4) being tested.
     * @param expected The expected bytes4 values.
     */
    function _recExpectedBytes4(address subject, bytes4 func, bytes4[] memory expected) internal {
        _b4SetCompare(subject._toBytes32()).recordedExpected[subject][func]._add(expected);
    }

    // end::_recExpectedBytes4(address-bytes4-bytes4[])[]

    // tag::_recExpectedBytes4(address-bytes4-bytes4)[]
    /**
     * @notice Records a single expected bytes4 for a subject and function (bytes4 key).
     * @dev Used in expect_* pattern (from Behaviors) to store expectations before validation.
     * @param subject The contract address being tested.
     * @param func The function selector (as bytes4) being tested.
     * @param expected The expected bytes4 value.
     */
    function _recExpectedBytes4(address subject, bytes4 func, bytes4 expected) internal {
        _b4SetCompare(subject._toBytes32()).recordedExpected[subject][func]._add(expected);
    }

    // end::_recExpectedBytes4(address-bytes4-bytes4)[]

    // tag::_recedExpectedBytes4(address-bytes4)[]
    /**
     * @notice Retrieves recorded expected bytes4 for a subject and function.
     * @dev Used in hasValid_* / areValid_* pattern to retrieve stored expectations for comparison.
     * @param subject The contract address being tested.
     * @param func The function selector (as bytes4) being tested.
     * @return The stored expected Bytes4Set.
     */
    function _recedExpectedBytes4(address subject, bytes4 func) internal view returns (Bytes4Set storage) {
        return _b4SetCompare(subject._toBytes32()).recordedExpected[subject][func];
    }

    // end::_recedExpectedBytes4(address-bytes4)[]

    // tag::_tempExpectedBytes4(bytes32)[]
    /**
     * @notice Gets the temporary expected set for a comparison operation.
     * @dev Used during comparison to detect duplicates in expected array (via length check after _add).
     * @param actualHash Hash of the actual array being compared.
     * @return The temporary expected set.
     */
    function _tempExpectedBytes4(bytes32 actualHash) internal view returns (Bytes4Set storage) {
        return _b4SetCompare(actualHash).tempExpected;
    }

    // end::_tempExpectedBytes4(bytes32)[]

    // tag::_actualBytes4(bytes32)[]
    /**
     * @notice Gets the actual set for a comparison operation.
     * @dev Used during comparison to store actual values.
     * @param actualHash Hash of the actual array being compared.
     * @return The actual values set.
     */
    function _actualBytes4(bytes32 actualHash) internal view returns (Bytes4Set storage) {
        return _b4SetCompare(actualHash).actual;
    }
    // end::_actualBytes4(bytes32)[]
}

// end::Bytes4SetComparatorRepo[]

// tag::Bytes4SetComparator[]
/**
 * @title Bytes4SetComparator
 * @author cyotee doge <doge.cyotee>
 * @notice Library for comparing arrays of bytes4 values with detailed error reporting.
 * @dev Performs bidirectional set comparison (using Bytes4SetRepo for dedup/detection) to detect:
 *      - Missing expected values (values in expected but not in actual)
 *      - Unexpected actual values (values in actual but not in expected)
 *      - Duplicate values in the expected array (causes immediate failure via length mismatch after add)
 *      - Length mismatches between sets
 *
 *      The comparison is bidirectional:
 *      1. First direction: For each expected value, check if it exists in actual (tracks `expectedMisses`)
 *      2. Second direction: For each actual value, check if it exists in expected (tracks `actualMisses`)
 *
 *      This ensures that the sets are equivalent, not just that one is a subset of the other.
 *      Delegates logging and result formatting to SetComparatorLogger / SetComparatorResults.
 *      Used by Behavior_* for bytes4-based declaration validation (e.g. facet interfaces, facet funcs).
 *
 *      Preserves 100% original logic, console logging, duplicate detection (with special handling), and _add usage on temp/actual.
 *      No custom NatSpec values (internal test comparator; CENTRALLY_COMPUTED_NATSPEC_VALUES.md has none for it).
 *      Rich NatSpec + exact // tag:: / end:: modeled on AddressSetComparator + Behavior_IFacet + Bytes4SetRepo golds.
 */
library Bytes4SetComparator {
    using Bytes4SetRepo for Bytes4Set;
    using Bytes4SetComparatorRepo for bytes32;
    using BetterEfficientHashLib for bytes;
    using SetComparatorLogger for SetComparatorResults;

    // tag::_compare(bytes4[]-bytes4[]-string-string)[]
    /**
     * @notice Compares two bytes4 arrays with logging and error reporting.
     * @dev Entry point for comparisons that need formatted error messages (via prefix/suffix).
     *      Wraps the core compare + delegates to _logCompare. Includes debug logs for expected/actual.
     * @param expected The expected bytes4 values (must not contain duplicates).
     * @param actual The actual bytes4 values to compare against.
     * @param errorPrefix Prefix for error messages (e.g., "MyContract:myFunction::").
     * @param errorSuffix Suffix for error messages (e.g., "interface IDs").
     * @return True if expected and actual contain the same values, false otherwise.
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

    // end::_compare(bytes4[]-bytes4[]-string-string)[]

    // tag::_logCompare(Bytes4ComparatorRequest)[]
    /**
     * @notice Compares arrays and logs results with error message formatting.
     * @dev Wrapper that combines comparison logic with logging via SetComparatorLogger.
     *      TODO/IMPROVE: Add version accepting storage pointer to expected (per source comment).
     * @param request The comparison request containing expected, actual, and error message details.
     * @return matches True if the sets are equivalent.
     */
    function _logCompare(Bytes4ComparatorRequest memory request) internal returns (bool matches) {
        SetComparatorResults memory result = _compare(request.expected, request.actual);
        matches = result._logResult(request.errorMsg);
    }

    // end::_logCompare(Bytes4ComparatorRequest)[]

    // tag::_compare(bytes4[]-bytes4[])[]
    /**
     * @notice Core comparison function that performs bidirectional set validation.
     * @dev Performs a full bidirectional comparison between expected and actual arrays using Bytes4Set for dedup.
     *      Both `expectedMisses` and `actualMisses` are tracked separately in the result.
     *      Duplicates in expected cause special handling (no revert, set misses counts).
     *
     *      **Failure Conditions:**
     *      1. Duplicate values in expected array: length check after adding to tempExpected set (differs from Address: records diff as misses).
     *      2. Missing expected values (expectedMisses > 0).
     *      3. Unexpected actual values (actualMisses > 0).
     *      4. Length mismatch: implicit in misses counts.
     *
     *      Uses tempExpected and actual Bytes4Sets populated via _add; queries via _contains/_index/_length.
     *      TODO/IMPROVE: Add version accepting storage pointer to expected (per source comment).
     *
     * @param expected The expected bytes4 values (duplicates will cause failure path).
     * @param actual The actual bytes4 values to compare against.
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
    // end::_compare(bytes4[]-bytes4[])[]
}
// end::Bytes4SetComparator[]
