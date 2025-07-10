// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
// import "forge-std/console.sol";
// import "forge-std/console2.sol";
import {betterconsole as console} from "../../utils/vm/foundry/tools/betterconsole.sol";


struct ErrorMsg {
    string prefix;
    string suffix;
}

/**
 * @title Comparator
 * @notice Common comparison logic, mostly for logging comparison errors.
 */
contract Comparator
{

    function _logCompareError(
        string memory errorPrefix,
        string memory errorBody,
        string memory expectedLog,
        string memory actualLog
    ) internal pure {
        if(bytes(errorBody).length > 0) {
            console.log(string.concat(errorPrefix, ":: ", errorBody));
        } else {
            console.log(errorPrefix);
        }
        console.log("expected: ", expectedLog);
        console.log("actual: ", actualLog);
    }

    function _logCompareErrorBool(
        string memory errorPrefix,
        string memory errorBody,
        bool expected,
        bool actual
    ) internal pure {
        _logCompareError(
            errorPrefix,
            errorBody,
            expected == true ? "true" : "false",
            actual == true ? "true" : "false"
        );
    }
}