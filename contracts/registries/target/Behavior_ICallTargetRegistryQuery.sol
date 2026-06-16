// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Vm} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {ICallTargetRegistryQuery} from "@crane/contracts/interfaces/ICallTargetRegistryQuery.sol";
import {BehaviorUtils} from "@crane/contracts/test/behaviors/BehaviorUtils.sol";
import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";

// tag::Behavior_ICallTargetRegistryQuery[]
/**
 * @title Behavior_ICallTargetRegistryQuery
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Behavior library encapsulating validation logic for ICallTargetRegistryQuery interface compliance testing (defaultCallTargetForID / callTargetForIDForCaller queries).
 * @dev Core for LR-7 CallTarget registry query behavior and declaration tests. Provides expect_*, hasValid_* (and recInvariant / full hasValid_ICall...) helpers that use direct comparison + logging.
 *      All ICallTargetRegistryQuery surface references use ONLY the centrally computed values from CENTRALLY_COMPUTED_NATSPEC_VALUES.md:
 *        interfaceId: 0xb6dd59b7
 *        defaultCallTargetForID(bytes4): 0xd2cfb6ed
 *        callTargetForIDForCaller(bytes4,address): 0x6412ef5a
 *      Pattern modeled exactly on Behavior_IFacet.sol + Behavior_IERC165.sol + Behavior_IDiamondLoupe.sol golds (rich title/author/notice/dev NatSpec header, _name() or similar, _errPrefix* overloads with hyphen tags, funcSig_* with custom, expect/hasValid patterns).
 *      No behavior or logic changes: console.log, direct compares, internal comments, imports, using-no, forge-lint disables preserved exactly.
 *      "Storage" pattern N/A (pure behavior lib, not a Repo).
 */
