// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BetterEfficientHashLib} from '@crane/contracts/utils/BetterEfficientHashLib.sol';
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";

abstract contract DFPkgBase is IDiamondFactoryPackage {
    using BetterEfficientHashLib for bytes;

    // tag::packageName()[]
    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function packageName() public view virtual returns (string memory name);
    // end::packageName()[]

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function facetInterfaces() public view virtual returns (bytes4[] memory interfaces);

    function facetAddresses() public view virtual returns (address[] memory facetAddresses);

    function packageMetadata()
        public
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets)
    {
        name_ = packageName();
        interfaces = facetInterfaces();
        facets = facetAddresses();
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function facetCuts() public view virtual returns (IDiamond.FacetCut[] memory facetCuts_);

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function calcSalt(bytes memory pkgArgs) public view virtual returns (bytes32 salt) {
        return pkgArgs._hash();
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function processArgs(bytes memory pkgArgs) public virtual returns (bytes memory processedPkgArgs) {
        return pkgArgs;
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function updatePkg(address /*expectedProxy*/, bytes memory /*pkgArgs*/) public virtual returns (bool) {
        return true;
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function initAccount(bytes memory /*initArgs*/) public virtual;

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function postDeploy(address /*account*/) public virtual returns (bool) {
        return true;
    }
}