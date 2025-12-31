// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestBase_IFacet} from "contracts/crane/test/bases/TestBase_IFacet.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IERC5115} from "contracts/crane/interfaces/IERC5115.sol";
// import { ERC5115ViewFacet } from "contracts/crane/token/ERC5115/ERC5115ViewFacet.sol";

contract ERC5115ViewFacet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return IFacet(address(erc5115ViewFacet()));
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);
        controlInterfaces[0] = type(IERC5115).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](3);
        controlFuncs[0] = IERC5115.yieldToken.selector;
        controlFuncs[1] = IERC5115.getTokensIn.selector;
        controlFuncs[2] = IERC5115.getTokensOut.selector;
    }
}
