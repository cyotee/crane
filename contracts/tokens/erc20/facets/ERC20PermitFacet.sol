// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {
    IERC20
} from "../interfaces/IERC20.sol";

import {
    IERC2612
} from "../../../access/erc2612/interfaces/IERC2612.sol";

import {
    IERC5267
} from "../../../access/erc5267/interfaces/IERC5267.sol";

import {
    ERC20PermitTarget
} from "../targets/ERC20PermitTarget.sol";

import {
    IFacet
} from "../../../factories/create2/callback/diamondPkg/interfaces/IFacet.sol";

import {
    Create2CallbackContract
} from "../../../factories/create2/callback/targets/Create2CallbackContract.sol";

contract ERC20PermitFacet
is
ERC20PermitTarget,
Create2CallbackContract,
IFacet
{

    function facetInterfaces()
    public view virtual
    // override
    returns(bytes4[] memory interfaces) {
        interfaces = new bytes4[](3);

        interfaces[0] = type(IERC20).interfaceId;
        interfaces[1] = type(IERC2612).interfaceId;
        interfaces[2] = type(IERC5267).interfaceId;

    }

    function facetFuncs()
    public pure virtual 
    // override
    returns(bytes4[] memory funcs) {
        funcs = new bytes4[](13);

        funcs[0] = IERC20.name.selector;
        funcs[1] = IERC20.symbol.selector;
        funcs[2] = IERC20.decimals.selector;
        funcs[3] = IERC20.totalSupply.selector;
        funcs[4] = IERC20.balanceOf.selector;
        funcs[5] = IERC20.allowance.selector;
        funcs[6] = IERC20.approve.selector;
        funcs[7] = IERC20.transfer.selector;
        funcs[8] = IERC20.transferFrom.selector;

        funcs[9] = IERC5267.eip712Domain.selector;

        funcs[10] = IERC2612.permit.selector;
        funcs[11] = IERC2612.nonces.selector;
        funcs[12] = IERC2612.DOMAIN_SEPARATOR.selector;

    }

}