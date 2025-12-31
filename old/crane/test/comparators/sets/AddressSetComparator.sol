// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

import {EfficientHashLib} from "@solady/utils/EfficientHashLib.sol";

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {BetterAddress as Address} from "contracts/crane/utils/BetterAddress.sol";
import {BetterBytes as Bytes} from "contracts/crane/utils/BetterBytes.sol";
import {Bytes4} from "contracts/crane/utils/Bytes4.sol";
import {Bytes32} from "@crane/src/utils/Bytes32.sol";
import {BetterStrings as Strings} from "contracts/crane/utils/BetterStrings.sol";
import {UInt256} from "contracts/crane/utils/UInt256.sol";
import {AddressSet, AddressSetRepo} from "@crane/src/utils/collections/sets/AddressSetRepo.sol";
import {BetterMath} from "contracts/crane/utils/math/BetterMath.sol";

import {ErrorMsg} from 
// Comparator
"contracts/crane/test/comparators/Comparator.sol";

import {SetComparatorResults, SetComparator} from "contracts/crane/test/comparators/sets/SetComparator.sol";

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
}

contract AddressSetComparatorStorage {
    using AddressSetComparatorRepo for bytes32;

    using Address for address;
    using Bytes for bytes;
    using Bytes4 for bytes4;
    using Bytes4 for bytes4[];
    using Bytes32 for bytes32;
    using EfficientHashLib for bytes;
    using Strings for string;
    using UInt256 for uint256;
    using AddressSetRepo for AddressSet;
    // using Bytes4SetRepo for Bytes4Set;
    // using Bytes32SetRepo for Bytes32Set;
    // using StringSetRepo for StringSet;
    // using UInt256SetRepo for UInt256Set;

    using BetterMath for uint256;

    // using Bytes4Matcher for address;

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(AddressSetComparatorRepo).name));
    // = address(AddressSetComparatorRepo);
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    // bytes32 private constant STORAGE_RANGE
    //     = type(IStandardVault).interfaceId;
    // bytes32 private constant STORAGE_SLOT
    //     = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    function _addrSetCompare(bytes32 actualHash) internal pure returns (AddressSetComparatorLayout storage) {
        return (actualHash ^ STORAGE_RANGE_OFFSET)._layout();
    }

    function _recExpectedAddrs(address subject, bytes4 func, address expected) internal {
        _addrSetCompare(subject.toBytes32()).recordedExpected[subject][func]._add(expected);
    }

    function _recExpectedAddrs(address subject, bytes4 func, address[] memory expected) internal {
        _addrSetCompare(subject.toBytes32()).recordedExpected[subject][func]._add(expected);
    }

    function _recedExpectedAddrs(address subject, bytes4 func) internal view returns (AddressSet storage) {
        return _addrSetCompare(subject.toBytes32()).recordedExpected[subject][func];
    }

    function _tempExpectedAddrs(bytes32 actualHash) internal view returns (AddressSet storage) {
        return _addrSetCompare(actualHash).tempExpected;
    }

    function _actualAddrs(bytes32 actualHash) internal view returns (AddressSet storage) {
        return _addrSetCompare(actualHash).actual;
    }
}

contract AddressSetComparator is AddressSetComparatorStorage, SetComparator {
    using Address for address;
    using Bytes for bytes;
    using Bytes4 for bytes4;
    using Bytes4 for bytes4[];
    using Bytes32 for bytes32;
    using EfficientHashLib for bytes;
    using Strings for string;
    using UInt256 for uint256;
    using AddressSetRepo for AddressSet;
    // using Bytes4SetRepo for Bytes4Set;
    // using Bytes32SetRepo for Bytes32Set;
    // using StringSetRepo for StringSet;
    // using UInt256SetRepo for UInt256Set;

    using BetterMath for uint256;

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
        matches = _logResult(result, request.errorMsg);
    }

    // IMPROVE Add version accepting storage pointer to expected.
    function _compare(address[] memory expected, address[] memory actual)
        internal
        returns (SetComparatorResults memory result)
    {
        // matches = true;
        // bytes32 ah = keccak256(abi.encode(actual));
        bytes32 ah = abi.encode(actual).hash();
        result.actualArgLength = actual.length;
        _tempExpectedAddrs(ah)._add(expected);
        if (expected.length != _tempExpectedAddrs(ah)._length()) {
            console.log("AddressSet expectations MUST NOT contain duplicates. Provide expectations as FIRST argument.");
            revert();
        }
        _actualAddrs(ah)._add(actual);
        result.actualCheckLength = _actualAddrs(ah)._length();
        result.expectedCheckLength = _tempExpectedAddrs(ah)._length();
        for (uint256 expectedCursor = 0; expectedCursor < _tempExpectedAddrs(ah)._length(); expectedCursor++) {
            if (!_actualAddrs(ah)._contains(_tempExpectedAddrs(ah)._index(expectedCursor))) {
                result.expectedMisses++;
            }
        }
        for (uint256 actualCursor = 0; actualCursor < _actualAddrs(ah)._length(); actualCursor++) {
            if (!_tempExpectedAddrs(ah)._contains(_actualAddrs(ah)._index(actualCursor))) {
                result.actualMisses++;
            }
        }
    }
}
