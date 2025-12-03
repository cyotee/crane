// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IDiamond} from "./IDiamond.sol";
import {IDiamondFactoryPackage} from "./IDiamondFactoryPackage.sol";

interface IDiamondPackageCallBackFactory {
    error UnexpectedOrigin(address expected, address reported);
    error UnexpectedMetadata(address expected, address reported);

    function PROXY_INIT_HASH() external view returns (bytes32);

    function pkgOfAccount(address account) external view returns (IDiamondFactoryPackage pkg);

    function pkgArgsOfAccount(address account) external view returns (bytes memory);

    function create2SaltOfAccount(address account) external view returns (bytes32);

    function calcAddress(IDiamondFactoryPackage pkg, bytes memory pkgArgs) external view returns (address);

    function deploy(IDiamondFactoryPackage pkg, bytes memory pkgArgs) external returns (address proxy);

    function create2AwareFacetFuncs() external pure returns (bytes4[] memory funcs);

    function create2AwareFacetCuts(address facetAddress) external view returns (IDiamond.FacetCut[] memory facetCuts_);
}
