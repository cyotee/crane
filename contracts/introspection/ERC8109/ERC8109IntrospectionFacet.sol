// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC8109Introspection} from "@crane/contracts/interfaces/IERC8109Introspection.sol";
import {ERC8109IntrospectionTarget} from "@crane/contracts/introspection/ERC8109/ERC8109IntrospectionTarget.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

contract ERC8109IntrospectionFacet is ERC8109IntrospectionTarget, IFacet {
    function facetName() public pure returns (string memory name) {
        return type(ERC8109IntrospectionFacet).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IERC8109Introspection).interfaceId;
    }

    function facetFuncs()
        public
        pure
        virtual
        returns (bytes4[] memory funcs)
    {
        funcs = new bytes4[](2);
        funcs[0] = IERC8109Introspection.facetAddress.selector;
        funcs[1] = IERC8109Introspection.functionFacetPairs.selector;
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
