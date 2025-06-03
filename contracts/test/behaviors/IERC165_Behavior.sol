// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    IERC165
} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// import "hardhat/console.sol";
// import "forge-std/console.sol";
// import "forge-std/console2.sol";
import {betterconsole as console} from "../../utils/vm/foundry/tools/betterconsole.sol";

import {
    Behavior
} from "./Behavior.sol";



import {
    BetterAddress as Address
} from "../../utils/BetterAddress.sol";
import {
    BetterBytes as Bytes
} from "../../utils/BetterBytes.sol";

import {
    Bytes4
} from "../../utils/Bytes4.sol";

import {
    Bytes32
} from "../../utils/Bytes32.sol";

import {
    BetterStrings as Strings
} from "../../utils/BetterStrings.sol";

import {
    UInt256
} from "../../utils/UInt256.sol";



import {
    AddressSet,
    AddressSetRepo
} from "../../utils/collections/sets/AddressSetRepo.sol";
import {
    Bytes4Set,
    Bytes4SetRepo
} from "../../utils/collections/sets/Bytes4SetRepo.sol";
import {
    BetterMath as Math
} from "../../utils/math/BetterMath.sol";



import {
    Bytes4SetComparator
} from "../../test/comparators/sets/Bytes4SetComparator.sol";


/**
 * @title IERC165_Behavior  
 * @notice This contract provides a behavior for the IERC165 interface.
 * @dev Validates that contracts correctly implement the IERC165 interface
 *      by checking interface support declarations and validating actual support.
 */
