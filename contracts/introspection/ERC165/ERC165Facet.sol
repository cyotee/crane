// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {ERC165Target} from "@crane/contracts/introspection/ERC165/ERC165Target.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

contract ERC165Facet is ERC165Target, IFacet {
    function facetName() public pure returns (string memory name) {
        return type(ERC165Facet).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);

        interfaces[0] = type(IERC165).interfaceId;
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
        funcs = new bytes4[](1);

        funcs[0] = IERC165.supportsInterface.selector;
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
