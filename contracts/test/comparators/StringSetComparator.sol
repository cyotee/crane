// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {StringSet, StringSetRepo} from "@crane/contracts/utils/collections/sets/StringSetRepo.sol";
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";
import {ErrorMsg, ComparatorLogger} from "@crane/contracts/test/comparators/ComparatorLogger.sol";
import {SetComparatorResults, SetComparatorLogger} from "@crane/contracts/test/comparators/SetComparatorLogger.sol";

// tag::StringComparatorRequest[]
/**
 * @notice Request struct for string set comparison operations.
 * @param expected The array of expected string values.
 * @param actual The array of actual string values to compare against.
 * @param errorMsg Error message configuration for failure reporting.
 */
struct StringComparatorRequest {
    string[] expected;
    string[] actual;
    ErrorMsg errorMsg;
}
// end::StringComparatorRequest[]

// tag::StringSetComparatorLayout[]
/**
 * @notice Storage layout for the StringSetComparator testing infrastructure.
 * @dev Uses isolated storage per comparison operation to avoid conflicts between tests.
 * @param recordedExpected Persistent storage for expected values keyed by subject address and function selector (as bytes32).
 * @param tempExpected Temporary set used during comparison to detect duplicates in expected array.
 * @param actual Temporary set used during comparison to store actual values.
 */
struct StringSetComparatorLayout {
    mapping(address subject => mapping(bytes32 key => StringSet expected)) recordedExpected;
    StringSet tempExpected;
    StringSet actual;
}
// end::StringSetComparatorLayout[]

// tag::StringSetComparatorRepo[]
/**
 * @title StringSetComparatorRepo
 * @author cyotee doge <doge.cyotee>
 * @notice Storage management for the StringSetComparator testing infrastructure.
 * @dev Provides isolated storage slots for comparison operations (via hash XOR offset) to prevent test interference.
 *      Used by Behavior libraries for expect_/hasValid_ patterns via _recExpected / _recedExpected and during _compare for temp/actual.
 *      Modeled on Bytes4SetComparatorRepo and AddressSetComparatorRepo + StringSetRepo gold (rich NatSpec, exact // tag:: / end:: with hyphen overloads).
 *      All functions are internal; no public API surface or custom values required (per CENTRALLY_COMPUTED_NATSPEC_VALUES.md; no custom tags apply).
 */
