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
import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {OperableFacet} from "@crane/contracts/access/operable/OperableFacet.sol";
import {TestBase_IFacet} from "@crane/contracts/factories/diamondPkg/TestBase_IFacet.sol";

/**
 * @title OperableFacet_IFacet_Test
 * @notice Tests IFacet compliance for OperableFacet.
 */
contract OperableFacet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return new OperableFacet();
    }

    function controlFacetName() public pure override returns (string memory facetName) {
        return "OperableFacet";
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);
        controlInterfaces[0] = type(IOperable).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](4);
        controlFuncs[0] = IOperable.isOperator.selector;
        controlFuncs[1] = IOperable.isOperatorFor.selector;
        controlFuncs[2] = IOperable.setOperator.selector;
        controlFuncs[3] = IOperable.setOperatorFor.selector;
    }
}
