// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "forge-std/console.sol";
import "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";

import "../../../../../constants/Constants.sol";
import "../../FoundryConstants.sol";
import {Address} from "../../../../primitives/Address.sol";
import {Bytes} from "../../../../primitives/Bytes.sol";
import {UInt} from "../../../../primitives/UInt.sol";

library betterconsole {

    using Address for address;
    using Bytes for bytes;
    using UInt for uint256;

    Vm constant vm = Vm(VM_ADDRESS);

    function log(string memory logMsg) public pure {
        console.log(logMsg);
    }

    function log(
        string memory logMsg,
        string memory logMsg2,
        string memory logMsg3
    ) public pure {
        console.log(string.concat(logMsg, logMsg2, logMsg3));
    }

    
    function log(
        string memory logMsg,
        uint256 num,
        address addr
    ) public pure {
        console.log(string.concat(logMsg, num._toString(), addr._toString()));
    }


    function logBytes32(bytes32 value) public pure {
        console.logBytes32(value);
    }

    function log(
        string memory logPrefix,
        string memory logMsg
    ) public pure {
        log(string.concat(logPrefix, logMsg));
    }

    function log(
        string memory logMsg,
        bool value
    ) public pure {
        log(string.concat(logMsg, value ? "true" : "false"));
    }

    function log(
        string memory logMsg,
        bytes32 value
    ) public pure {
        log(string.concat(logMsg, "0x", uint256(value)._toHexString()));
    }

    function log(
        string memory logMsg,
        address addr
    ) public pure {
        log(string.concat(logMsg, addr._toString()));
    }

    function log(
        string memory logMsg,
        uint256 num
    ) public pure {
        log(string.concat(logMsg, num._toString()));
    }

    function log(
        string memory logMsg,
        bytes memory data
    ) public pure {
        log(logMsg);
        log(DIV);
        console.logBytes(data);
        log(DIV);
    }

    function log(
        string memory logMsg,
        bytes4[] memory values
    ) public pure {
        log(logMsg);
        log("values length = ", values.length);
        log(DIV);
        for(uint256 i = 0; i < values.length; i++) {
            console.logBytes4(values[i]);
        }
        log(DIV);
    }

    function log(
        string memory logMsg1,
        address addr1,
        string memory logMsgs2,
        address addr2,
        string memory logMsgs3,
        uint256 num
    ) public pure {
        console.log(string.concat(logMsg1, addr1._toString(), logMsgs2, addr2._toString(), logMsgs3, num._toString()));
    }

    function log(
        string memory logMsg1,
        address addr1,
        string memory logMsgs2,
        address addr2,
        string memory logMsgs3,
        uint256 num,
        string memory logMsg4,
        address addr3
    ) public pure {
        console.log(string.concat(logMsg1, addr1._toString(), logMsgs2, addr2._toString(), logMsgs3, num._toString(), logMsg4, addr3._toString()));
    }

    function log(
        string memory logMsg1,
        uint256 num1,
        bool bool1
    ) public pure {
        console.log(string.concat(logMsg1, num1._toString(), bool1 ? "true" : "false"));
    }

    /* ---------------------------------------------------------------------- */
    /*                            Function Logging                            */
    /* ---------------------------------------------------------------------- */

    function logFuncMsg(
        string memory contractName,
        string memory functionSig,
        string memory logMsg
    ) public pure {
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
    ) public pure {
        logFuncMsg(
            contractName,
            functionSig,
            ":: Entering function."
        );
    }

    function logExit(
        string memory contractName,
        string memory functionSig
    ) public pure {
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
    ) public pure {
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
    ) public view {
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
    ) public pure {
        logCompare(
            subjectLabel,
            logBody,
            uint256(expected)._toHexString(),
            uint256(actual)._toHexString()
        );
    }

    /* ------------------------ Behavior Debug Logging ----------------------- */

    function logBehaviorEntry(
        string memory behaviorName,
        string memory functionName
    ) public pure {
        log(
            string.concat(
                behaviorName,
                ":",
                functionName,
                ":: Entering function."
            )
        );
    }

    function logBehaviorExit(
        string memory behaviorName,
        string memory functionName
    ) public pure {
        log(
            string.concat(
                behaviorName,
                ":",
                functionName,
                ":: Exiting function."
            )
        );
    }

    function logBehaviorExpectation(
        string memory behaviorName,
        string memory functionName,
        string memory expectationType,
        string memory expectedValue
    ) public pure {
        log(
            string.concat(
                behaviorName,
                ":",
                functionName,
                ":: Expecting ",
                expectationType,
                " to be ",
                expectedValue
            )
        );
    }

    function logBehaviorValidation(
        string memory behaviorName,
        string memory functionName,
        string memory validationType,
        bool isValid
    ) public pure {
        log(
            string.concat(
                behaviorName,
                ":",
                functionName,
                ":: ",
                validationType,
                " is ",
                isValid ? "valid" : "invalid"
            )
        );
    }

    function logBehaviorProcessing(
        string memory behaviorName,
        string memory functionName,
        string memory processType,
        string memory processValue
    ) public pure {
        log(
            string.concat(
                behaviorName,
                ":",
                functionName,
                ":: Processing ",
                processType,
                ": ",
                processValue
            )
        );
    }

    function logBehaviorCompare(
        string memory behaviorName,
        string memory functionName,
        string memory compareType,
        string memory expected,
        string memory actual
    ) public pure {
        log(
            string.concat(
                behaviorName,
                ":",
                functionName,
                ":: Comparing ",
                compareType
            )
        );
        logCompare(
            string.concat(behaviorName, ":", functionName),
            "",
            expected,
            actual
        );
    }

    function logBehaviorCompare(
        string memory behaviorName,
        string memory functionName,
        string memory compareType,
        address expected,
        address actual
    ) public view {
        log(
            string.concat(
                behaviorName,
                ":",
                functionName,
                ":: Comparing ",
                compareType
            )
        );
        logCompare(
            string.concat(behaviorName, ":", functionName),
            "",
            expected,
            actual
        );
    }

    function logBehaviorCompare(
        string memory behaviorName,
        string memory functionName,
        string memory compareType,
        bytes32 expected,
        bytes32 actual
    ) public pure {
        log(
            string.concat(
                behaviorName,
                ":",
                functionName,
                ":: Comparing ",
                compareType
            )
        );
        logCompare(
            string.concat(behaviorName, ":", functionName),
            "",
            expected,
            actual
        );
    }

    function logBehaviorError(
        string memory behaviorName,
        string memory functionName,
        string memory errorPrefix,
        string memory errorSuffix
    ) public pure {
        log(
            string.concat(
                behaviorName,
                ":",
                functionName,
                ":: ",
                errorPrefix,
                " UNEXPECTED ",
                errorSuffix
            )
        );
    }
   
}