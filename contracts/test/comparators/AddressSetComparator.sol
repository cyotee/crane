// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";
import {BetterAddress} from "@crane/contracts/utils/BetterAddress.sol";
import {ErrorMsg, ComparatorLogger} from "@crane/contracts/test/comparators/ComparatorLogger.sol";
import {SetComparatorResults, SetComparatorLogger} from "@crane/contracts/test/comparators/SetComparatorLogger.sol";

// tag::AddressComparatorRequest[]
/**
 * @notice Request struct for address set comparison operations.
 * @param expected The array of expected address values.
 * @param actual The array of actual address values to compare against.
 * @param errorMsg Error message configuration for failure reporting.
 */
struct AddressComparatorRequest {
    address[] expected;
    address[] actual;
    ErrorMsg errorMsg;
}
// end::AddressComparatorRequest[]

// tag::AddressSetComparatorLayout[]
/**
 * @notice Storage layout for the AddressSetComparator testing infrastructure.
 * @dev Uses isolated storage per comparison operation to avoid conflicts between tests.
 * @param recordedExpected Persistent storage for expected values keyed by subject address and function selector (as bytes32).
 * @param tempExpected Temporary set used during comparison to detect duplicates in expected array.
 * @param actual Temporary set used during comparison to store actual values.
 */
struct AddressSetComparatorLayout {
    mapping(address subject => mapping(bytes32 func => AddressSet expected)) recordedExpected;
    AddressSet tempExpected;
    AddressSet actual;
}
// end::AddressSetComparatorLayout[]

// tag::AddressSetComparatorRepo[]
/**
 * @title AddressSetComparatorRepo
 * @author cyotee doge <doge.cyotee>
 * @notice Storage management for the AddressSetComparator testing infrastructure.
 * @dev Provides isolated storage slots for comparison operations (via hash XOR offset) to prevent test interference.
 *      Used by Behavior libraries (e.g. Behavior_IFacetRegistry, Behavior_IDiamondLoupe, Behavior_IDiamondFactoryPackageRegistry)
 *      and FacetsComparator for expect_/hasValid_ patterns via _recExpectedAddrs / _recedExpectedAddrs and during _compare for temp/actual.
 *      Modeled on Bytes4SetComparatorRepo and AddressSetRepo gold (rich NatSpec, exact // tag:: / end:: with hyphen overloads).
 *      All functions are internal; no public API surface or custom values required (per CENTRALLY_COMPUTED_NATSPEC_VALUES.md; no custom tags apply).
 */
