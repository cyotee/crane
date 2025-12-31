// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestBase_IFacet} from "contracts/crane/test/bases/TestBase_IFacet.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IERC5115Extension} from "contracts/crane/interfaces/IERC5115Extension.sol";
// import { ERC5115ExtensionViewFacet } from "contracts/crane/token/ERC5115/extensions/ERC5115ExtensionViewFacet.sol";

contract ERC5115ExtensionViewFacet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public override returns (IFacet) {
        return IFacet(address(erc5115ExtensionViewFacet()));
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);
        controlInterfaces[0] = type(IERC5115Extension).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](1);
        controlFuncs[0] = IERC5115Extension.yieldTokenTypes.selector;
    }
}
