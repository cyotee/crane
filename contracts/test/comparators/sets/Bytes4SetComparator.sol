// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;
import {betterconsole as console} from "../../../utils/vm/foundry/tools/betterconsole.sol";
import {
    BetterAddress as Address
} from "../../../utils/BetterAddress.sol";
import {
    BetterBytes as Bytes
} from "../../../utils/BetterBytes.sol";
import {
    Bytes4
} from "../../../utils/Bytes4.sol";
import {
    Bytes32
} from "../../../utils/Bytes32.sol";
import {
    BetterStrings as Strings
} from "../../../utils/BetterStrings.sol";
import {
    UInt256
} from "../../../utils/UInt256.sol";
import {
    Bytes4Set,
    Bytes4SetRepo
} from "../../../utils/collections/sets/Bytes4SetRepo.sol";
import {
    BetterMath
} from "../../../utils/math/BetterMath.sol";

import {
    ErrorMsg,
    Comparator
} from "../../../test/comparators/Comparator.sol";

import {
    SetComparatorResults,
    SetComparator
} from "../../../test/comparators/sets/SetComparator.sol";

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

    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(
        bytes32 slot_
    ) internal pure returns(Bytes4SetComparatorLayout storage layout_) {
        assembly{layout_.slot := slot_}
    }
   
}

contract Bytes4SetComparatorStorage
{

    using Bytes4SetComparatorRepo for bytes32;

    using Address for address;
    using Bytes for bytes;
    using Bytes4 for bytes4;
    using Bytes4 for bytes4[];
    using Bytes32 for bytes32;
    using Strings for string;
    using UInt256 for uint256;
    // using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    // using Bytes32SetRepo for Bytes32Set;
    // using StringSetRepo for StringSet;
    // using UInt256SetRepo for UInt256Set;

    using BetterMath for uint256;

    // using Bytes4Matcher for address;

    address private constant LAYOUT_ID
        = address(uint160(uint256(keccak256(type(Bytes4SetComparatorRepo).creationCode))));
        // = address(Bytes4SetComparatorRepo);
    bytes32 private constant STORAGE_RANGE_OFFSET
        = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    // bytes32 private constant STORAGE_RANGE
    //     = type(IStandardVault).interfaceId;
    // bytes32 private constant STORAGE_SLOT
    //     = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    function _b4SetCompare(bytes32 actualHash)
    internal pure returns(Bytes4SetComparatorLayout storage) {
        return (actualHash ^ STORAGE_RANGE_OFFSET)._layout();
    }

    function _recExpectedBytes4(
        address subject,
        bytes4 func,
        bytes4[] memory expected
    ) internal {
        _b4SetCompare(subject.toBytes32())
        .recordedExpected[subject][func]._add(expected);
    }

    function _recedExpectedBytes4(
        address subject,
        bytes4 func
    ) internal view returns(Bytes4Set storage) {
        return _b4SetCompare(subject.toBytes32()).recordedExpected[subject][func];
    }

    function _tempExpectedBytes4(
        bytes32 actualHash
    ) internal view returns(Bytes4Set storage) {
        return _b4SetCompare(actualHash).tempExpected;
    }

    function _actualBytes4(
        bytes32 actualHash
    ) internal view returns(Bytes4Set storage) {
        return _b4SetCompare(actualHash).actual;
    }

}

contract Bytes4SetComparator
is
Bytes4SetComparatorStorage,
SetComparator
{

    using Address for address;
    using Bytes for bytes;
    using Bytes4 for bytes4;
    using Bytes4 for bytes4[];
    using Bytes32 for bytes32;
    using Strings for string;
    using UInt256 for uint256;
    // using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;
    // using Bytes32SetRepo for Bytes32Set;
    // using StringSetRepo for StringSet;
    // using UInt256SetRepo for UInt256Set;

    using BetterMath for uint256;

    function _compare(
        bytes4[] memory expected,
        bytes4[] memory actual,
        string memory errorPrefix,
        string memory errorSuffix
    ) internal returns (bool) {
        console.log("Bytes4SetComparator:_compare:: Entering function.");
        
        // Add logging for array lengths
        console.log("Expected array length = ", expected.length);
        console.log("Actual array length = ", actual.length);

        // Log arrays
        console.log("Expected values:", expected);
        console.log("Actual values:", actual);

        bool matches = _logCompare(
            Bytes4ComparatorRequest({
                expected: expected,
                actual: actual,
                errorMsg: ErrorMsg({
                    prefix: errorPrefix,
                    suffix: errorSuffix
                })
            })
        );
        console.log("Bytes4SetComparator:_compare:: Exiting function.");
        return matches;
    }

    // IMPROVE Add version accepting storage pointer to expected.
    function _logCompare(
        Bytes4ComparatorRequest memory request
    ) internal returns(
        bool matches
    ) {
        SetComparatorResults memory result
        = _compare(request.expected, request.actual);
        matches = _logResult(
            result,
            request.errorMsg
        );

    }

    // IMPROVE Add version accepting storage pointer to expected.
    function _compare(
        bytes4[] memory expected,
        bytes4[] memory actual
    ) internal returns(
        SetComparatorResults memory result
    ) {
        console.log("Bytes4SetComparator:_compare:: Entering function.");
        // matches = true;
        bytes32 ah = keccak256(abi.encode(actual));
        result.actualArgLength = actual.length;
        console.log("Storing expected to detect duplicates.");
        _tempExpectedBytes4(ah)._add(expected);
        console.log("Checking for duplicates.");
        if(
            expected.length
            != _tempExpectedBytes4(ah)._length()
        ) {
            console.log(
                "Bytes4Set expectations MUST NOT contain duplicates. Provide expectations as FIRST argument.",
                expected
            );
            // Calculate absolute difference to avoid underflow
            unchecked {
                uint256 expectedLen = expected.length;
                uint256 tempLen = _tempExpectedBytes4(ah)._length();
                result.expectedMisses = expectedLen >= tempLen ? expectedLen - tempLen : tempLen - expectedLen;
                result.actualMisses = actual.length;
            }
            return result;
        }
        _actualBytes4(ah)._add(actual);
        result.actualCheckLength = _actualBytes4(ah)._length();
        result.expectedCheckLength = _tempExpectedBytes4(ah)._length();
        for(uint256 expectedCursor = 0; expectedCursor < _tempExpectedBytes4(ah)._length(); expectedCursor++) {
            if(
                !_actualBytes4(ah)._contains(
                    _tempExpectedBytes4(ah)._index(expectedCursor)
                )
            ) {
                result.expectedMisses++;
            }
        }
        for(uint256 actualCursor = 0; actualCursor < _actualBytes4(ah)._length(); actualCursor++) {
            if(
                !_tempExpectedBytes4(ah)._contains(
                    _actualBytes4(ah)._index(actualCursor)
                )
            ) {
                result.actualMisses++;
            }
        }
        console.log("Bytes4SetComparator:_compare:: Exiting function.");
        return result;
    }

}