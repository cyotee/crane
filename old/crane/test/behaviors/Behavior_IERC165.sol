// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

// import "hardhat/console.sol";
// import "forge-std/console.sol";
// import "forge-std/console2.sol";
import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";

import {Behavior} from "contracts/crane/test/behaviors/Behavior.sol";

import {BetterAddress as Address} from "contracts/crane/utils/BetterAddress.sol";
import {BetterBytes as Bytes} from "contracts/crane/utils/BetterBytes.sol";

import {Bytes4} from "contracts/crane/utils/Bytes4.sol";

import {Bytes32} from "@crane/src/utils/Bytes32.sol";

import {BetterStrings as Strings} from "contracts/crane/utils/BetterStrings.sol";

import {UInt256} from "contracts/crane/utils/UInt256.sol";

import {AddressSet, AddressSetRepo} from "@crane/src/utils/collections/sets/AddressSetRepo.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/src/utils/collections/sets/Bytes4SetRepo.sol";
// import {
//     BetterMath as Math
// } from "contracts/crane/utils/math/BetterMath.sol";

import {Bytes4SetComparator} from "contracts/crane/test/comparators/sets/Bytes4SetComparator.sol";

/**
 * @title Behavior_IERC165
 * @notice This contract provides a behavior for the IERC165 interface.
 * @dev Validates that contracts correctly implement the IERC165 interface
 *      by checking interface support declarations and validating actual support.
 */
contract Behavior_IERC165 is Behavior, Bytes4SetComparator {
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
    /// forge-lint: disable-next-line(mixed-case-function)
    function _Behavior_IERC165Name() internal pure returns (string memory) {
        return type(Behavior_IERC165).name;
    }

    /**
     * @notice Returns the error prefix function for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _ierc165_errPrefixFunc(string memory testedFuncSig) internal view virtual returns (string memory) {
        return _errPrefixFunc(_Behavior_IERC165Name(), testedFuncSig);
    }

    /**
     * @notice Returns the error prefix for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @param subjectLabel The label of the subject being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _ierc165_errPrefix(string memory testedFuncSig, string memory subjectLabel)
        internal
        view
        virtual
        returns (string memory)
    {
        return string.concat(_ierc165_errPrefixFunc(testedFuncSig), subjectLabel);
    }

    /**
     * @notice Returns the error prefix for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @param subject The address of the subject being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _ierc165_errPrefix(string memory testedFuncSig, address subject)
        internal
        view
        virtual
        returns (string memory)
    {
        return _ierc165_errPrefix(testedFuncSig, vm.getLabel(subject));
    }

    /* ---------------------- supportsInterFace(bytes4) --------------------- */

    /**
     * @notice Returns the IERC165.supportsInterface function signature.
     * @return The function signature.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IERC165_supportsInterFace() public pure returns (string memory) {
        return "supportsInterFace(bytes4)";
    }

    /**
     * @notice Returns the error prefix for the supportsInterface function.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _errPrefix_IERC165_supportsInterFace(string memory subjectLabel) internal view returns (string memory) {
        return _ierc165_errPrefix(funcSig_IERC165_supportsInterFace(), subjectLabel);
    }

    /**
     * @notice Returns the error body for the supportsInterface function.
     * @return The error body.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function errBody_IERC165_supportsInterFace() public pure returns (string memory) {
        return "Interface support mismatch";
    }

    /**
     * @notice Checks if booleans are equal.
     * @notice Mostly included to keep testing patterns of interfaces consistent.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_IERC165_supportsInterfaces(string memory subjectLabel, bool expected, bool actual)
        public
        view
        returns (bool isValid)
    {
        console.logBehaviorEntry(_Behavior_IERC165Name(), "isValid_IERC165_supportsInterfaces");

        isValid = expected == actual;
        if (!isValid) {
            console.logBehaviorError(
                _Behavior_IERC165Name(),
                "isValid_IERC165_supportsInterfaces",
                _errPrefix_IERC165_supportsInterFace(subjectLabel),
                errBody_IERC165_supportsInterFace()
            );
            console.logBehaviorCompare(
                _Behavior_IERC165Name(),
                "isValid_IERC165_supportsInterfaces",
                "interface support",
                expected ? "true" : "false",
                actual ? "true" : "false"
            );
        }

        console.logBehaviorValidation(
            _Behavior_IERC165Name(), "isValid_IERC165_supportsInterfaces", "interface support", isValid
        );

        console.logBehaviorExit(_Behavior_IERC165Name(), "isValid_IERC165_supportsInterfaces");
        return isValid;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_IERC165_supportsInterfaces(IERC165 subject, bool expected, bool actual)
        public
        view
        returns (bool valid)
    {
        return isValid_IERC165_supportsInterfaces(vm.getLabel(address(subject)), expected, actual);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IERC165_supportsInterface(IERC165 subject, bytes4[] memory expectedInterfaces_) public {
        console.logBehaviorEntry(_Behavior_IERC165Name(), "expect_IERC165_supportsInterface");

        console.logBehaviorExpectation(
            _Behavior_IERC165Name(),
            "expect_IERC165_supportsInterface",
            "interfaces",
            string.concat("count: ", expectedInterfaces_.length.toString())
        );

        _recExpectedBytes4(address(subject), IERC165.supportsInterface.selector, expectedInterfaces_);

        console.logBehaviorExit(_Behavior_IERC165Name(), "expect_IERC165_supportsInterface");
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _expected_IERC165_supportsInterface(IERC165 subject) internal view returns (Bytes4Set storage) {
        return _recedExpectedBytes4(address(subject), IERC165.supportsInterface.selector);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_IERC165_supportsInterface(IERC165 subject) public view returns (bool isValid_) {
        console.logBehaviorEntry(_Behavior_IERC165Name(), "hasValid_IERC165_supportsInterface");

        isValid_ = true;
        uint256 expectedCount = _expected_IERC165_supportsInterface(subject)._length();

        console.logBehaviorValidation(
            _Behavior_IERC165Name(), "hasValid_IERC165_supportsInterface", "expected interface count", expectedCount > 0
        );

        for (uint256 index = 0; index < expectedCount; index++) {
            bytes4 interfaceId = _expected_IERC165_supportsInterface(subject)._index(index);
            bool result = isValid_IERC165_supportsInterfaces(subject, true, subject.supportsInterface(interfaceId));
            if (!result) {
                console.logBehaviorError(
                    _Behavior_IERC165Name(),
                    "hasValid_IERC165_supportsInterface",
                    "Interface not supported",
                    interfaceId.toHexString()
                );
            }
            isValid_ = isValid_ && result;
        }

        console.logBehaviorValidation(
            _Behavior_IERC165Name(), "hasValid_IERC165_supportsInterface", "all interfaces", isValid_
        );

        console.logBehaviorExit(_Behavior_IERC165Name(), "hasValid_IERC165_supportsInterface");
    }
}
