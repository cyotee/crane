// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {Vm as FoundryVM} from "forge-std/Vm.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {IFacet} from '@crane/contracts/interfaces/IFacet.sol';
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {SuperChainBridgeTokenRegistryFacet} from '@crane/contracts/protocols/l2s/superchain/registries/token/bridge/SuperChainBridgeTokenRegistryFacet.sol';
import {ISuperChainBridgeTokenRegistryDFPkg, SuperChainBridgeTokenRegistryDFPkg} from '@crane/contracts/protocols/l2s/superchain/registries/token/bridge/SuperChainBridgeTokenRegistryDFPkg.sol';
import {ISuperChainBridgeTokenRegistry} from '@crane/contracts/interfaces/ISuperChainBridgeTokenRegistry.sol';

library SuperChainBridgeTokenRegistryFactoryService {
    using BetterEfficientHashLib for bytes;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    FoundryVM constant HEVM = FoundryVM(VM_ADDRESS);
    function deploySuperChainBridgeTokenRegistryFacet(ICreate3FactoryProxy create3Factory) internal returns (IFacet facet) {
        facet = create3Factory.deployFacet(
            type(SuperChainBridgeTokenRegistryFacet).creationCode, abi.encode(type(SuperChainBridgeTokenRegistryFacet).name)._hash()
        );
        HEVM.label(address(facet), type(SuperChainBridgeTokenRegistryFacet).name);
    }

    function deploySuperChainBridgeTokenRegistryDFPkg(
        ICreate3FactoryProxy factory,
        IFacet multiStepOwnableFacet,
        IFacet operableFacet,
        IFacet superChainBridgeTokenRegistryFacet
    ) internal returns (ISuperChainBridgeTokenRegistryDFPkg dfpkg) {
        ISuperChainBridgeTokenRegistryDFPkg.PkgInit memory pkgInitArgs = ISuperChainBridgeTokenRegistryDFPkg.PkgInit({
            ownableFacet: multiStepOwnableFacet,
            operableFacet: operableFacet,
            superChainBridgeTokenRegistryFacet: superChainBridgeTokenRegistryFacet
        });

        dfpkg = ISuperChainBridgeTokenRegistryDFPkg(
            address(
                factory.deployPackageWithArgs(
                    type(SuperChainBridgeTokenRegistryDFPkg).creationCode,
                    abi.encode(pkgInitArgs),
                    abi.encode(type(SuperChainBridgeTokenRegistryDFPkg).name, pkgInitArgs)._hash()
                )
            )
        );
    }

    function deploySuperChainBridgeTokenRegistry(
        IDiamondPackageCallBackFactory diamondFactory,
        ISuperChainBridgeTokenRegistryDFPkg dfpkg,
        address owner
    ) internal returns (ISuperChainBridgeTokenRegistry registry) {
        ISuperChainBridgeTokenRegistryDFPkg.PkgArgs memory pkgArgs = ISuperChainBridgeTokenRegistryDFPkg.PkgArgs({owner: owner});

        registry = ISuperChainBridgeTokenRegistry(diamondFactory.deploy(dfpkg, abi.encode(pkgArgs)));
        HEVM.label(address(registry), "SuperChainBridgeTokenRegistry");
    }
}