// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {BetterAddress as Address} from "contracts/crane/utils/BetterAddress.sol";
import {BetterBytes as Bytes} from "contracts/crane/utils/BetterBytes.sol";
import {Bytes4} from "contracts/crane/utils/Bytes4.sol";
import {Bytes32} from "@crane/src/utils/Bytes32.sol";
import {BetterStrings as Strings} from "contracts/crane/utils/BetterStrings.sol";
import {UInt256} from "contracts/crane/utils/UInt256.sol";
import {BetterMath} from "contracts/crane/utils/math/BetterMath.sol";

import {ErrorMsg, Comparator} from "contracts/crane/test/comparators/Comparator.sol";

struct SetComparatorResults {
    bool hasDupes;
    uint256 actualArgLength;
    uint256 actualCheckLength;
    uint256 expectedCheckLength;
    uint256 expectedMisses;
    uint256 actualMisses;
}

contract SetComparator is

    // FoundryVM,
    Comparator
{
    using Address for address;
    using Bytes for bytes;
    using Bytes4 for bytes4;
    using Bytes4 for bytes4[];
    using Bytes32 for bytes32;
    using Strings for string;
    using UInt256 for uint256;
    // using AddressSetRepo for AddressSet;
    // using Bytes4SetRepo for Bytes4Set;
    // using Bytes32SetRepo for Bytes32Set;
    // using StringSetRepo for StringSet;
    // using UInt256SetRepo for UInt256Set;

    using BetterMath for uint256;

    error ExpectedActualSizeMismatch(uint256 expectedSize, uint256 actualSize);

    function _logResult(SetComparatorResults memory result, ErrorMsg memory errorMsg)
        internal
        pure
        returns (bool isValid)
    {
        isValid = true;
        if (result.actualArgLength > result.actualCheckLength) {
            isValid = false;
            _logDupes(result, errorMsg);
        }
        if (result.actualCheckLength != result.expectedCheckLength) {
            isValid = false;
            _logLengthMismatch(result, errorMsg);
        }
        if (result.expectedMisses > 0) {
            isValid = false;
            _logExpectedMisses(result, errorMsg);
        }
        if (result.actualMisses > 0) {
            isValid = false;
            _logActualMisses(result, errorMsg);
        }
    }

    function _logDupes(SetComparatorResults memory result, ErrorMsg memory errorMsg) internal pure {
        console.log(
            string.concat(
                errorMsg.prefix,
                " declares ",
                (result.actualArgLength - result.actualCheckLength).toString(),
                " duplicate ",
                errorMsg.suffix,
                "."
            )
        );
    }

    function _logLengthMismatch(
        uint256 expectedLen,
        uint256 actualLen,
        string memory errorPrefix,
        string memory errorSuffix
    ) internal pure {
        // IMPROVE more granular log message.
        console.log(
            string.concat(
                errorPrefix,
                " declaration mismatch ",
                actualLen.diff(expectedLen).toString(),
                actualLen > expectedLen ? " UNEXPECTED " : " NOT DECLARED ",
                errorSuffix,
                "."
            )
        );
    }

    function _logLengthMismatch(SetComparatorResults memory result, ErrorMsg memory errorMsg) internal pure {
        // IMPROVE more granular log message.
        // console.log(
        //     string.concat(
        //         errorMsg.prefix,
        //         " declaration mismatch ",
        //         result.actualCheckLength
        //         ._diff(result.expectedCheckLength)._toString(),
        //         result.actualCheckLength > result.expectedCheckLength
        //         ? " UNEXPECTED "
        //         : " NOT DECLARED ",
        //         errorMsg.suffix,
        //         "."
        //     )
        // );
        _logLengthMismatch(
            // uint256 expectedLen,
            result.expectedCheckLength,
            // uint256 actualLen,
            result.actualCheckLength,
            // string memory errorPrefix,
            errorMsg.prefix,
            // string memory errorSuffix
            errorMsg.suffix
        );
    }

    function _logExpectedMisses(SetComparatorResults memory result, ErrorMsg memory errorMsg) internal pure {
        console.log(
            string.concat(
                errorMsg.prefix,
                " does NOT declare ",
                result.expectedMisses.toString(),
                " expected ",
                errorMsg.suffix,
                "."
            )
        );
    }

    function _logActualMisses(SetComparatorResults memory result, ErrorMsg memory errorMsg) internal pure {
        console.log(
            string.concat(
                errorMsg.prefix, " DOES declare ", result.actualMisses.toString(), " UNEXPECTED ", errorMsg.suffix, "."
            )
        );
    }
}
