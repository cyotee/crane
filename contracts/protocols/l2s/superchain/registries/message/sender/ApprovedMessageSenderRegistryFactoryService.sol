// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {Vm as FoundryVM} from "forge-std/Vm.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {IFacet} from '@crane/contracts/interfaces/IFacet.sol';
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IApprovedMessageSenderRegistry} from '@crane/contracts/interfaces/IApprovedMessageSenderRegistry.sol';
import {ApprovedMessageSenderRegistryFacet} from '@crane/contracts/protocols/l2s/superchain/registries/message/sender/ApprovedMessageSenderRegistryFacet.sol';
import {IApprovedMessageSenderRegistryDFPkg, ApprovedMessageSenderRegistryDFPkg} from '@crane/contracts/protocols/l2s/superchain/registries/message/sender/ApprovedMessageSenderRegistryDFPkg.sol';

library ApprovedMessageSenderRegistryFactoryService {
    using BetterEfficientHashLib for bytes;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    FoundryVM constant HEVM = FoundryVM(VM_ADDRESS);

    function deployApprovedMessageSenderRegistryFacet(ICreate3FactoryProxy create3Factory) internal returns (IFacet facet) {
        facet = create3Factory.deployFacet(
            type(ApprovedMessageSenderRegistryFacet).creationCode, abi.encode(type(ApprovedMessageSenderRegistryFacet).name)._hash()
        );
        HEVM.label(address(facet), type(ApprovedMessageSenderRegistryFacet).name);
    }

    function deployApprovedMessageSenderRegistryDFPkg(
        ICreate3FactoryProxy factory,
        IFacet multiStepOwnableFacet,
        IFacet operableFacet,
        IFacet approvedMessageSenderRegistryFacet
    ) internal returns (IApprovedMessageSenderRegistryDFPkg dfpkg) {
        IApprovedMessageSenderRegistryDFPkg.PkgInit memory pkgInitArgs = IApprovedMessageSenderRegistryDFPkg.PkgInit({
            ownableFacet: multiStepOwnableFacet,
            operableFacet: operableFacet,
            approvedMessageSenderRegistryFacet: approvedMessageSenderRegistryFacet
        });

        dfpkg = IApprovedMessageSenderRegistryDFPkg(
            address(
                factory.deployPackageWithArgs(
                    type(ApprovedMessageSenderRegistryDFPkg).creationCode,
                    abi.encode(pkgInitArgs),
                    abi.encode(type(ApprovedMessageSenderRegistryDFPkg).name, pkgInitArgs)._hash()
                )
            )
        );
    }

    function deployApprovedMessageSenderRegistry(
        IDiamondPackageCallBackFactory diamondFactory,
        IApprovedMessageSenderRegistryDFPkg dfpkg,
        address owner
    ) internal returns (IApprovedMessageSenderRegistry registry) {
        IApprovedMessageSenderRegistryDFPkg.PkgArgs memory pkgArgs = IApprovedMessageSenderRegistryDFPkg.PkgArgs({owner: owner});

        registry = IApprovedMessageSenderRegistry(diamondFactory.deploy(dfpkg, abi.encode(pkgArgs)));
        HEVM.label(address(registry), "ApprovedMessageSenderRegistry");
    }
}