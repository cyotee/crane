// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";

interface IDiamondPackageCallBackFactory {
    function PROXY_INIT_HASH() external view returns (bytes32);

    function ERC165_FACET() external view returns (IFacet);

    function DIAMOND_LOUPE_FACET() external view returns (IFacet);

    function POST_DEPLOY_HOOK_FACET() external view returns (IFacet);

    function pkgOfAccount(address account) external view returns (IDiamondFactoryPackage pkg);

    function pkgArgsOfAccount(address account) external view returns (bytes memory);

    function calcAddress(IDiamondFactoryPackage pkg, bytes memory pkgArgs) external view returns (address);

    function deploy(IDiamondFactoryPackage pkg, bytes memory pkgArgs) external returns (address proxy);
}