library AddressSetComparatorRepo {
    using AddressSetRepo for AddressSet;
    using BetterAddress for address;

    /// @dev Offset used to derive unique storage slots for comparison operations (per-actual-hash isolation).
    bytes32 private constant STORAGE_RANGE_OFFSET = keccak256(abi.encode(type(AddressSetComparatorRepo).name));

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layoutStruct A struct from a Layout library bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (AddressSetComparatorLayout storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }
    // end::_layoutStruct(bytes32)[]

    // tag::_addrSetCompare(bytes32)[]
    /**
     * @notice Gets the storage layout for a specific comparison operation.
     * @dev XORs the actual hash with the storage offset for slot isolation.
     * @param actualHash Hash of the actual array being compared.
     * @return The layout bound to the derived slot.
     */
    function _addrSetCompare(bytes32 actualHash) internal pure returns (AddressSetComparatorLayout storage) {
        return _layoutStruct((actualHash ^ STORAGE_RANGE_OFFSET));
    }
    // end::_addrSetCompare(bytes32)[]

    // tag::_recExpectedAddrs(address-bytes32-address)[]
    /**
     * @notice Records a single expected address for a subject and function (bytes32 key).
     * @dev Used in expect_* pattern (from Behaviors) to store expectations before validation.
     * @param subject The contract address being tested.
     * @param func The function selector (as bytes32) being tested.
     * @param expected The expected address value.
     */
    function _recExpectedAddrs(address subject, bytes32 func, address expected) internal {
        _addrSetCompare(subject._toBytes32()).recordedExpected[subject][func]._add(expected);
    }
    // end::_recExpectedAddrs(address-bytes32-address)[]

    // tag::_recExpectedAddrs(address-bytes32-address[])[]
    /**
     * @notice Records an array of expected addresses for a subject and function (bytes32 key).
     * @dev Used in expect_* pattern to store expectations before validation. Idempotent via AddressSetRepo.
     * @param subject The contract address being tested.
     * @param func The function selector (as bytes32) being tested.
     * @param expected The expected address values.
     */
    function _recExpectedAddrs(address subject, bytes32 func, address[] memory expected) internal {
        _addrSetCompare(subject._toBytes32()).recordedExpected[subject][func]._add(expected);
    }
    // end::_recExpectedAddrs(address-bytes32-address[])[]

    // tag::_recedExpectedAddrs(address-bytes32)[]
    /**
     * @notice Retrieves recorded expected addresses for a subject and function.
     * @dev Used in hasValid_* / areValid_* pattern to retrieve stored expectations for comparison.
     * @param subject The contract address being tested.
     * @param func The function selector (as bytes32) being tested.
     * @return The stored expected AddressSet.
     */
    function _recedExpectedAddrs(address subject, bytes32 func) internal view returns (AddressSet storage) {
        return _addrSetCompare(subject._toBytes32()).recordedExpected[subject][func];
    }
    // end::_recedExpectedAddrs(address-bytes32)[]

    // tag::_tempExpectedAddrs(bytes32)[]
    /**
     * @notice Gets the temporary expected set for a comparison operation.
     * @dev Used during comparison to detect duplicates in expected array (via length check after _add).
     * @param actualHash Hash of the actual array being compared.
     * @return The temporary expected set.
     */
    function _tempExpectedAddrs(bytes32 actualHash) internal view returns (AddressSet storage) {
        return _addrSetCompare(actualHash).tempExpected;
    }
    // end::_tempExpectedAddrs(bytes32)[]

    // tag::_actualAddrs(bytes32)[]
    /**
     * @notice Gets the actual set for a comparison operation.
     * @dev Used during comparison to store actual values.
     * @param actualHash Hash of the actual array being compared.
     * @return The actual values set.
     */
    function _actualAddrs(bytes32 actualHash) internal view returns (AddressSet storage) {
        return _addrSetCompare(actualHash).actual;
    }
    // end::_actualAddrs(bytes32)[]
}
// end::AddressSetComparatorRepo[]

// tag::AddressSetComparator[]
/**
 * @title AddressSetComparator
 * @author cyotee doge <doge.cyotee>
 * @notice Library for comparing arrays of address values with detailed error reporting.
 * @dev Performs bidirectional set comparison (using AddressSetRepo for dedup/detection) to detect:
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
 *      Used by Behavior_* for address-based declaration validation (e.g. facet addresses, package addresses).
 *
 *      Preserves 100% original logic, console logging, duplicate detection, and _add usage on temp/actual.
 *      No custom NatSpec values (internal test comparator; CENTRALLY_COMPUTED_NATSPEC_VALUES.md has none for it).
 *      Rich NatSpec + exact // tag:: / end:: modeled on Behavior_IFacet.sol (test lib gold) + Bytes4SetComparator + SetRepos.
 */
