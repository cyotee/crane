// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {VM_ADDRESS} from "@crane/contracts/constants/FoundryConstants.sol";
import {Vm as FoundryVM} from "forge-std/Vm.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {IFacet} from '@crane/contracts/interfaces/IFacet.sol';
import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IMultiStepOwnable} from '@crane/contracts/interfaces/IMultiStepOwnable.sol';
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {IApprovedMessageSenderRegistry} from '@crane/contracts/interfaces/IApprovedMessageSenderRegistry.sol';
import {ITokenTransferRelayer} from '@crane/contracts/interfaces/ITokenTransferRelayer.sol';
import {TokenTransferRelayerFacet} from '@crane/contracts/protocols/l2s/superchain/relayers/token/TokenTransferRelayerFacet.sol';
import {ITokenTransferRelayerDFPkg, TokenTransferRelayerDFPkg} from '@crane/contracts/protocols/l2s/superchain/relayers/token/TokenTransferRelayerDFPkg.sol';

library TokenTransferRelayerFactoryService {
    using BetterEfficientHashLib for bytes;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    FoundryVM constant HEVM = FoundryVM(VM_ADDRESS);

    function deployTokenTransferRelayerFacet(ICreate3FactoryProxy create3Factory) internal returns (IFacet facet) {
        facet = create3Factory.deployFacet(
            type(TokenTransferRelayerFacet).creationCode, abi.encode(type(TokenTransferRelayerFacet).name)._hash()
        );
        HEVM.label(address(facet), type(TokenTransferRelayerFacet).name);
    }

    function deployTokenTransferRelayerDFPkg(
        ICreate3FactoryProxy factory,
        IFacet ownableFacet,
        IFacet tokenTransferRelayerFacet,
        IPermit2 permit2
    ) internal returns (ITokenTransferRelayerDFPkg dfpkg) {
        ITokenTransferRelayerDFPkg.PkgInit memory pkgInitArgs = ITokenTransferRelayerDFPkg.PkgInit({
            ownableFacet: ownableFacet,
            tokenTransferRelayerFacet: tokenTransferRelayerFacet,
            permit2: permit2
        });

        dfpkg = ITokenTransferRelayerDFPkg(
            address(
                factory.deployPackageWithArgs(
                    type(TokenTransferRelayerDFPkg).creationCode,
                    abi.encode(pkgInitArgs),
                    abi.encode(type(TokenTransferRelayerDFPkg).name, pkgInitArgs)._hash()
                )
            )
        );
    }

    function deployTokenTransferRelayer(
        IDiamondPackageCallBackFactory diamondFactory,
        ITokenTransferRelayerDFPkg dfpkg,
        address owner,
        IApprovedMessageSenderRegistry approvedMessageSenderRegistry
    ) internal returns (ITokenTransferRelayer relayer) {
        ITokenTransferRelayerDFPkg.PkgArgs memory pkgArgs = ITokenTransferRelayerDFPkg.PkgArgs({
            owner: owner,
            approvedMessageSenderRegistry: approvedMessageSenderRegistry
        });

        relayer = ITokenTransferRelayer(diamondFactory.deploy(dfpkg, abi.encode(pkgArgs)));
        HEVM.label(address(relayer), "TokenTransferRelayer");
    }
}