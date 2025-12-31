// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_IFacet} from "contracts/crane/test/bases/TestBase_IFacet.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";
// import { ERC20PermitFacet } from "contracts/crane/token/ERC20/extensions/ERC20PermitFacet.sol";

contract ERC20PermitFacet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return IFacet(address(erc20PermitFacet()));
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](5);
        controlInterfaces[0] = type(IERC20).interfaceId;
        controlInterfaces[1] = type(IERC20Metadata).interfaceId;
        controlInterfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
        controlInterfaces[3] = type(IERC20Permit).interfaceId;
        controlInterfaces[4] = type(IERC5267).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](13);
        controlFuncs[0] = IERC20Metadata.name.selector;
        controlFuncs[1] = IERC20Metadata.symbol.selector;
        controlFuncs[2] = IERC20Metadata.decimals.selector;
        controlFuncs[3] = IERC20.totalSupply.selector;
        controlFuncs[4] = IERC20.balanceOf.selector;
        controlFuncs[5] = IERC20.allowance.selector;
        controlFuncs[6] = IERC20.approve.selector;
        controlFuncs[7] = IERC20.transfer.selector;
        controlFuncs[8] = IERC20.transferFrom.selector;
        controlFuncs[9] = IERC5267.eip712Domain.selector;
        controlFuncs[10] = IERC20Permit.permit.selector;
        controlFuncs[11] = IERC20Permit.nonces.selector;
        controlFuncs[12] = IERC20Permit.DOMAIN_SEPARATOR.selector;
    }
}
