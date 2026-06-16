// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {
    DiamondFactoryPackageRegistryRepo
} from "@crane/contracts/registries/package/DiamondFactoryPackageRegistryRepo.sol";
import {Create3FactoryService} from "@crane/contracts/factories/create3/Create3FactoryService.sol";

// tag::DiamondFactoryPackageRegistryFactoryService[]
/**
 * @title DiamondFactoryPackageRegistryFactoryService
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Stateless library for deterministic CREATE3 deployments of IDiamondFactoryPackage instances with automatic registration into DiamondFactoryPackageRegistryRepo.
 * @dev Core factory service used by DiamondFactoryPackageRegistryTarget (and indirectly by consumers via IDiamondFactoryPackageRegistry) to implement deploy*Package + registration.
 * Delegates low-level CREATE3 to Create3FactoryService._create3 / _create3WithArgs.
 * Immediately after deploy, calls _registerPackage which queries the package's packageMetadata() (central selector 0xf45469e7) to extract (name, interfaces, facets) and delegates to DiamondFactoryPackageRegistryRepo._registerPackage.
 * Package name / facetInterfaces / facetAddresses / calcSalt / initAccount / postDeploy / facetCuts / diamondConfig referenced via IDiamondFactoryPackage (packageName 0xabc8b346, facetInterfaces 0x2ea80826, facetAddresses 0x52ef6b2c, facetCuts 0xa4b3ad35, diamondConfig 0x65d375b3, calcSalt 0xd82be56e, initAccount 0x870d4838, postDeploy 0x70068fcf etc per CENTRALLY_COMPUTED_NATSPEC_VALUES.md).
 * Salt is provided by caller (typically `abi.encode(type(XDFPkg).name)._hash()` for cross-chain determinism).
 * LR-7 support: ensures full registration after deploy so consuming tests (DevEnvSmokeTest, DFPkg tests, Behavior_IDiamondFactoryPackage) can query registered packages with real non-zero facet addresses.
 */
library DiamondFactoryPackageRegistryFactoryService {
    // tag::_registerPackage(IDiamondFactoryPackage)[]
    /**
     * @notice Registers the given package by querying packageMetadata() and delegating the details to the repo.
     * @dev Extracts (name, interfaces, facets) via IDiamondFactoryPackage.packageMetadata() (selector 0xf45469e7) then calls the repo overload.
     * @param package The IDiamondFactoryPackage to register (typically just deployed).
     */
    function _registerPackage(IDiamondFactoryPackage package) internal {
        (string memory name, bytes4[] memory interfaces, address[] memory facets) = package.packageMetadata();
        DiamondFactoryPackageRegistryRepo._registerPackage(package, name, interfaces, facets);
    }
    // end::_registerPackage(IDiamondFactoryPackage)[]

    // tag::_deployPackage(bytes-bytes32)[]
    /**
     * @notice Deploys a package using CREATE3 (no constructor arguments) then auto-registers it in the package registry.
     * @dev Wraps Create3FactoryService._create3 then _registerPackage. Idempotent if address already exists (per Create3FactoryService behavior).
     * @param initCode Package creation bytecode (no encoded ctor args).
     * @param salt CREATE3 salt for deterministic address (e.g. from type name hash).
     * @return package The deployed and registered IDiamondFactoryPackage.
     */
    function _deployPackage(bytes memory initCode, bytes32 salt) internal returns (IDiamondFactoryPackage package) {
        package = IDiamondFactoryPackage(Create3FactoryService._create3(initCode, salt));
        _registerPackage(package);
        return package;
    }
    // end::_deployPackage(bytes-bytes32)[]

    // tag::_deployPackage(bytes-bytes-bytes32)[]
    /**
     * @notice Deploys a package using CREATE3 (with constructor arguments) then auto-registers it in the package registry.
     * @dev Wraps Create3FactoryService._create3WithArgs (for PkgInit ctor) then _registerPackage.
     * @param initCode Package creation bytecode.
     * @param constructorArgs ABI-encoded constructor args (typically IDiamondFactoryPackage.PkgInit or equivalent).
     * @param salt CREATE3 salt for deterministic address.
     * @return package The deployed and registered IDiamondFactoryPackage.
     */
    function _deployPackage(bytes memory initCode, bytes memory constructorArgs, bytes32 salt)
        internal
        returns (IDiamondFactoryPackage package)
    {
        package = IDiamondFactoryPackage(Create3FactoryService._create3WithArgs(initCode, constructorArgs, salt));
        _registerPackage(package);
        return package;
    }
    // end::_deployPackage(bytes-bytes-bytes32)[]

// end::DiamondFactoryPackageRegistryFactoryService[]
}
