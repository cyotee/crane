// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "forge-std/console.sol";
// import "forge-std/console2.sol";

import {
    FoundryVM
} from "../../../utils/vm/foundry/FoundryVM.sol";

// import "contracts/crane/utils/Primitives.sol";
import {
    Address
} from "../../../utils/primitives/Address.sol";
import {
    Bytes
} from "../../../utils/primitives/Bytes.sol";
import {
    Bytes4
} from "../../../utils/primitives/Bytes4.sol";
import {
    Bytes32
} from "../../../utils/primitives/Bytes32.sol";
import {
    String
} from "../../../utils/primitives/String.sol";
import {
    UInt
} from "../../../utils/primitives/UInt.sol";
// import "contracts/crane/utils/Collections.sol";
import {
    BetterMath
} from "../../../utils/math/BetterMath.sol";

import {
    ErrorMsg,
    Comparator
} from "../Comparator.sol";

struct SetComparatorResults {
    bool hasDupes;
    uint256 actualArgLength;
    uint256 actualCheckLength;
    uint256 expectedCheckLength;
    uint256 expectedMisses;
    uint256 actualMisses;
}

contract SetComparator
is
FoundryVM,
Comparator
{

    using Address for address;
    using Bytes for bytes;
    using Bytes4 for bytes4;
    using Bytes4 for bytes4[];
    using Bytes32 for bytes32;
    using String for string;
    using UInt for uint256;
    // using AddressSetRepo for AddressSet;
    // using Bytes4SetRepo for Bytes4Set;
    // using Bytes32SetRepo for Bytes32Set;
    // using StringSetRepo for StringSet;
    // using UInt256SetRepo for UInt256Set;

    using BetterMath for uint256;

    error ExpectedActualSizeMismatch(
        uint256 expectedSize,
        uint256 actualSize
    );

    function _logResult(
        SetComparatorResults memory result,
        ErrorMsg memory errorMsg
    ) internal pure returns(bool isValid) {
        isValid = true;
        if(
            result.actualArgLength
            > result.actualCheckLength
        ) {
            isValid = false;
            _logDupes(result, errorMsg);
        }
        if(
            result.actualCheckLength
            != result.expectedCheckLength
        ) {
            isValid = false;
            _logLengthMismatch(result, errorMsg);
        }
        if(result.expectedMisses > 0) {
            isValid = false;
            _logExpectedMisses(result, errorMsg);
        }
        if(result.actualMisses > 0) {
            isValid = false;
            _logActualMisses(result, errorMsg);
        }
    }

    function _logDupes(
        SetComparatorResults memory result,
        ErrorMsg memory errorMsg
    ) internal pure {
        console.log(
            string.concat(
                errorMsg.prefix,
                " declares ",
                (result.actualArgLength - result.actualCheckLength)._toString(),
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
                actualLen
                ._diff(expectedLen)._toString(),
                actualLen > expectedLen
                ? " UNEXPECTED "
                : " NOT DECLARED ",
                errorSuffix,
                "."
            )
        );
    }

    function _logLengthMismatch(
        SetComparatorResults memory result,
        ErrorMsg memory errorMsg
    ) internal pure {
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

    function _logExpectedMisses(
        SetComparatorResults memory result,
        ErrorMsg memory errorMsg
    ) internal pure {
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

    function _logActualMisses(
        SetComparatorResults memory result,
        ErrorMsg memory errorMsg
    ) internal pure {
        console.log(
            string.concat(
                errorMsg.prefix,
                " DOES declare ",
                result.actualMisses._toString(),
                " UNEXPECTED ",
                errorMsg.suffix,
                "."
            )
        );
    }
    
}