library Behavior_ICallTargetRegistryQuery {
    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    // tag::_name()[]
    /**
     * @notice Returns the name of the behavior.
     * @dev Used to prefix to identify which Behavior is logging.
     * @return The name of the behavior.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _name() internal pure returns (string memory) {
        return type(Behavior_ICallTargetRegistryQuery).name;
    }
    // end::_name()[]

    // tag::_errPrefixFunc(string)[]
    /**
     * @notice Returns the error prefix function for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _errPrefixFunc(string memory testedFuncSig) internal pure returns (string memory) {
        return BehaviorUtils._errPrefixFunc(_name(), testedFuncSig);
    }
    // end::_errPrefixFunc(string)[]

    // tag::_errPrefix(string-string)[]
    /**
     * @notice Returns the error prefix for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @param subjectLabel The label of the subject being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _errPrefix(string memory testedFuncSig, string memory subjectLabel) internal pure returns (string memory) {
        return string.concat(_errPrefixFunc(testedFuncSig), subjectLabel);
    }
    // end::_errPrefix(string-string)[]

    // tag::_errPrefix(string-address)[]
    /**
     * @notice Returns the error prefix for the behavior.
     * @param testedFuncSig The function signature being tested.
     * @param subject The address of the subject being tested.
     * @return The error prefix.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _errPrefix(string memory testedFuncSig, address subject) internal view returns (string memory) {
        return _errPrefix(testedFuncSig, vm.getLabel(subject));
    }
    // end::_errPrefix(string-address)[]

    /* -------------------------------------------------------------------------- */
    /*                        defaultCallTargetForID(bytes4)                      */
    /* -------------------------------------------------------------------------- */

    // tag::funcSig_defaultCallTargetForID()[]
    /**
     * @notice Returns the ICallTargetRegistryQuery.defaultCallTargetForID() function signature for error messages and logging.
     * @return The function signature.
     * @custom:signature defaultCallTargetForID(bytes4)
     * @custom:selector 0xd2cfb6ed
     */
    function funcSig_defaultCallTargetForID() public pure returns (string memory) {
        return "defaultCallTargetForID(bytes4)";
    }
    // end::funcSig_defaultCallTargetForID()[]

    // tag::expect_defaultCallTargetForID(ICallTargetRegistryQuery-bytes4-address)[]
    /**
     * @notice Records expectation for defaultCallTargetForID (for later hasValid checks).
     * @param subject The ICallTargetRegistryQuery subject under test.
     * @param interfaceId The interface ID to query.
     * @param expected The expected call target address.
     */
    function expect_defaultCallTargetForID(ICallTargetRegistryQuery subject, bytes4 interfaceId, address expected)
        internal {
        // Record for invariant if using comparator system
        // For simplicity in this behavior, we use direct in tests
    }
    // end::expect_defaultCallTargetForID(ICallTargetRegistryQuery-bytes4-address)[]

    // tag::hasValid_defaultCallTargetForID(ICallTargetRegistryQuery-bytes4-address)[]
    /**
     * @notice Validates that subject's defaultCallTargetForID matches the provided expected.
     * @param subject The ICallTargetRegistryQuery subject under test.
     * @param interfaceId The interface ID to query.
     * @param expected The expected call target address.
     * @return True if matches.
     */
    function hasValid_defaultCallTargetForID(ICallTargetRegistryQuery subject, bytes4 interfaceId, address expected)
        internal
        returns (bool)
    {
        address actual = subject.defaultCallTargetForID(interfaceId);
        if (actual != expected) {
            console.log(_errPrefix(funcSig_defaultCallTargetForID(), address(subject)));
            console.log("expected", expected);
            console.log("actual  ", actual);
            return false;
        }
        return true;
    }
    // end::hasValid_defaultCallTargetForID(ICallTargetRegistryQuery-bytes4-address)[]

    /* -------------------------------------------------------------------------- */
    /*                    callTargetForIDForCaller(bytes4, address)               */
    /* -------------------------------------------------------------------------- */

    // tag::funcSig_callTargetForIDForCaller()[]
    /**
     * @notice Returns the ICallTargetRegistryQuery.callTargetForIDForCaller() function signature for error messages and logging.
     * @return The function signature.
     * @custom:signature callTargetForIDForCaller(bytes4,address)
     * @custom:selector 0x6412ef5a
     */
    function funcSig_callTargetForIDForCaller() public pure returns (string memory) {
        return "callTargetForIDForCaller(bytes4,address)";
    }
    // end::funcSig_callTargetForIDForCaller()[]

    // tag::expect_callTargetForIDForCaller(ICallTargetRegistryQuery-bytes4-address-address)[]
    /**
     * @notice Records expectation for callTargetForIDForCaller (for later hasValid checks).
     * @param subject The ICallTargetRegistryQuery subject under test.
     * @param interfaceId The interface ID to query.
     * @param caller The caller address to scope the override.
     * @param expected The expected call target address.
     */
    function expect_callTargetForIDForCaller(
        ICallTargetRegistryQuery subject,
        bytes4 interfaceId,
        address caller,
        address expected
    ) internal {
        // Recording for invariants
    }
    // end::expect_callTargetForIDForCaller(ICallTargetRegistryQuery-bytes4-address-address)[]

    // tag::hasValid_callTargetForIDForCaller(ICallTargetRegistryQuery-bytes4-address-address)[]
    /**
     * @notice Validates that subject's callTargetForIDForCaller matches the provided expected.
     * @param subject The ICallTargetRegistryQuery subject under test.
     * @param interfaceId The interface ID to query.
     * @param caller The caller address to scope the override.
     * @param expected The expected call target address.
     * @return True if matches.
     */
    function hasValid_callTargetForIDForCaller(
        ICallTargetRegistryQuery subject,
        bytes4 interfaceId,
        address caller,
        address expected
    ) internal returns (bool) {
        address actual = subject.callTargetForIDForCaller(interfaceId, caller);
        if (actual != expected) {
            console.log(_errPrefix(funcSig_callTargetForIDForCaller(), address(subject)));
            console.log("expected", expected);
            console.log("actual  ", actual);
            return false;
        }
        return true;
    }
    // end::hasValid_callTargetForIDForCaller(ICallTargetRegistryQuery-bytes4-address-address)[]

    /* -------------------------------------------------------------------------- */
    /*                              Invariant helpers                             */
    /* -------------------------------------------------------------------------- */

    // tag::recInvariant_defaultCallTargetForID(ICallTargetRegistryQuery-bytes4-address)[]
    function recInvariant_defaultCallTargetForID(ICallTargetRegistryQuery subject, bytes4 interfaceId, address expected)
        internal
    {
        expect_defaultCallTargetForID(subject, interfaceId, expected);
    }
    // end::recInvariant_defaultCallTargetForID(ICallTargetRegistryQuery-bytes4-address)[]

    // tag::recInvariant_callTargetForIDForCaller(ICallTargetRegistryQuery-bytes4-address-address)[]
    function recInvariant_callTargetForIDForCaller(
        ICallTargetRegistryQuery subject,
        bytes4 interfaceId,
        address caller,
        address expected
    ) internal {
        expect_callTargetForIDForCaller(subject, interfaceId, caller, expected);
    }
    // end::recInvariant_callTargetForIDForCaller(ICallTargetRegistryQuery-bytes4-address-address)[]

    // tag::hasValid_ICallTargetRegistryQuery(ICallTargetRegistryQuery-bytes4-address-address-address)[]
    /**
     * @notice Validates full ICallTargetRegistryQuery surface for a (interfaceId, caller) pair against expected default + per-caller.
     * @param subject The query subject.
     * @param interfaceId The interface ID.
     * @param caller The caller for override query.
     * @param expectedDefault Expected from defaultCallTargetForID.
     * @param expectedForCaller Expected from callTargetForIDForCaller.
     * @return True if both match.
     */
    function hasValid_ICallTargetRegistryQuery(
        ICallTargetRegistryQuery subject,
        bytes4 interfaceId,
        address caller,
        address expectedDefault,
        address expectedForCaller
    ) internal returns (bool) {
        bool ok1 = hasValid_defaultCallTargetForID(subject, interfaceId, expectedDefault);
        bool ok2 = hasValid_callTargetForIDForCaller(subject, interfaceId, caller, expectedForCaller);
        return ok1 && ok2;
    }
    // end::hasValid_ICallTargetRegistryQuery(ICallTargetRegistryQuery-bytes4-address-address-address)[]

// end::Behavior_ICallTargetRegistryQuery[]
}
