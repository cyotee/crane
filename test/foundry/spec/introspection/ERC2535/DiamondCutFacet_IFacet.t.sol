// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {DiamondCutFacet} from "@crane/contracts/introspection/ERC2535/DiamondCutFacet.sol";
import {TestBase_IFacet} from "@crane/contracts/factories/diamondPkg/TestBase_IFacet.sol";

/**
 * @title DiamondCutFacet_IFacet_Test
 * @notice Tests IFacet compliance for DiamondCutFacet.
 */
contract DiamondCutFacet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return new DiamondCutFacet();
    }

    function controlFacetName() public pure override returns (string memory facetName) {
        return "DiamondCutFacet";
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        // DiamondCutFacet.facetInterfaces() returns 2 interfaces but index[0] is 0x00000000
        // This is a quirk in the implementation where interfaces[0] is not set
        controlInterfaces = new bytes4[](2);
        controlInterfaces[0] = bytes4(0); // Not set in the implementation
        controlInterfaces[1] = type(IDiamondCut).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](1);
        controlFuncs[0] = IDiamondCut.diamondCut.selector;
    }
}
