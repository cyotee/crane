// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
// import "forge-std/console.sol";
// import "forge-std/console2.sol";

import {
    Address
} from "../../../../../utils/primitives/Address.sol";

import {
    IFacet
} from "../interfaces/IFacet.sol";

import {
    IPostDeployAccountHook
} from "../interfaces/IPostDeployAccountHook.sol";

import {
    IDiamondFactoryPackage
} from "../interfaces/IDiamondFactoryPackage.sol";

contract PostDeployAccountHookFacet
is
IPostDeployAccountHook,
IFacet
{

    using Address for address;

    /* ---------------------------------------------------------------------- */
    /*                                  Logic                                 */
    /* ---------------------------------------------------------------------- */

    function postDeploy() public returns(bool) {
        // console.log("Proxy post deploy");
        // console.log(address(msg.sender));
        address(msg.sender)._delegateCall(
            // IDiamondFactoryPackage.postDeploy.selector,
            // abi.encode(address(this))
            abi.encodeWithSelector(
                IDiamondFactoryPackage.postDeploy.selector,
                address(this)
            )
        );
        return true;
    }

    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    function facetInterfaces()
    public view virtual returns(bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IPostDeployAccountHook).interfaceId;
    }

    function facetFuncs()
    public view virtual returns(bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IPostDeployAccountHook.postDeploy.selector;
    }

}