library StringSetComparatorRepo {
    using StringSetRepo for StringSet;
    using BetterAddress for address;

    /// @dev Offset used to derive unique storage slots for comparison operations (per-actual-hash isolation).
    bytes32 private constant STORAGE_RANGE_OFFSET = keccak256(abi.encode(type(StringSetComparatorRepo).name));

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layoutStruct A struct from a Layout library bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (StringSetComparatorLayout storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }
    // end::_layoutStruct(bytes32)[]

    // tag::_stringSetCompare(bytes32)[]
    /**
     * @notice Gets the storage layout for a specific comparison operation.
     * @dev XORs the actual hash with the storage offset for slot isolation.
     * @param actualHash Hash of the actual array being compared.
     * @return The layout bound to the derived slot.
     */
    function _stringSetCompare(bytes32 actualHash) internal pure returns (StringSetComparatorLayout storage) {
        return _layoutStruct((actualHash ^ STORAGE_RANGE_OFFSET));
    }
    // end::_stringSetCompare(bytes32)[]

    // tag::_recExpected(address-bytes32-string)[]
    /**
     * @notice Records a single expected string for a subject and function (bytes32 key).
     * @dev Used in expect_* pattern (from Behaviors) to store expectations before validation.
     * @param subject The contract address being tested.
     * @param func The function selector (as bytes32) being tested.
     * @param expected The expected string value.
     */
    function _recExpected(address subject, bytes32 func, string memory expected) internal {
        _stringSetCompare(subject._toBytes32()).recordedExpected[subject][func]._add(expected);
    }
    // end::_recExpected(address-bytes32-string)[]

    // tag::_recExpected(address-bytes32-string[])[]
    /**
     * @notice Records an array of expected strings for a subject and function (bytes32 key).
     * @dev Used in expect_* pattern to store expectations before validation. Idempotent via StringSetRepo.
     * @param subject The contract address being tested.
     * @param func The function selector (as bytes32) being tested.
     * @param expected The expected string values.
     */
    function _recExpected(address subject, bytes32 func, string[] memory expected) internal {
        _stringSetCompare(subject._toBytes32()).recordedExpected[subject][func]._add(expected);
    }
    // end::_recExpected(address-bytes32-string[])[]

    // tag::_recedExpected(address-bytes32)[]
    /**
     * @notice Retrieves recorded expected strings for a subject and function.
     * @dev Used in hasValid_* / areValid_* pattern to retrieve stored expectations for comparison.
     * @param subject The contract address being tested.
     * @param func The function selector (as bytes32) being tested.
     * @return The stored expected StringSet.
     */
    function _recedExpected(address subject, bytes32 func) internal view returns (StringSet storage) {
        return _stringSetCompare(subject._toBytes32()).recordedExpected[subject][func];
    }
    // end::_recedExpected(address-bytes32)[]

    // tag::_tempExpected(bytes32)[]
    /**
     * @notice Gets the temporary expected set for a comparison operation.
     * @dev Used during comparison to detect duplicates in expected array (via length check after _add).
     * @param actualHash Hash of the actual array being compared.
     * @return The temporary expected set.
     */
    function _tempExpected(bytes32 actualHash) internal view returns (StringSet storage) {
        return _stringSetCompare(actualHash).tempExpected;
    }
    // end::_tempExpected(bytes32)[]

    // tag::_actual(bytes32)[]
    /**
     * @notice Gets the actual set for a comparison operation.
     * @dev Used during comparison to store actual values.
     * @param actualHash Hash of the actual array being compared.
     * @return The actual values set.
     */
    function _actual(bytes32 actualHash) internal view returns (StringSet storage) {
        return _stringSetCompare(actualHash).actual;
    }
    // end::_actual(bytes32)[]
}
// end::StringSetComparatorRepo[]

// tag::StringSetComparator[]
/**
 * @title StringSetComparator
 * @author cyotee doge <doge.cyotee>
 * @notice Library for comparing arrays of string values with detailed error reporting.
 * @dev Performs bidirectional set comparison (using StringSetRepo for dedup/detection) to detect:
 *      - Missing expected values (values in expected but not in actual)
 *      - Unexpected actual values (values in actual but not in expected)
 *      - Duplicate values in the expected array (causes immediate failure via length mismatch after add + revert)
 *      - Length mismatches between sets
 *
 *      The comparison is bidirectional:
 *      1. First direction: For each expected value, check if it exists in actual (tracks `expectedMisses`)
 *      2. Second direction: For each actual value, check if it exists in expected (tracks `actualMisses`)
 *
 *      This ensures that the sets are equivalent, not just that one is a subset of the other.
 *      Delegates logging and result formatting to SetComparatorLogger / SetComparatorResults.
 *
 *      Preserves 100% original logic, console logging, duplicate detection (revert on dups), and _add usage on temp/actual.
 *      No custom NatSpec values (internal test comparator; CENTRALLY_COMPUTED_NATSPEC_VALUES.md has none for it).
 *      Rich NatSpec + exact // tag:: / end:: modeled on AddressSetComparator + Bytes4SetComparator + StringSetRepo + Behavior_IFacet golds.
 */
