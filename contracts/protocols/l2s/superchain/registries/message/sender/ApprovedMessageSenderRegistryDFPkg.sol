// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {MultiStepOwnableRepo} from '@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol';
import {IDiamond} from '@crane/contracts/interfaces/IDiamond.sol';
import {IFacet} from '@crane/contracts/interfaces/IFacet.sol';
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IMultiStepOwnable} from '@crane/contracts/interfaces/IMultiStepOwnable.sol';
import {IOperable} from '@crane/contracts/interfaces/IOperable.sol';
import {IApprovedMessageSenderRegistry} from '@crane/contracts/interfaces/IApprovedMessageSenderRegistry.sol';
import {DFPkgBase} from '@crane/contracts/factories/diamondPkg/DFPkgBase.sol';

interface IApprovedMessageSenderRegistryDFPkg is IDiamondFactoryPackage {

    struct PkgInit {
        IFacet ownableFacet;
        IFacet operableFacet;
        IFacet approvedMessageSenderRegistryFacet;
    }

    struct PkgArgs {
        address owner;
    }

}

contract ApprovedMessageSenderRegistryDFPkg is DFPkgBase, IApprovedMessageSenderRegistryDFPkg {

    IFacet public immutable OWNABLE_FACET;
    IFacet public immutable OPERABLE_FACET;
    IFacet public immutable APPROVED_MESSAGE_SENDER_REGISTRY_FACET;

    constructor(PkgInit memory init) {
        OWNABLE_FACET = init.ownableFacet;
        OPERABLE_FACET = init.operableFacet;
        APPROVED_MESSAGE_SENDER_REGISTRY_FACET = init.approvedMessageSenderRegistryFacet;
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function packageName() public pure override(IDiamondFactoryPackage, DFPkgBase) returns (string memory name) {
        name = 'ApprovedMessageSenderRegistryDFPkg';
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function facetAddresses() public view override(IDiamondFactoryPackage, DFPkgBase) returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](3);
        facetAddresses_[0] = address(OWNABLE_FACET);
        facetAddresses_[1] = address(OPERABLE_FACET);
        facetAddresses_[2] = address(APPROVED_MESSAGE_SENDER_REGISTRY_FACET);
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function facetInterfaces() public pure override(IDiamondFactoryPackage, DFPkgBase) returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](3);
        interfaces[0] = type(IMultiStepOwnable).interfaceId;
        interfaces[1] = type(IOperable).interfaceId;
        interfaces[2] = type(IApprovedMessageSenderRegistry).interfaceId;
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function facetCuts() public view override(IDiamondFactoryPackage, DFPkgBase) returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](3);
        facetCuts_[0] = IDiamond.FacetCut({
            facetAddress: address(OWNABLE_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: OWNABLE_FACET.facetFuncs()
        });
        facetCuts_[1] = IDiamond.FacetCut({
            facetAddress: address(OPERABLE_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: OPERABLE_FACET.facetFuncs()
        });
        facetCuts_[2] = IDiamond.FacetCut({
            facetAddress: address(APPROVED_MESSAGE_SENDER_REGISTRY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: APPROVED_MESSAGE_SENDER_REGISTRY_FACET.facetFuncs()
        });
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function initAccount(bytes memory initArgs) public virtual override(IDiamondFactoryPackage, DFPkgBase) {
        PkgArgs memory args = abi.decode(initArgs, (PkgArgs));
        MultiStepOwnableRepo._initialize(args.owner, 3 days);
    }

}