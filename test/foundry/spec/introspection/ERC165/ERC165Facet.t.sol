// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "contracts/interfaces/IFacet.sol";
import {TestBase_IFacet} from "contracts/factories/diamondPkg/TestBase_IFacet.sol";
import {IERC165} from "contracts/interfaces/IERC165.sol";
import {ERC165Facet} from "contracts/introspection/ERC165/ERC165Facet.sol";

contract ERC165Facet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public virtual override returns (IFacet) {
        return new ERC165Facet();
    }

    function controlFacetName() public view virtual override returns (string memory facetName) {
        return type(ERC165Facet).name;
    }

    function controlFacetInterfaces() public view virtual override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);

        controlInterfaces[0] = type(IERC165).interfaceId;
    }

    function controlFacetFuncs() public view virtual override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](1);

        controlFuncs[0] = IERC165.supportsInterface.selector;
    }
}
