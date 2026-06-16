// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Vm} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {Bytes4Set, Bytes4SetRepo} from "@crane/contracts/utils/collections/sets/Bytes4SetRepo.sol";
import {BehaviorUtils} from "@crane/contracts/test/behaviors/BehaviorUtils.sol";
import {Bytes4SetComparatorRepo, Bytes4SetComparator} from "@crane/contracts/test/comparators/Bytes4SetComparator.sol";
import {UInt256} from "@crane/contracts/utils/UInt256.sol";
import {Bytes4} from "@crane/contracts/utils/Bytes4.sol";

// tag::Behavior_IERC165[]
/**
 * @notice Behavior_IERC165 - Behavior library encapsulating validation logic for IERC165 interface compliance testing (supportsInterface).
 * @dev Core for LR-7 ERC165 declaration and behavior tests (via TestBase_IERC165 and direct use in ERC165Facet.t.sol etc). Provides expect_*, hasValid_*, isValid_* helpers (and internal err/expected) that delegate to comparators + betterconsole logging.
 *      All IERC165 surface references use ONLY the centrally computed values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md:
 *        supportsInterface(bytes4): 0x01ffc9a7
 *      Pattern modeled exactly on recently closed Behavior_IFacet gold (rich prose, funcSig_* with custom tags, _*Name/_errPrefix* helpers, expect/hasValid/isValid patterns, hyphenated overload tags), Behavior_IERC165 context, TestBase_IERC165, AGENTS.md Behavior libraries section, PRD LR-1/LR-7.
 *      No behavior or logic changes: all console.logBehavior*, Bytes4SetComparatorRepo, UInt256, existing internal flows, negative 0xffffffff test, forge-lint disables, imports, using statements preserved exactly.
 *      "Storage" pattern N/A (pure behavior lib, not a Repo).
 *      Author: cyotee doge (not_cyotee at proton.me)
 */
