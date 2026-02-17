// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {ICreate3FactoryBootstrap} from "@crane/contracts/interfaces/ICreate3FactoryBootstrap.sol";
import {BetterAddress as Address} from "@crane/contracts/utils/BetterAddress.sol";
import {FacetRegistryRepo} from "@crane/contracts/registries/facet/FacetRegistryRepo.sol";
import {FacetRegistryService} from "@crane/contracts/registries/facet/FacetRegistryService.sol";
import {
    DiamondFactoryPackageRegistryRepo
} from "@crane/contracts/registries/package/DiamondFactoryPackageRegistryRepo.sol";
import {
    DiamondFactoryPackageRegistryFactoryService
} from "@crane/contracts/registries/package/DiamondFactoryPackageRegistryFactoryService.sol";
import {OperableModifiers} from "@crane/contracts/access/operable/OperableModifiers.sol";
import {ICREATE3DFPkg} from "@crane/contracts/factories/create3/Create3FactoryDFPkg.sol";
import {MultiStepOwnableModifiers} from "@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol";
import {
    DiamondFactoryPackageRegistryRepo
} from "@crane/contracts/registries/package/DiamondFactoryPackageRegistryRepo.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {DiamondPackageFactoryAwareRepo} from "@crane/contracts/factories/diamondPkg/DiamondPackageFactoryAwareRepo.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {Create3FactoryService} from "@crane/contracts/factories/create3/Create3FactoryService.sol";
// import {MultiStepOwnableModifiers} from '@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol';

contract Create3FactoryBootstrapTarget is MultiStepOwnableModifiers, OperableModifiers, ICreate3FactoryBootstrap {
    using Address for address;

    function initFactory() external onlyOwner returns (bool) {
        ICREATE3DFPkg.PkgArgs memory pkgArgs = ICREATE3DFPkg.PkgArgs({owner: MultiStepOwnableRepo._owner()});
        address(DiamondPackageFactoryAwareRepo._diamondPackageFactory()).functionDelegateCall(abi.encodeWithSelector(IDiamondPackageCallBackFactory.initAccount.selector, DiamondFactoryPackageRegistryRepo._canonicalPackage(type(ICREATE3DFPkg).interfaceId), abi.encode(pkgArgs)));
        return true;
    }

    function setDiamondPackageFactory(IDiamondPackageCallBackFactory diamondPackageFactory_) external onlyOwner returns (bool) {
        DiamondPackageFactoryAwareRepo._initialize(diamondPackageFactory_);
        return true;
    }

    function create3WithArgs(bytes memory initCode, bytes memory initData, bytes32 salt)
        external
        onlyOwnerOrOperator
        returns (address proxy)
    {
        return Create3FactoryService._create3WithArgs(initCode, initData, salt);
    }

    function deployCanonicalFacet(bytes calldata initCode, bytes32 salt)
        external
        onlyOwnerOrOperator
        returns (IFacet facet)
    {
        facet = FacetRegistryService._deployFacet(initCode, salt);
        FacetRegistryRepo._setCanonicalFacet(facet.facetInterfaces(), facet);
        return facet;
    }

    function canonicalFacet(bytes4 interfaceId) external view returns (IFacet facet) {
        return FacetRegistryRepo._canonicalFacet(interfaceId);
    }

    // function deployCanonicalFacetOverride(bytes calldata initCode, bytes32 salt, bytes4 interfaceId) external returns (IFacet facet) {
    //     facet = FacetRegistryService._deployFacet(initCode, salt);
    //     FacetRegistryRepo._setCanonicalFacet(interfaceId, facet);
    //     return facet;
    // }

    // function deployCanonicalFacetWithArgs(bytes calldata initCode, bytes calldata initArgs, bytes32 salt)
    //     external
    //     onlyOwnerOrOperator
    //     returns (IFacet facet)
    // {
    //     facet = FacetRegistryService._deployFacet(initCode, initArgs, salt);
    //     FacetRegistryRepo._setCanonicalFacet(facet.facetInterfaces(), facet);
    //     return facet;
    // }

    // function deployCanonicalFacetWithArgsOverride(bytes calldata initCode, bytes calldata initArgs, bytes32 salt, bytes4 interfaceId)
    //     external
    //     returns (IFacet facet) {
    //         facet = FacetRegistryService._deployFacet(initCode, initArgs, salt);
    //         FacetRegistryRepo._setCanonicalFacet(interfaceId, facet);
    //         return facet;
    //     }

    // function deployCanonicalPackage(bytes calldata initCode, bytes32 salt, bytes4 interfaceId)
    //     external
    //     onlyOwnerOrOperator
    //     returns (IDiamondFactoryPackage package)
    // {
    //     package = DiamondFactoryPackageRegistryFactoryService._deployPackage(initCode, salt);
    //     DiamondFactoryPackageRegistryRepo._setCanonicalPackage(interfaceId, package);
    //     return package;
    // }

    function deployCanonicalPackageWithArgs(
        bytes calldata initCode,
        bytes calldata constructorArgs,
        bytes32 salt,
        bytes4 interfaceId
    ) external onlyOwnerOrOperator returns (IDiamondFactoryPackage package) {
        package = DiamondFactoryPackageRegistryFactoryService._deployPackage(initCode, constructorArgs, salt);
        DiamondFactoryPackageRegistryRepo._setCanonicalPackage(interfaceId, package);
        return package;
    }
}