library StringSetComparator {
    using StringSetRepo for StringSet;
    using BetterEfficientHashLib for bytes;

    // tag::_compare(string[]-string[]-string-string)[]
    /**
     * @notice Compares two string arrays with logging and error reporting.
     * @dev Entry point for comparisons that need formatted error messages (via prefix/suffix).
     *      Wraps the core compare + delegates to _logCompare.
     * @param expected The expected string values (must not contain duplicates).
     * @param actual The actual string values to compare against.
     * @param errorPrefix Prefix for error messages (e.g., "MyContract:myFunction::").
     * @param errorSuffix Suffix for error messages (e.g., "strings").
     * @return True if expected and actual contain the same values, false otherwise.
     */
    function _compare(
        string[] memory expected,
        string[] memory actual,
        string memory errorPrefix,
        string memory errorSuffix
    ) internal returns (bool) {
        return _logCompare(
            StringComparatorRequest({
                expected: expected, actual: actual, errorMsg: ErrorMsg({prefix: errorPrefix, suffix: errorSuffix})
            })
        );
    }
    // end::_compare(string[]-string[]-string-string)[]

    // tag::_logCompare(StringComparatorRequest)[]
    /**
     * @notice Compares arrays and logs results with error message formatting.
     * @dev Wrapper that combines comparison logic with logging via SetComparatorLogger.
     *      TODO/IMPROVE: Add version accepting storage pointer to expected (per source comment).
     * @param request The comparison request containing expected, actual, and error message details.
     * @return matches True if the sets are equivalent.
     */
    function _logCompare(StringComparatorRequest memory request) internal returns (bool matches) {
        SetComparatorResults memory result = _compare(request.expected, request.actual);
        matches = SetComparatorLogger._logResult(result, request.errorMsg);
    }
    // end::_logCompare(StringComparatorRequest)[]

    // tag::_compare(string[]-string[])[]
    /**
     * @notice Core comparison function that performs bidirectional set validation.
     * @dev Performs a full bidirectional comparison between expected and actual arrays using StringSet for dedup.
     *      Both `expectedMisses` and `actualMisses` are tracked separately in the result.
     *      Duplicates in expected cause immediate failure (detected by length vs set length after _add + revert).
     *
     *      **Failure Conditions:**
     *      1. Duplicate values in expected array: length check after adding to tempExpected set.
     *      2. Missing expected values (expectedMisses > 0).
     *      3. Unexpected actual values (actualMisses > 0).
     *      4. Length mismatch: implicit in misses counts.
     *
     *      Uses tempExpected and actual StringSets populated via _add; queries via _contains/_index/_length.
     *      TODO/IMPROVE: Add version accepting storage pointer to expected (per source comment).
     *
     * @param expected The expected string values (duplicates will cause revert).
     * @param actual The actual string values to compare against.
     * @return result A SetComparatorResults struct containing:
     *         - actualArgLength: Length of the input actual array
     *         - expectedCheckLength: Length of expected set after deduplication
     *         - actualCheckLength: Length of actual set after deduplication
     *         - expectedMisses: Count of expected values not found in actual
     *         - actualMisses: Count of actual values not found in expected
     */
    function _compare(string[] memory expected, string[] memory actual)
        internal
        returns (SetComparatorResults memory result)
    {
        bytes32 ah = abi.encode(actual)._hash();
        result.actualArgLength = actual.length;
        StringSetComparatorRepo._tempExpected(ah)._add(expected);
        if (expected.length != StringSetComparatorRepo._tempExpected(ah)._length()) {
            console.log("StringSet expectations MUST NOT contain duplicates. Provide expectations as FIRST argument.");
            revert();
        }
        StringSetComparatorRepo._actual(ah)._add(actual);
        result.actualCheckLength = StringSetComparatorRepo._actual(ah)._length();
        result.expectedCheckLength = StringSetComparatorRepo._tempExpected(ah)._length();
        for (
            uint256 expectedCursor = 0;
            expectedCursor < StringSetComparatorRepo._tempExpected(ah)._length();
            expectedCursor++
        ) {
            if (!StringSetComparatorRepo._actual(ah)
                    ._contains(StringSetComparatorRepo._tempExpected(ah)._index(expectedCursor))) {
                result.expectedMisses++;
            }
        }
        for (uint256 actualCursor = 0; actualCursor < StringSetComparatorRepo._actual(ah)._length(); actualCursor++) {
            if (!StringSetComparatorRepo._tempExpected(ah)
                    ._contains(StringSetComparatorRepo._actual(ah)._index(actualCursor))) {
                result.actualMisses++;
            }
        }
    }
    // end::_compare(string[]-string[])[]
}
// end::StringSetComparator[]
