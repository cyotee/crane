// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/StdAssertions.sol";
import {CommonBase} from "forge-std/Base.sol";
import {AddressSet} from 
// AddressSetRepo
"@crane/src/utils/collections/sets/AddressSetRepo.sol";
// import {
//     betterconsole as console
// } from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {IBehavior} from "contracts/crane/interfaces/IBehavior.sol";

contract Behavior is

    // DeclaredAddrs,
    CommonBase,
    // StdAssertions,
    // FoundryVM,
    IBehavior
{
    /// forge-lint: disable-next-line(mixed-case-variable)
    AddressSet internal _declared_subjects;

    // function behaviorName()
    // public view virtual returns(string memory) {
    //     return vm.getLabel(address(this));
    // }

    function _errPrefixFunc(string memory behaviorName, string memory testedFuncSig)
        internal
        view
        virtual
        returns (string memory)
    {
        return string.concat(behaviorName, ":", testedFuncSig, "::");
    }

    function _errPrefix(string memory behaviorName, string memory testedFuncSig, string memory subjectLabel)
        internal
        view
        virtual
        returns (string memory)
    {
        return string.concat(_errPrefixFunc(behaviorName, testedFuncSig), subjectLabel);
    }

    function _errPrefix(string memory behaviorName, string memory testedFuncSig, address subject)
        internal
        view
        virtual
        returns (string memory)
    {
        return _errPrefix(behaviorName, testedFuncSig, vm.getLabel(subject));
    }
}
