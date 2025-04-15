// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import { IAuthentication } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IAuthentication.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BalancerV3AuthenticationTarget} from "./BalancerV3AuthenticationTarget.sol";
import {IFacet} from "../../../../../interfaces/IFacet.sol";
import {Create3AwareContract} from "../../../../../factories/create2/aware/Create3AwareContract.sol";

contract BalancerV3AuthenticationFacet is Create3AwareContract, BalancerV3AuthenticationTarget, IFacet {

    constructor(CREATE3InitData memory create3InitData_)
    Create3AwareContract(create3InitData_){}

    function facetInterfaces()
    public view virtual
    // override
    returns(bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IAuthentication).interfaceId;
    }

    function facetFuncs()
    public pure virtual 
    // override
    returns(bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IAuthentication.getActionId.selector;
    }

}