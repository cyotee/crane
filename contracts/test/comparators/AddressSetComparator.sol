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

struct AddressComparatorRequest {
    address[] expected;
    address[] actual;
    ErrorMsg errorMsg;
}

struct AddressSetComparatorLayout {
    mapping(address subject => mapping(bytes4 func => AddressSet expected)) recordedExpected;
    AddressSet tempExpected;
    AddressSet actual;
}

library AddressSetComparatorRepo {
    using AddressSetRepo for AddressSet;
    using BetterAddress for address;

    bytes32 private constant STORAGE_RANGE_OFFSET = keccak256(abi.encode(type(AddressSetComparatorRepo).name));

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (AddressSetComparatorLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }

    function _addrSetCompare(bytes32 actualHash) internal pure returns (AddressSetComparatorLayout storage) {
        return _layout((actualHash ^ STORAGE_RANGE_OFFSET));
    }

    function _recExpectedAddrs(address subject, bytes4 func, address expected) internal {
        _addrSetCompare(subject._toBytes32()).recordedExpected[subject][func]._add(expected);
    }

    function _recExpectedAddrs(address subject, bytes4 func, address[] memory expected) internal {
        _addrSetCompare(subject._toBytes32()).recordedExpected[subject][func]._add(expected);
    }

    function _recedExpectedAddrs(address subject, bytes4 func) internal view returns (AddressSet storage) {
        return _addrSetCompare(subject._toBytes32()).recordedExpected[subject][func];
    }

    function _tempExpectedAddrs(bytes32 actualHash) internal view returns (AddressSet storage) {
        return _addrSetCompare(actualHash).tempExpected;
    }

    function _actualAddrs(bytes32 actualHash) internal view returns (AddressSet storage) {
        return _addrSetCompare(actualHash).actual;
    }
}

library AddressSetComparator {
    using AddressSetRepo for AddressSet;
    using BetterEfficientHashLib for bytes;

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

    // IMPROVE Add version accepting storage pointer to expected.
    function _logCompare(AddressComparatorRequest memory request) internal returns (bool matches) {
        SetComparatorResults memory result = _compare(request.expected, request.actual);
        matches = SetComparatorLogger._logResult(result, request.errorMsg);
    }

    // IMPROVE Add version accepting storage pointer to expected.
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
}
