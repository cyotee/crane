// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {MultiStepOwnableRepo} from '@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol';
import {IDiamond} from '@crane/contracts/interfaces/IDiamond.sol';
import {IFacet} from '@crane/contracts/interfaces/IFacet.sol';
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IMultiStepOwnable} from '@crane/contracts/interfaces/IMultiStepOwnable.sol';
import {IOperable} from '@crane/contracts/interfaces/IOperable.sol';
import {DFPkgBase} from '@crane/contracts/factories/diamondPkg/DFPkgBase.sol';
import {ISuperChainBridgeTokenRegistry} from '@crane/contracts/interfaces/ISuperChainBridgeTokenRegistry.sol';

interface ISuperChainBridgeTokenRegistryDFPkg is IDiamondFactoryPackage {

    struct PkgInit {
        IFacet ownableFacet;
        IFacet operableFacet;
        IFacet superChainBridgeTokenRegistryFacet;
    }

    struct PkgArgs {
        address owner;
    }

}

contract SuperChainBridgeTokenRegistryDFPkg is DFPkgBase, ISuperChainBridgeTokenRegistryDFPkg {

    IFacet public immutable OWNABLE_FACET;
    IFacet public immutable OPERABLE_FACET;
    IFacet public immutable SUPER_CHAIN_BRIDGE_TOKEN_REGISTRY_FACET;

    constructor(PkgInit memory init) {
        OWNABLE_FACET = init.ownableFacet;
        OPERABLE_FACET = init.operableFacet;
        SUPER_CHAIN_BRIDGE_TOKEN_REGISTRY_FACET = init.superChainBridgeTokenRegistryFacet;
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function packageName() public pure override(IDiamondFactoryPackage, DFPkgBase) returns (string memory name) {
        name = 'SuperChainBridgeTokenRegistryDFPkg';
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function facetAddresses() public view override(IDiamondFactoryPackage, DFPkgBase) returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](3);
        facetAddresses_[0] = address(OWNABLE_FACET);
        facetAddresses_[1] = address(OPERABLE_FACET);
        facetAddresses_[2] = address(SUPER_CHAIN_BRIDGE_TOKEN_REGISTRY_FACET);
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function facetInterfaces() public pure override(IDiamondFactoryPackage, DFPkgBase) returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](3);
        interfaces[0] = type(IMultiStepOwnable).interfaceId;
        interfaces[1] = type(IOperable).interfaceId;
        interfaces[2] = type(ISuperChainBridgeTokenRegistry).interfaceId;
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
            facetAddress: address(SUPER_CHAIN_BRIDGE_TOKEN_REGISTRY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: SUPER_CHAIN_BRIDGE_TOKEN_REGISTRY_FACET.facetFuncs()
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