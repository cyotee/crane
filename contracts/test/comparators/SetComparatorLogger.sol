// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ErrorMsg, ComparatorLogger} from "contracts/test/comparators/ComparatorLogger.sol";
import {BetterMath} from "contracts/utils/math/BetterMath.sol";
import {UInt256} from "contracts/utils/UInt256.sol";

struct SetComparatorResults {
    bool hasDupes;
    uint256 actualArgLength;
    uint256 actualCheckLength;
    uint256 expectedCheckLength;
    uint256 expectedMisses;
    uint256 actualMisses;
}

error ExpectedActualSizeMismatch(uint256 expectedSize, uint256 actualSize);

library SetComparatorLogger {
    using BetterMath for uint256;
    using UInt256 for uint256;

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
                UInt256._toString((result.actualArgLength - result.actualCheckLength)),
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
                actualLen._diff(expectedLen)._toString(),
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
                result.expectedMisses._toString(),
                " expected ",
                errorMsg.suffix,
                "."
            )
        );
    }

    function _logActualMisses(SetComparatorResults memory result, ErrorMsg memory errorMsg) internal pure {
        console.log(
            string.concat(
                errorMsg.prefix, " DOES declare ", result.actualMisses._toString(), " UNEXPECTED ", errorMsg.suffix, "."
            )
        );
    }
}
