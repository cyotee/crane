// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_IFacet} from "contracts/crane/test/bases/TestBase_IFacet.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IOwnable} from "contracts/crane/interfaces/IOwnable.sol";
import {IERC20MinterFacade} from "contracts/crane/interfaces/IERC20MinterFacade.sol";

contract ERC20MinterFacadeFacetDFPkg_IFacet_Test is TestBase_IFacet {
    // function setUp() public override(TestBase_IFacet) {
    //     super.setUp();
    // }

    function facetTestInstance() public override returns (IFacet) {
        return IFacet(address(erc20MinterFacadeFacetDFPkg()));
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](2);
        controlInterfaces[0] = type(IOwnable).interfaceId;
        controlInterfaces[1] = type(IERC20MinterFacade).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](3);
        controlFuncs[0] = IERC20MinterFacade.maxMintAmount.selector;
        controlFuncs[1] = IERC20MinterFacade.setMaxMintAmount.selector;
        controlFuncs[2] = IERC20MinterFacade.mint.selector;
    }
}
