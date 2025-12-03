// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {IFacet} from "contracts/interfaces/IFacet.sol";
import {IPermit2Aware} from "contracts/interfaces/IPermit2Aware.sol";
// import {Permit2AwareStorage} from "contracts/protocols/utils/permit2/utils/Permit2AwareStorage.sol";
import {Create3AwareContract} from "contracts/factories/create2/aware/Create3AwareContract.sol";
import {Permit2AwareRepo} from "contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol";

contract Permit2AwareFacet is IPermit2Aware, IFacet {
    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IPermit2Aware).interfaceId;
        return interfaces;
    }

    function facetFuncs() external pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IPermit2Aware.permit2.selector;
        return funcs;
    }

    function permit2() external view returns (IPermit2) {
        return Permit2AwareRepo._permit2();
    }
}