library AddressSetComparator {
    using AddressSetRepo for AddressSet;
    using BetterEfficientHashLib for bytes;

    // tag::_compare(address[]-address[]-string-string)[]
    /**
     * @notice Compares two address arrays with logging and error reporting.
     * @dev Entry point for comparisons that need formatted error messages (via prefix/suffix).
     *      Wraps the core compare + delegates to _logCompare.
     * @param expected The expected address values (must not contain duplicates).
     * @param actual The actual address values to compare against.
     * @param errorPrefix Prefix for error messages (e.g., "MyContract:myFunction::").
     * @param errorSuffix Suffix for error messages (e.g., "facet addresses").
     * @return True if expected and actual contain the same values, false otherwise.
     */
    function _compare(
        address[] memory expected,
        address[] memory actual,
        string memory errorPrefix,
        string memory errorSuffix
    ) internal returns (bool) {
        return _logCompare(
            AddressComparatorRequest({
                expected: expected, actual: actual, errorMsg: ErrorMsg({prefix: errorPrefix, suffix: errorSuffix})
            })
        );
    }
    // end::_compare(address[]-address[]-string-string)[]

    // tag::_logCompare(AddressComparatorRequest)[]
    /**
     * @notice Compares arrays and logs results with error message formatting.
     * @dev Wrapper that combines comparison logic with logging via SetComparatorLogger.
     *      TODO/IMPROVE: Add version accepting storage pointer to expected (per source comment).
     * @param request The comparison request containing expected, actual, and error message details.
     * @return matches True if the sets are equivalent.
     */
    function _logCompare(AddressComparatorRequest memory request) internal returns (bool matches) {
        SetComparatorResults memory result = _compare(request.expected, request.actual);
        matches = SetComparatorLogger._logResult(result, request.errorMsg);
    }
    // end::_logCompare(AddressComparatorRequest)[]

    // tag::_compare(address[]-address[])[]
    /**
     * @notice Core comparison function that performs bidirectional set validation.
     * @dev Performs a full bidirectional comparison between expected and actual arrays using AddressSet for dedup.
     *      Both `expectedMisses` and `actualMisses` are tracked separately in the result.
     *      Duplicates in expected cause immediate failure (detected by length vs set length after _add).
     *
     *      **Failure Conditions:**
     *      1. Duplicate values in expected array: length check after adding to tempExpected set.
     *      2. Missing expected values (expectedMisses > 0).
     *      3. Unexpected actual values (actualMisses > 0).
     *      4. Length mismatch: implicit in misses counts.
     *
     *      Uses tempExpected and actual AddressSets populated via _add; queries via _contains/_index/_length.
     *      TODO/IMPROVE: Add version accepting storage pointer to expected (per source comment).
     *
     * @param expected The expected address values (duplicates will cause failure).
     * @param actual The actual address values to compare against.
     * @return result A SetComparatorResults struct containing:
     *         - actualArgLength: Length of the input actual array
     *         - expectedCheckLength: Length of expected set after deduplication
     *         - actualCheckLength: Length of actual set after deduplication
     *         - expectedMisses: Count of expected values not found in actual
     *         - actualMisses: Count of actual values not found in expected
     */
    function _compare(address[] memory expected, address[] memory actual)
        internal
        returns (SetComparatorResults memory result)
    {
        // matches = true;
        // bytes32 ah = keccak256(abi.encode(actual));
        bytes32 ah = abi.encode(actual)._hash();
        result.actualArgLength = actual.length;
        AddressSetComparatorRepo._tempExpectedAddrs(ah)._add(expected);
        if (expected.length != AddressSetComparatorRepo._tempExpectedAddrs(ah)._length()) {
            console.log("AddressSet expectations MUST NOT contain duplicates. Provide expectations as FIRST argument.");
            revert();
        }
        AddressSetComparatorRepo._actualAddrs(ah)._add(actual);
        result.actualCheckLength = AddressSetComparatorRepo._actualAddrs(ah)._length();
        result.expectedCheckLength = AddressSetComparatorRepo._tempExpectedAddrs(ah)._length();
        for (
            uint256 expectedCursor = 0;
            expectedCursor < AddressSetComparatorRepo._tempExpectedAddrs(ah)._length();
            expectedCursor++
        ) {
            if (!AddressSetComparatorRepo._actualAddrs(ah)
                    ._contains(AddressSetComparatorRepo._tempExpectedAddrs(ah)._index(expectedCursor))) {
                result.expectedMisses++;
            }
        }
        for (
            uint256 actualCursor = 0;
            actualCursor < AddressSetComparatorRepo._actualAddrs(ah)._length();
            actualCursor++
        ) {
            if (!AddressSetComparatorRepo._tempExpectedAddrs(ah)
                    ._contains(AddressSetComparatorRepo._actualAddrs(ah)._index(actualCursor))) {
                result.actualMisses++;
            }
        }
    }
    // end::_compare(address[]-address[])[]
}
// end::AddressSetComparator[]
