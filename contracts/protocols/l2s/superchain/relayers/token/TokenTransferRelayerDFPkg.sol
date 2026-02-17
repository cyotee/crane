// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {MultiStepOwnableRepo} from '@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol';
import {Permit2AwareRepo} from '@crane/contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol';
import {TokenTransferRelayerRepo} from '@crane/contracts/protocols/l2s/superchain/relayers/token/TokenTransferRelayerRepo.sol';
import {IDiamond} from '@crane/contracts/interfaces/IDiamond.sol';
import {IFacet} from '@crane/contracts/interfaces/IFacet.sol';
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IMultiStepOwnable} from '@crane/contracts/interfaces/IMultiStepOwnable.sol';
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {IApprovedMessageSenderRegistry} from '@crane/contracts/interfaces/IApprovedMessageSenderRegistry.sol';
import {ITokenTransferRelayer} from '@crane/contracts/interfaces/ITokenTransferRelayer.sol';
import {DFPkgBase} from '@crane/contracts/factories/diamondPkg/DFPkgBase.sol';

interface ITokenTransferRelayerDFPkg is IDiamondFactoryPackage {
    struct PkgInit {
        IFacet ownableFacet;
        IFacet tokenTransferRelayerFacet;
        IPermit2 permit2;
    }

    struct PkgArgs {
        address owner;
        IApprovedMessageSenderRegistry approvedMessageSenderRegistry;
    }
}

contract TokenTransferRelayerDFPkg is DFPkgBase, ITokenTransferRelayerDFPkg {

    IFacet public immutable OWNABLE_FACET;

    IFacet public immutable TOKEN_TRANSFER_RELAYER_FACET;

    IPermit2 public immutable PERMIT2;

    constructor(PkgInit memory init) {
        OWNABLE_FACET = init.ownableFacet;
        TOKEN_TRANSFER_RELAYER_FACET = init.tokenTransferRelayerFacet;
        PERMIT2 = init.permit2;
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function packageName() public pure override(IDiamondFactoryPackage, DFPkgBase) returns (string memory name) {
        return type(TokenTransferRelayerDFPkg).name;
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function facetAddresses() public view override(IDiamondFactoryPackage, DFPkgBase) returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](2);
        facetAddresses_[0] = address(OWNABLE_FACET);
        facetAddresses_[1] = address(TOKEN_TRANSFER_RELAYER_FACET);
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function facetInterfaces() public pure override(IDiamondFactoryPackage, DFPkgBase) returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IMultiStepOwnable).interfaceId;
        interfaces[1] = type(ITokenTransferRelayer).interfaceId;
        return interfaces;
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function facetCuts() public view override(IDiamondFactoryPackage, DFPkgBase) returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](2);
        facetCuts_[0] = IDiamond.FacetCut({
            facetAddress: address(OWNABLE_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: OWNABLE_FACET.facetFuncs()
        });
        facetCuts_[1] = IDiamond.FacetCut({
            facetAddress: address(TOKEN_TRANSFER_RELAYER_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: TOKEN_TRANSFER_RELAYER_FACET.facetFuncs()
        });
    }

    /**
     * @inheritdoc IDiamondFactoryPackage
     */
    function initAccount(bytes memory initArgs) public virtual override(IDiamondFactoryPackage, DFPkgBase) {
        PkgArgs memory args = abi.decode(initArgs, (PkgArgs));
        MultiStepOwnableRepo._initialize(args.owner, 3 days);
        TokenTransferRelayerRepo._initialize(args.approvedMessageSenderRegistry);
        Permit2AwareRepo._initialize(PERMIT2);

    }

}