// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";
import {Vm, VmSafe} from "forge-std/Vm.sol";

import "../../../../constants/Constants.sol";
import "../FoundryConstants.sol";
import {Address} from "../../../primitives/Address.sol";
import {Bytes} from "../../../primitives/Bytes.sol";
import {UInt} from "../../../primitives/UInt.sol";

library betterconsole {

    using Address for address;
    using Bytes for bytes;
    using UInt for uint256;

    Vm constant vm = Vm(VM_ADDRESS);

    function log(string memory logMsg) internal pure {
        console.log(logMsg);
    }

    function log(
        string memory logPrefix,
        string memory logMsg
    ) internal pure {
        log(string.concat(logPrefix, logMsg));
    }

    function log(
        string memory logMsg,
        bool value
    ) internal pure {
        log(string.concat(logMsg, value ? "true" : "false"));
    }

    function log(
        string memory logMsg,
        bytes32 value
    ) internal pure {
        log(string.concat(logMsg, "0x", uint256(value)._toHexString()));
    }

    function log(
        string memory logMsg,
        address addr
    ) internal pure {
        log(string.concat(logMsg, addr._toString()));
    }

    function log(
        string memory logMsg,
        uint256 num
    ) internal pure {
        log(string.concat(logMsg, num._toString()));
    }

    function log(
        string memory logMsg,
        bytes memory data
    ) internal pure {
        log(logMsg);
        log(DIV);
        console.logBytes(data);
        log(DIV);
    }

    function log(
        string memory logMsg,
        bytes4[] memory values
    ) internal pure {
        log(logMsg);
        log("values length = ", values.length);
        log(DIV);
        for(uint256 i = 0; i < values.length; i++) {
            console.logBytes4(values[i]);
        }
        log(DIV);
    }

    /* ---------------------------------------------------------------------- */
    /*                            Function Logging                            */
    /* ---------------------------------------------------------------------- */

    function logFuncMsg(
        string memory contractName,
        string memory functionSig,
        string memory logMsg
    ) internal pure {
        log(
            string.concat(
                contractName,
                ":",
                functionSig,
                ":: ",
                logMsg
            )
        );
    }

    function logEntry(
        string memory contractName,
        string memory functionSig
    ) internal pure {
        logFuncMsg(
            contractName,
            functionSig,
            ":: Entering function."
        );
    }

    function logExit(
        string memory contractName,
        string memory functionSig
    ) internal pure {
        logFuncMsg(
            contractName,
            functionSig,
            ":: Exiting function."
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                             Comparison Logs                            */
    /* ---------------------------------------------------------------------- */

    function logCompare(
        string memory subjectLabel,
        string memory logBody,
        string memory expectedLog,
        string memory actualLog
    ) internal pure {
        console.log(
            "subject: ",
            subjectLabel
        );
        if(bytes(logBody).length > 0) {
            console.log(
                logBody
            );
        }
        console.log(
            "expected: ",
            expectedLog
        );
        console.log(
            "actual: ",
            actualLog
        );
    }

    function logCompare(
        string memory subjectLabel,
        string memory logBody,
        address expected,
        address actual
    ) internal view {
        logCompare(
            subjectLabel,
            logBody,
            string.concat(vm.getLabel(expected), " :: ", expected._toString()),
            string.concat(vm.getLabel(actual), " :: ", actual._toString())
        );
    }

    function logCompare(
        string memory subjectLabel,
        string memory logBody,
        bytes32 expected,
        bytes32 actual
    ) internal pure {
        logCompare(
            subjectLabel,
            logBody,
            uint256(expected)._toHexString(),
            uint256(actual)._toHexString()
        );
    }

}