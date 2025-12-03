// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {Vm} from "forge-std/Vm.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {VM_ADDRESS} from "contracts/constants/FoundryConstants.sol";

library BehaviorUtils {
    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    function _errPrefixFunc(string memory behaviorName, string memory testedFuncSig)
        internal
        pure
        returns (string memory)
    {
        return string.concat(behaviorName, ":", testedFuncSig, "::");
    }

    function _errPrefix(string memory behaviorName, string memory testedFuncSig, string memory subjectLabel)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_errPrefixFunc(behaviorName, testedFuncSig), subjectLabel);
    }

    function _errPrefix(string memory behaviorName, string memory testedFuncSig, address subject)
        internal
        view
        returns (string memory)
    {
        return _errPrefix(behaviorName, testedFuncSig, vm.getLabel(subject));
    }
}
