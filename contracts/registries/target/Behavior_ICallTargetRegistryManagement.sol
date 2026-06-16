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
import {ICallTargetRegistryManagement} from "@crane/contracts/interfaces/ICallTargetRegistryManagement.sol";
import {BehaviorUtils} from "@crane/contracts/test/behaviors/BehaviorUtils.sol";
import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";

// tag::Behavior_ICallTargetRegistryManagement[]
/**
 * @dev Behavior_ICallTargetRegistryManagement library for LR-1/LR-7: validation for ICallTargetRegistryManagement (setDefaultCallTargetForID / setCallTargetForIDForCaller).
 *      Uses ONLY centrals: interfaceId 0x9400c76a, setDefault... 0xaf87fa1d, setCall... 0x3b873d77 .
 *      Rich title/author/notice/dev modeled (see Behavior golds); custom tags on funcSig_ only.
 *      Preserves 100% original logic/imports/forge-lint/console. No storage. Author: cyotee doge (not_cyotee at proton.me)
 */
library Behavior_ICallTargetRegistryManagement {
    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    // tag::_name()[]
    /**
     * @notice Returns the name of the behavior.
     * @dev Used to prefix to identify which Behavior is logging.
     * @return The name of the behavior.
     */
    function _name() internal pure returns (string memory) {
        return type(Behavior_ICallTargetRegistryManagement).name;
    }
    // end::_name()[]

    // tag::_errPrefixFunc(string)[]
    /// forge-lint: disable-next-line(mixed-case-function)
    function _errPrefixFunc(string memory testedFuncSig) internal pure returns (string memory) {
        return BehaviorUtils._errPrefixFunc(_name(), testedFuncSig);
    }
    // end::_errPrefixFunc(string)[]

    // tag::_errPrefix(string-string)[]
    /// forge-lint: disable-next-line(mixed-case-function)
    function _errPrefix(string memory testedFuncSig, string memory subjectLabel) internal pure returns (string memory) {
        return string.concat(_errPrefixFunc(testedFuncSig), subjectLabel);
    }
    // end::_errPrefix(string-string)[]

    // tag::_errPrefix(string-address)[]
    /// forge-lint: disable-next-line(mixed-case-function)
    function _errPrefix(string memory testedFuncSig, address subject) internal view returns (string memory) {
        return _errPrefix(testedFuncSig, vm.getLabel(subject));
    }
    // end::_errPrefix(string-address)[]

    /* -------------------------------------------------------------------------- */
    /*                     setDefaultCallTargetForID(bytes4, address)             */
    /* -------------------------------------------------------------------------- */

    // tag::funcSig_setDefaultCallTargetForID()[]
    /**
     * @notice Returns the ICallTargetRegistryManagement.setDefaultCallTargetForID function signature for error messages and logging.
     * @return The function signature.
     * @custom:signature setDefaultCallTargetForID(bytes4,address)
     * @custom:selector 0xaf87fa1d
     */
    function funcSig_setDefaultCallTargetForID() public pure returns (string memory) {
        return "setDefaultCallTargetForID(bytes4,address)";
    }
    // end::funcSig_setDefaultCallTargetForID()[]

    // tag::expect_setDefaultCallTargetForID(ICallTargetRegistryManagement-bytes4-address-bool)[]
    function expect_setDefaultCallTargetForID(
        ICallTargetRegistryManagement subject,
        bytes4 interfaceId,
        address callTarget,
        bool expected
    ) internal {
        // For recording
    }
    // end::expect_setDefaultCallTargetForID(ICallTargetRegistryManagement-bytes4-address-bool)[]

    // tag::hasValid_setDefaultCallTargetForID(ICallTargetRegistryManagement-bytes4-address-bool)[]
    function hasValid_setDefaultCallTargetForID(
        ICallTargetRegistryManagement subject,
        bytes4 interfaceId,
        address callTarget,
        bool expected
    ) internal returns (bool) {
        bool actual = subject.setDefaultCallTargetForID(interfaceId, callTarget);
        if (actual != expected) {
            console.log(_errPrefix(funcSig_setDefaultCallTargetForID(), address(subject)));
            console.log("expected", expected);
            console.log("actual  ", actual);
            return false;
        }
        return true;
    }
    // end::hasValid_setDefaultCallTargetForID(ICallTargetRegistryManagement-bytes4-address-bool)[]

    /* -------------------------------------------------------------------------- */
    /*              setCallTargetForIDForCaller(bytes4, address, address)         */
    /* -------------------------------------------------------------------------- */

    // tag::funcSig_setCallTargetForIDForCaller()[]
    /**
     * @notice Returns the ICallTargetRegistryManagement.setCallTargetForIDForCaller function signature for error messages and logging.
     * @return The function signature.
     * @custom:signature setCallTargetForIDForCaller(bytes4,address,address)
     * @custom:selector 0x3b873d77
     */
    function funcSig_setCallTargetForIDForCaller() public pure returns (string memory) {
        return "setCallTargetForIDForCaller(bytes4,address,address)";
    }
    // end::funcSig_setCallTargetForIDForCaller()[]

    // tag::expect_setCallTargetForIDForCaller(ICallTargetRegistryManagement-bytes4-address-address-bool)[]
    function expect_setCallTargetForIDForCaller(
        ICallTargetRegistryManagement subject,
        bytes4 interfaceId,
        address caller,
        address callTarget,
        bool expected
    ) internal {
        // For recording
    }
    // end::expect_setCallTargetForIDForCaller(ICallTargetRegistryManagement-bytes4-address-address-bool)[]

    // tag::hasValid_setCallTargetForIDForCaller(ICallTargetRegistryManagement-bytes4-address-address-bool)[]
    function hasValid_setCallTargetForIDForCaller(
        ICallTargetRegistryManagement subject,
        bytes4 interfaceId,
        address caller,
        address callTarget,
        bool expected
    ) internal returns (bool) {
        bool actual = subject.setCallTargetForIDForCaller(interfaceId, caller, callTarget);
        if (actual != expected) {
            console.log(_errPrefix(funcSig_setCallTargetForIDForCaller(), address(subject)));
            console.log("expected", expected);
            console.log("actual  ", actual);
            return false;
        }
        return true;
    }
    // end::hasValid_setCallTargetForIDForCaller(ICallTargetRegistryManagement-bytes4-address-address-bool)[]

    /* -------------------------------------------------------------------------- */
    /*                              Invariant helpers                             */
    /* -------------------------------------------------------------------------- */

    // tag::recInvariant_setDefaultCallTargetForID(ICallTargetRegistryManagement-bytes4-address-bool)[]
    function recInvariant_setDefaultCallTargetForID(
        ICallTargetRegistryManagement subject,
        bytes4 interfaceId,
        address callTarget,
        bool expectedSuccess
    ) internal {
        expect_setDefaultCallTargetForID(subject, interfaceId, callTarget, expectedSuccess);
    }
    // end::recInvariant_setDefaultCallTargetForID(ICallTargetRegistryManagement-bytes4-address-bool)[]

    // tag::recInvariant_setCallTargetForIDForCaller(ICallTargetRegistryManagement-bytes4-address-address-bool)[]
    function recInvariant_setCallTargetForIDForCaller(
        ICallTargetRegistryManagement subject,
        bytes4 interfaceId,
        address caller,
        address callTarget,
        bool expectedSuccess
    ) internal {
        expect_setCallTargetForIDForCaller(subject, interfaceId, caller, callTarget, expectedSuccess);
    }
    // end::recInvariant_setCallTargetForIDForCaller(ICallTargetRegistryManagement-bytes4-address-address-bool)[]

// end::Behavior_ICallTargetRegistryManagement[]
}
