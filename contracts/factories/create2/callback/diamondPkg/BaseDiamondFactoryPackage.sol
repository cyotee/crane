// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {
    IDiamond
} from "contracts/interfaces/IDiamond.sol";
import {
    IDiamondFactoryPackage
} from "contracts/interfaces/IDiamondFactoryPackage.sol";

abstract contract BaseDiamondFactoryPackage
is IDiamondFactoryPackage {

    function facetInterfaces()
    public pure virtual returns(bytes4[] memory interfaces);

    function facetCuts()
    public pure virtual returns(IDiamond.FacetCut[] memory facetCuts_);

    function diamondConfig()
    public pure virtual returns(IDiamondFactoryPackage.DiamondConfig memory config);

    function calcSalt(
        bytes memory pkgArgs
    ) public pure virtual returns(bytes32 salt) {
        return keccak256(pkgArgs);
    }

    function processArgs(
        bytes memory pkgArgs
    ) public pure virtual returns(bytes memory processedPkgArgs) {
        return pkgArgs;
    }

    function updatePkg(
        address , // expectedProxy,
        bytes memory // pkgArgs
    ) public virtual returns(bool) {
        return true;
    }

    function initAccount(
        bytes memory initArgs
    ) public pure virtual;


    function postDeploy(
        address // account
    ) public pure virtual returns(bytes memory postDeployData) {
        return "";
    }

}
