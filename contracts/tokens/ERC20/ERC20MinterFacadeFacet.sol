// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IERC20MinterFacade} from "@crane/contracts/tokens/ERC20/IERC20MinterFacade.sol";
import {ERC20MinterFacadeTarget} from "@crane/contracts/tokens/ERC20/ERC20MinterFacadeTarget.sol";

contract ERC20MinterFacadeFacet is ERC20MinterFacadeTarget {
    function facetName() public pure returns (string memory name) {
        return type(ERC20MinterFacadeFacet).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces)
    {
        interfaces = new bytes4[](1);

        interfaces[0] = type(IERC20MinterFacade).interfaceId;
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

        funcs[0] = IERC20MinterFacade.mintToken.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}