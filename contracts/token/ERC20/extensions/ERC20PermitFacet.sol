// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterIERC20} from "../../../interfaces/BetterIERC20.sol";
import {IERC2612} from "../../../interfaces/IERC2612.sol";
import {BetterERC20Permit} from "./BetterERC20Permit.sol";
import {IFacet} from "../../../interfaces/IFacet.sol";
import {Create3AwareContract} from "../../../factories/create2/aware/Create3AwareContract.sol";
import {ICreate3Aware} from "../../../interfaces/ICreate3Aware.sol";

contract ERC20PermitFacet
is
BetterERC20Permit,
Create3AwareContract,
IFacet
{

    constructor(ICreate3Aware.CREATE3InitData memory create3InitData) Create3AwareContract(create3InitData) {
        // No additional initialization needed for facets
    }

    function facetInterfaces()
    public view virtual
    // override
    returns(bytes4[] memory interfaces) {
        interfaces = new bytes4[](5);

        interfaces[0] = type(IERC20).interfaceId;
        interfaces[1] = type(IERC20Metadata).interfaceId;
        interfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
        interfaces[3] = type(IERC20Permit).interfaceId;
        interfaces[4] = type(IERC5267).interfaceId;

    }

    function facetFuncs()
    public pure virtual 
    // override
    returns(bytes4[] memory funcs) {
        funcs = new bytes4[](13);

        funcs[0] = IERC20Metadata.name.selector;
        funcs[1] = IERC20Metadata.symbol.selector;
        funcs[2] = IERC20Metadata.decimals.selector;
        funcs[3] = IERC20.totalSupply.selector;
        funcs[4] = IERC20.balanceOf.selector;
        funcs[5] = IERC20.allowance.selector;
        funcs[6] = IERC20.approve.selector;
        funcs[7] = IERC20.transfer.selector;
        funcs[8] = IERC20.transferFrom.selector;

        funcs[9] = IERC5267.eip712Domain.selector;

        funcs[10] = IERC20Permit.permit.selector;
        funcs[11] = IERC20Permit.nonces.selector;
        funcs[12] = IERC20Permit.DOMAIN_SEPARATOR.selector;

    }

}