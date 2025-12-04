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

struct Bytes4ComparatorRequest {
    bytes4[] expected;
    bytes4[] actual;
    ErrorMsg errorMsg;
}

struct Bytes4SetComparatorLayout {
    mapping(address subject => mapping(bytes4 func => Bytes4Set expected)) recordedExpected;
    Bytes4Set tempExpected;
    Bytes4Set actual;
}

library Bytes4SetComparatorRepo {
    using Bytes4SetRepo for Bytes4Set;
    using BetterAddress for address;

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

    function _b4SetCompare(bytes32 actualHash) internal pure returns (Bytes4SetComparatorLayout storage) {
        return _layout((actualHash ^ STORAGE_RANGE_OFFSET));
    }

    function _recExpectedBytes4(address subject, bytes4 func, bytes4[] memory expected) internal {
        _b4SetCompare(subject._toBytes32()).recordedExpected[subject][func]._add(expected);
    }

    function _recedExpectedBytes4(address subject, bytes4 func) internal view returns (Bytes4Set storage) {
        return _b4SetCompare(subject._toBytes32()).recordedExpected[subject][func];
    }

    function _tempExpectedBytes4(bytes32 actualHash) internal view returns (Bytes4Set storage) {
        return _b4SetCompare(actualHash).tempExpected;
    }

    function _actualBytes4(bytes32 actualHash) internal view returns (Bytes4Set storage) {
        return _b4SetCompare(actualHash).actual;
    }
}

library Bytes4SetComparator {
    using Bytes4SetRepo for Bytes4Set;
    using Bytes4SetComparatorRepo for bytes32;
    using BetterEfficientHashLib for bytes;
    using SetComparatorLogger for SetComparatorResults;

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

    // IMPROVE Add version accepting storage pointer to expected.
    function _logCompare(Bytes4ComparatorRequest memory request) internal returns (bool matches) {
        SetComparatorResults memory result = _compare(request.expected, request.actual);
        matches = result._logResult(request.errorMsg);
    }

    // IMPROVE Add version accepting storage pointer to expected.
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
