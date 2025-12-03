// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

// import "hardhat/console.sol";
// import "forge-std/console.sol";
// import "forge-std/console2.sol";

import {BetterAddress as Address} from "contracts/utils/BetterAddress.sol";

import {IFacet} from "contracts/interfaces/IFacet.sol";

import {IPostDeployAccountHook} from "contracts/interfaces/IPostDeployAccountHook.sol";

import {IDiamondFactoryPackage} from "contracts/interfaces/IDiamondFactoryPackage.sol";

abstract contract PostDeployAccountHookFacet is IPostDeployAccountHook, IFacet {
    using Address for address;

    /* ---------------------------------------------------------------------- */
    /*                                  Logic                                 */
    /* ---------------------------------------------------------------------- */

    function postDeploy() public returns (bool) {
        // console.log("Proxy post deploy");
        // console.log(address(msg.sender));
        address(msg.sender)
            .functionDelegateCall(
                // IDiamondFactoryPackage.postDeploy.selector,
                // abi.encode(address(this))
                abi.encodeWithSelector(IDiamondFactoryPackage.postDeploy.selector, address(this))
            );
        return true;
    }

    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    function facetInterfaces() public view virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IPostDeployAccountHook).interfaceId;
    }

    function facetFuncs() public view virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IPostDeployAccountHook.postDeploy.selector;
    }
}
