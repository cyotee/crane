// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import { IFacet } from "../../../../../interfaces/IFacet.sol";
import { IWETH } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import { IWETHAware } from "../../../../../interfaces/IWETHAware.sol";
import { WETHAwareStorage } from "./utils/WETHAwareStorage.sol";

contract WETHAwareFacet is WETHAwareStorage, IWETHAware, IFacet {

    /* ------------------------------ LIBRARIES ----------------------------- */

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IWETHAware).interfaceId;
        return interfaces;
    }

    function facetFuncs() external pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IWETHAware.weth.selector;
        return funcs;
    }

    function weth() external view returns (IWETH) {
        return _weth();
    }

}