library Behavior_IERC165 {
    using Bytes4 for bytes4;
    using Bytes4SetRepo for Bytes4Set;
    using UInt256 for uint256;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    // tag::_Behavior_IERC165Name()[]
    /**
     * @notice Returns the name of the behavior.
     * @dev Used to prefix to identify which Behavior is logging.
     * @return The name of the behavior.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _Behavior_IERC165Name() internal pure returns (string memory) {
        return type(Behavior_IERC165).name;
    }
    // end::_Behavior_IERC165Name()[]

    // tag::_ierc165_errPrefixFunc(string)[]
    /**
     * @notice Returns the error prefix function for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _ierc165_errPrefixFunc(string memory testedFuncSig) internal pure returns (string memory) {
        return BehaviorUtils._errPrefixFunc(_Behavior_IERC165Name(), testedFuncSig);
    }
    // end::_ierc165_errPrefixFunc(string)[]

    // tag::_ierc165_errPrefix(string-string)[]
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
    // end::_ierc165_errPrefix(string-string)[]

    // tag::_ierc165_errPrefix(string-address)[]
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
    // end::_ierc165_errPrefix(string-address)[]

    /* ---------------------- supportsInterFace(bytes4) --------------------- */

    // tag::funcSig_IERC165_supportsInterFace()[]
    /**
     * @notice Returns the IERC165.supportsInterface function signature for error messages and logging.
     * @return The function signature.
     * @custom:signature supportsInterface(bytes4)
     * @custom:selector 0x01ffc9a7
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_IERC165_supportsInterFace() public pure returns (string memory) {
        return "supportsInterFace(bytes4)";
    }
    // end::funcSig_IERC165_supportsInterFace()[]

    // tag::_errPrefix_IERC165_supportsInterFace(string)[]
    /**
     * @notice Returns the error prefix for the supportsInterface function.
     * @param subjectLabel The label of the subject being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _errPrefix_IERC165_supportsInterFace(string memory subjectLabel) internal pure returns (string memory) {
        return _ierc165_errPrefix(funcSig_IERC165_supportsInterFace(), subjectLabel);
    }
    // end::_errPrefix_IERC165_supportsInterFace(string)[]

    // tag::errBody_IERC165_supportsInterFace()[]
    /**
     * @notice Returns the error body for the supportsInterface function.
     * @return The error body.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function errBody_IERC165_supportsInterFace() public pure returns (string memory) {
        return "Interface support mismatch";
    }
    // end::errBody_IERC165_supportsInterFace()[]

    // tag::isValid_IERC165_supportsInterfaces(string-bool-bool)[]
    /**
     * @notice Checks if booleans are equal.
     * @dev Mostly included to keep testing patterns of interfaces consistent. (string label overload)
     * @param subjectLabel The label of the subject being tested.
     * @param expected The expected support value.
     * @param actual The actual support value returned by subject.
     * @return isValid True if expected == actual.
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
    // end::isValid_IERC165_supportsInterfaces(string-bool-bool)[]

    // tag::isValid_IERC165_supportsInterfaces(IERC165-bool-bool)[]
    /**
     * @notice Checks if booleans are equal (IERC165 subject overload; resolves label internally).
     * @param subject The subject contract being tested.
     * @param expected The expected support value.
     * @param actual The actual support value returned by subject.
     * @return valid True if expected == actual.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_IERC165_supportsInterfaces(IERC165 subject, bool expected, bool actual)
        public
        view
        returns (bool valid)
    {
        return isValid_IERC165_supportsInterfaces(vm.getLabel(address(subject)), expected, actual);
    }
    // end::isValid_IERC165_supportsInterfaces(IERC165-bool-bool)[]

    // tag::expect_IERC165_supportsInterface(IERC165-bytes4)[]
    /**
     * @notice Records expectation for a single interface ID (for later hasValid checks). Single-interface overload.
     * @dev Delegates storage to Bytes4SetComparatorRepo keyed by subject + selector.
     * @param subject The IERC165 subject under test.
     * @param expectedInterface_ The single expected interface ID.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IERC165_supportsInterface(IERC165 subject, bytes4 expectedInterface_) public {
        console.logBehaviorEntry(_Behavior_IERC165Name(), "expect_IERC165_supportsInterface");

        console.logBehaviorExpectation(
            _Behavior_IERC165Name(), "expect_IERC165_supportsInterface", "interfaces ", string.concat("count: ", "1")
        );

        Bytes4SetComparatorRepo._recExpectedBytes4(
            address(subject), IERC165.supportsInterface.selector, expectedInterface_
        );

        console.logBehaviorExit(_Behavior_IERC165Name(), "expect_IERC165_supportsInterface");
    }
    // end::expect_IERC165_supportsInterface(IERC165-bytes4)[]

    // tag::expect_IERC165_supportsInterface(IERC165-bytes4[])[]

    /**
     * @notice Records expectations for multiple interface IDs (for later hasValid checks). Array overload.
     * @dev Stores via Bytes4SetComparatorRepo. Used to setup for hasValid_IERC165_supportsInterface in TestBase_IERC165 etc.
     * @param subject The IERC165 subject under test.
     * @param expectedInterfaces_ The expected interface IDs array (including ERC165 self ID).
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_IERC165_supportsInterface(IERC165 subject, bytes4[] memory expectedInterfaces_) public {
        console.logBehaviorEntry(_Behavior_IERC165Name(), "expect_IERC165_supportsInterface");

        console.logBehaviorExpectation(
            _Behavior_IERC165Name(),
            "expect_IERC165_supportsInterface",
            "interfaces ",
            string.concat("count: ", expectedInterfaces_.length._toString())
        );

        Bytes4SetComparatorRepo._recExpectedBytes4(
            address(subject), IERC165.supportsInterface.selector, expectedInterfaces_
        );

        console.logBehaviorExit(_Behavior_IERC165Name(), "expect_IERC165_supportsInterface");
    }
    // end::expect_IERC165_supportsInterface(IERC165-bytes4[])[]

    // tag::_expected_IERC165_supportsInterface(IERC165)[]
    /**
     * @notice Internal accessor for the expected interfaces set previously recorded for the subject.
     * @dev Retrieves from Bytes4SetComparatorRepo.
     * @param subject The subject under test.
     * @return The Bytes4Set of expected interface IDs.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _expected_IERC165_supportsInterface(IERC165 subject) internal view returns (Bytes4Set storage) {
        return Bytes4SetComparatorRepo._recedExpectedBytes4(address(subject), IERC165.supportsInterface.selector);
    }
    // end::_expected_IERC165_supportsInterface(IERC165)[]

    // tag::hasValid_IERC165_supportsInterface(IERC165)[]
    /**
     * @notice Validates that the subject supports all previously expect'ed interfaces (and rejects 0xffffffff).
     * @dev Iterates expectations, calls subject.supportsInterface, uses isValid_ for each. Includes negative test per ERC165.
     *      Used by TestBase_IERC165.test_IERC165_supportsInterface() and declaration tests (LR-7).
     * @param subject The IERC165 subject contract to validate.
     * @return isValid_ True if all expected interfaces are supported and negative case holds.
     */
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
    // end::hasValid_IERC165_supportsInterface(IERC165)[]

// end::Behavior_IERC165[]
}