contract IERC165_Behavior
is
Behavior,
Bytes4SetComparator
{

    /* ------------------------------ Library Usage ------------------------------ */

    using Address for address;
    using Bytes for bytes;
    using Bytes4 for bytes4;
    using Bytes32 for bytes32;
    using Strings for string;
    using UInt256 for uint256;

    using AddressSetRepo for AddressSet;
    using Bytes4SetRepo for Bytes4Set;

    /**
     * @notice Returns the name of the behavior.
     * @dev Used to prefix to identify which Behavior is logging.
     * @return The name of the behavior.
     */
    function _ierc165_behaviorName()
    internal pure returns(string memory) {
        return type(IERC165_Behavior).name;
    }

    /**
     * @notice Returns the error prefix function for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @return The error prefix.
     */
    function _ierc165_errPrefixFunc(
        string memory testedFuncSig
    ) internal view virtual returns(string memory) {
        return _errPrefixFunc(
            _ierc165_behaviorName(),
            testedFuncSig
        );
    }

    /**
     * @notice Returns the error prefix for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @param subjectLabel The label of the subject being tested.
     * @return The error prefix.
     */
    function _ierc165_errPrefix(
        string memory testedFuncSig,
        string memory subjectLabel
    ) internal view virtual returns(string memory) {
        return string.concat(
            _ierc165_errPrefixFunc(testedFuncSig),
            subjectLabel
        );
    }

    /**
     * @notice Returns the error prefix for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @param subject The address of the subject being tested.
     * @return The error prefix.
     */
    function _ierc165_errPrefix(
        string memory testedFuncSig,
        address subject
    ) internal view virtual returns(string memory) {
        return _ierc165_errPrefix(
            testedFuncSig,
            vm.getLabel(subject)
        );
    }

    /* ---------------------- supportsInterFace(bytes4) --------------------- */

    /**
     * @notice Returns the IERC165.supportsInterface function signature.
     * @return The function signature.
     */
    function funcSig_IERC165_supportsInterFace()
    public pure returns(string memory) {
        return "supportsInterFace(bytes4)";
    }

    /**
     * @notice Returns the error prefix for the supportsInterface function.
     * @return The error prefix.
     */
    function _errPrefix_IERC165_supportsInterFace(
        string memory subjectLabel
    ) internal view returns(string memory) {
        return _ierc165_errPrefix(
            funcSig_IERC165_supportsInterFace(),
            subjectLabel
        );
    }

    /**
     * @notice Returns the error body for the supportsInterface function.
     * @return The error body.
     */
    function errBody_IERC165_supportsInterFace()
    public pure returns(string memory) {
        return "Interface support mismatch";
    }

    /**
     * @notice Checks if booleans are equal.
     * @notice Mostly included to keep testing patterns of interfaces consistent.
     */
    function isValid_IERC165_supportsInterfaces(
        string memory subjectLabel,
        bool expected,
        bool actual
    ) public view returns(bool isValid) {
        console.logBehaviorEntry(_ierc165_behaviorName(), "isValid_IERC165_supportsInterfaces");
        
        isValid = expected == actual;
        if(!isValid) {
            console.logBehaviorError(
                _ierc165_behaviorName(),
                "isValid_IERC165_supportsInterfaces",
                _errPrefix_IERC165_supportsInterFace(subjectLabel),
                errBody_IERC165_supportsInterFace()
            );
            console.logBehaviorCompare(
                _ierc165_behaviorName(),
                "isValid_IERC165_supportsInterfaces",
                "interface support",
                expected ? "true" : "false",
                actual ? "true" : "false"
            );
        }

        console.logBehaviorValidation(
            _ierc165_behaviorName(),
            "isValid_IERC165_supportsInterfaces",
            "interface support",
            isValid
        );

        console.logBehaviorExit(_ierc165_behaviorName(), "isValid_IERC165_supportsInterfaces");
        return isValid;
    }

    function isValid_IERC165_supportsInterfaces(
        IERC165 subject,
        bool expected,
        bool actual
    ) public view returns(bool valid) {
        return isValid_IERC165_supportsInterfaces(
            vm.getLabel(address(subject)),
            expected,
            actual
        );
    }

    function expect_IERC165_supportsInterface(
        IERC165 subject,
        bytes4[] memory expectedInterfaces_
    ) public {
        console.logBehaviorEntry(_ierc165_behaviorName(), "expect_IERC165_supportsInterface");
        
        console.logBehaviorExpectation(
            _ierc165_behaviorName(),
            "expect_IERC165_supportsInterface",
            "interfaces",
            string.concat("count: ", expectedInterfaces_.length.toString())
        );
        
        _recExpectedBytes4(
            address(subject),
            IERC165.supportsInterface.selector,
            expectedInterfaces_
        );
        
        console.logBehaviorExit(_ierc165_behaviorName(), "expect_IERC165_supportsInterface");
    }

    function _expected_IERC165_supportsInterface(
        IERC165 subject
    ) internal view returns(Bytes4Set storage) {
        return _recedExpectedBytes4(
            address(subject),
            IERC165.supportsInterface.selector
        );
    }

    function hasValid_IERC165_supportsInterface(
        IERC165 subject
    ) public view returns(bool isValid_) {
        console.logBehaviorEntry(_ierc165_behaviorName(), "hasValid_IERC165_supportsInterface");
        
        isValid_ = true;
        uint256 expectedCount = _expected_IERC165_supportsInterface(subject)._length();
        
        console.logBehaviorValidation(
            _ierc165_behaviorName(),
            "hasValid_IERC165_supportsInterface",
            "expected interface count",
            expectedCount > 0
        );
        
        for(uint256 index = 0; index < expectedCount; index++) {
            bytes4 interfaceId = _expected_IERC165_supportsInterface(subject)._index(index);
            bool result = isValid_IERC165_supportsInterfaces(
                subject,
                true,
                subject.supportsInterface(interfaceId)
            );
            if (!result) {
                console.logBehaviorError(
                    _ierc165_behaviorName(),
                    "hasValid_IERC165_supportsInterface",
                    "Interface not supported",
                    interfaceId.toHexString()
                );
            }
            isValid_ = isValid_ && result;
        }
        
        console.logBehaviorValidation(
            _ierc165_behaviorName(),
            "hasValid_IERC165_supportsInterface",
            "all interfaces",
            isValid_
        );
        
        console.logBehaviorExit(_ierc165_behaviorName(), "hasValid_IERC165_supportsInterface");
    }

}