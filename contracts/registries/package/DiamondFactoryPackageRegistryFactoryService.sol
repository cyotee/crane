// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {
    DiamondFactoryPackageRegistryRepo
} from "@crane/contracts/registries/package/DiamondFactoryPackageRegistryRepo.sol";
import {Create3FactoryService} from "@crane/contracts/factories/create3/Create3FactoryService.sol";

library DiamondFactoryPackageRegistryFactoryService {
    function _registerPackage(IDiamondFactoryPackage package) internal {
        (string memory name, bytes4[] memory interfaces, address[] memory facets) = package.packageMetadata();
        DiamondFactoryPackageRegistryRepo._registerPackage(package, name, interfaces, facets);
    }

    function _deployPackage(bytes memory initCode, bytes32 salt) internal returns (IDiamondFactoryPackage package) {
        package = IDiamondFactoryPackage(Create3FactoryService._create3(initCode, salt));
        _registerPackage(package);
        return package;
    }

    function _deployPackage(bytes memory initCode, bytes memory constructorArgs, bytes32 salt)
        internal
        returns (IDiamondFactoryPackage package)
    {
        package = IDiamondFactoryPackage(Create3FactoryService._create3WithArgs(initCode, constructorArgs, salt));
        _registerPackage(package);
        return package;
    }
}
