// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Vm} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {BehaviorUtils} from "@crane/contracts/test/behaviors/BehaviorUtils.sol";
import {Bytes4SetComparatorRepo, Bytes4SetComparator} from "@crane/contracts/test/comparators/Bytes4SetComparator.sol";
import {UInt256} from "@crane/contracts/utils/UInt256.sol";
import {Bytes4} from "@crane/contracts/utils/Bytes4.sol";

library Behavior_IERC165 {
    using Bytes4 for bytes4;
    using Bytes4SetRepo for Bytes4Set;
    using UInt256 for uint256;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

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
    function _ierc165_errPrefixFunc(string memory testedFuncSig) internal pure returns (string memory) {
        return BehaviorUtils._errPrefixFunc(_Behavior_IERC165Name(), testedFuncSig);
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
        pure
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
    function _ierc165_errPrefix(string memory testedFuncSig, address subject) internal view returns (string memory) {
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
    function _errPrefix_IERC165_supportsInterFace(string memory subjectLabel) internal pure returns (string memory) {
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
        pure
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
            string.concat("count: ", expectedInterfaces_.length._toString())
        );

        Bytes4SetComparatorRepo._recExpectedBytes4(
            address(subject), IERC165.supportsInterface.selector, expectedInterfaces_
        );

        console.logBehaviorExit(_Behavior_IERC165Name(), "expect_IERC165_supportsInterface");
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _expected_IERC165_supportsInterface(IERC165 subject) internal view returns (Bytes4Set storage) {
        return Bytes4SetComparatorRepo._recedExpectedBytes4(address(subject), IERC165.supportsInterface.selector);
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
                    interfaceId._toHexString()
                );
            }
            isValid_ = isValid_ && result;
        }

        // Negative test: verify invalid interface returns false
        // 0xffffffff is explicitly invalid per ERC165 spec
        bool negativeResult =
            isValid_IERC165_supportsInterfaces(subject, false, subject.supportsInterface(bytes4(0xffffffff)));
        if (!negativeResult) {
            console.logBehaviorError(
                _Behavior_IERC165Name(),
                "hasValid_IERC165_supportsInterface",
                "Invalid interface 0xffffffff should return false",
                "always-true implementation detected"
            );
        }
        isValid_ = isValid_ && negativeResult;

        console.logBehaviorValidation(
            _Behavior_IERC165Name(), "hasValid_IERC165_supportsInterface", "all interfaces", isValid_
        );

        console.logBehaviorExit(_Behavior_IERC165Name(), "hasValid_IERC165_supportsInterface");
    }
}
