// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IFacet} from "contracts/interfaces/IFacet.sol";
import {TestBase_IFacet} from "contracts/factories/diamondPkg/TestBase_IFacet.sol";
import {ERC20Facet} from "contracts/tokens/ERC20/ERC20Facet.sol";

contract ERC20Facet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public virtual override returns (IFacet) {
        return new ERC20Facet();
    }

    function controlFacetName() public view virtual override returns (string memory facetName) {
        return type(ERC20Facet).name;
    }

    /**
     * @notice Returns the expected interface IDs that the facet should support
     * @dev Must be implemented by inheriting contracts
     * @return controlInterfaces Array of interface IDs (bytes4) the facet should expose
     */
    function controlFacetInterfaces() public view virtual override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](3);

        controlInterfaces[0] = type(IERC20).interfaceId;
        controlInterfaces[1] = type(IERC20Metadata).interfaceId;
        controlInterfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
    }

    /**
     * @notice Returns the expected function selectors that the facet should expose
     * @dev Must be implemented by inheriting contracts
     * @return controlFuncs Array of function selectors (bytes4) the facet should expose
     */
    function controlFacetFuncs() public view virtual override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](9);

        controlFuncs[0] = IERC20Metadata.name.selector;
        controlFuncs[1] = IERC20Metadata.symbol.selector;
        controlFuncs[2] = IERC20Metadata.decimals.selector;
        controlFuncs[3] = IERC20.totalSupply.selector;
        controlFuncs[4] = IERC20.balanceOf.selector;
        controlFuncs[5] = IERC20.allowance.selector;
        controlFuncs[6] = IERC20.approve.selector;
        controlFuncs[7] = IERC20.transfer.selector;
        controlFuncs[8] = IERC20.transferFrom.selector;
    }
}
