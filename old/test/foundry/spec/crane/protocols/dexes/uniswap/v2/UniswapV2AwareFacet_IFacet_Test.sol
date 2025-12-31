// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestBase_IFacet} from "contracts/crane/test/bases/TestBase_IFacet.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IUniswapV2Aware} from "contracts/crane/interfaces/IUniswapV2Aware.sol";
// import { UniswapV2AwareFacet } from "contracts/crane/protocols/dexes/uniswap/v2/UniswapV2AwareFacet.sol";

contract UniswapV2AwareFacet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return IFacet(address(uniswapV2AwareFacet()));
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);
        controlInterfaces[0] = type(IUniswapV2Aware).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](2);
        controlFuncs[0] = IUniswapV2Aware.uniV2Factory.selector;
        controlFuncs[1] = IUniswapV2Aware.uniV2Router.selector;
    }
}
