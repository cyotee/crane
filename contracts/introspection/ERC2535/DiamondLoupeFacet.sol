// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {DiamondLoupeTarget} from "@crane/contracts/introspection/ERC2535/DiamondLoupeTarget.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

contract DiamondLoupeFacet is DiamondLoupeTarget, IFacet {
    function facetName() public pure returns (string memory name) {
        return type(DiamondLoupeFacet).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);

        interfaces[0] = type(IDiamondLoupe).interfaceId;
    }

    function facetFuncs()
        public
        pure
        virtual
        returns (
            // override
            bytes4[] memory funcs
        )
    {
        funcs = new bytes4[](4);

        funcs[0] = IDiamondLoupe.facets.selector;
        funcs[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        funcs[2] = IDiamondLoupe.facetAddresses.selector;
        funcs[3] = IDiamondLoupe.facetAddress.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}
