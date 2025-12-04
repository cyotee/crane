// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BetterAddress as Address} from "@crane/contracts/utils/BetterAddress.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

import {IPostDeployAccountHook} from "@crane/contracts/interfaces/IPostDeployAccountHook.sol";

import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";

contract PostDeployAccountHookFacet is IPostDeployAccountHook, IFacet {
    using Address for address;

    /* ---------------------------------------------------------------------- */
    /*                                  Logic                                 */
    /* ---------------------------------------------------------------------- */

    function postDeploy() public returns (bool) {
        address(msg.sender)
            .functionDelegateCall(abi.encodeWithSelector(IDiamondFactoryPackage.postDeploy.selector, address(this)));
        return true;
    }

    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    function facetName() public pure returns (string memory name) {
        return type(PostDeployAccountHookFacet).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IPostDeployAccountHook).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IPostDeployAccountHook.postDeploy.selector;
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
