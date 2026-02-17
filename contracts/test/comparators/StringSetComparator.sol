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

struct StringComparatorRequest {
    string[] expected;
    string[] actual;
    ErrorMsg errorMsg;
}

struct StringSetComparatorLayout {
    mapping(address subject => mapping(bytes32 key => StringSet expected)) recordedExpected;
    StringSet tempExpected;
    StringSet actual;
}

library StringSetComparatorRepo {
    using StringSetRepo for StringSet;
    using BetterAddress for address;

    bytes32 private constant STORAGE_RANGE_OFFSET = keccak256(abi.encode(type(StringSetComparatorRepo).name));

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (StringSetComparatorLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }

    function _stringSetCompare(bytes32 actualHash) internal pure returns (StringSetComparatorLayout storage) {
        return _layout((actualHash ^ STORAGE_RANGE_OFFSET));
    }

    function _recExpected(address subject, bytes32 func, string memory expected) internal {
        _stringSetCompare(subject._toBytes32()).recordedExpected[subject][func]._add(expected);
    }

    function _recExpected(address subject, bytes32 func, string[] memory expected) internal {
        _stringSetCompare(subject._toBytes32()).recordedExpected[subject][func]._add(expected);
    }

    function _recedExpected(address subject, bytes32 func) internal view returns (StringSet storage) {
        return _stringSetCompare(subject._toBytes32()).recordedExpected[subject][func];
    }

    function _tempExpected(bytes32 actualHash) internal view returns (StringSet storage) {
        return _stringSetCompare(actualHash).tempExpected;
    }

    function _actual(bytes32 actualHash) internal view returns (StringSet storage) {
        return _stringSetCompare(actualHash).actual;
    }
}

library StringSetComparator {
    using StringSetRepo for StringSet;
    using BetterEfficientHashLib for bytes;

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

    // IMPROVE Add version accepting storage pointer to expected.
    function _logCompare(StringComparatorRequest memory request) internal returns (bool matches) {
        SetComparatorResults memory result = _compare(request.expected, request.actual);
        matches = SetComparatorLogger._logResult(result, request.errorMsg);
    }

    // IMPROVE Add version accepting storage pointer to expected.
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
}
