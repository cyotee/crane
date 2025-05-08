// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BetterIERC20 as IERC20} from "./BetterIERC20.sol";
import {IERC2612} from "./extensions/IERC2612.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";
import {IERC20MintBurn} from "./IERC20MintBurn.sol";
import {IOwnable} from "../../access/ownable/IOwnable.sol";
import {IOperable} from "../../access/operable/IOperable.sol";

import {
    ERC20MintBurnOperableTarget
} from "./ERC20MintBurnOperableTarget.sol";

import {IDiamond} from "../../utils/introspection/erc2535/IDiamond.sol";

import {
    IFacet
} from "../../factories/create2/callback/diamondPkg/IFacet.sol";

import {
    IDiamondFactoryPackage
} from "../../factories/create2/callback/diamondPkg/IDiamondFactoryPackage.sol";

import {
    Create2CallbackContract
} from "../../factories/create2/callback/Create2CallbackContract.sol";

interface IERC20MintBurnOperableFacetDFPkg {
    struct PkgInit {
        IFacet ownableFacet;
        IFacet operableFacet;
        IFacet erc20PermitFacet;
    }
    

}

contract ERC20MintBurnOperableFacetDFPkg
is
Create2CallbackContract,
ERC20MintBurnOperableTarget
,IFacet
,IDiamondFactoryPackage
,IERC20MintBurnOperableFacetDFPkg
{

    IDiamondFactoryPackage immutable SELF;

    // IFacet immutable ownableFacet;
    IFacet immutable public OWNABLE_FACET;
    IFacet immutable public OPERABLE_FACET;
    IFacet immutable public ERC20_PERMIT_FACET;

    constructor(
        // PkgInit memory pkgInit
    ) {
        SELF = this;
        PkgInit memory pkgInit = abi.decode(initData, (PkgInit));
        OWNABLE_FACET = pkgInit.ownableFacet;
        OPERABLE_FACET = pkgInit.operableFacet;
        ERC20_PERMIT_FACET = pkgInit.erc20PermitFacet;
    }

    function facetInterfaces()
    public view virtual
    override(
        IFacet,
        IDiamondFactoryPackage
    )
    returns(bytes4[] memory interfaces) {
        interfaces = new bytes4[](6);
        interfaces[0] = type(IERC20).interfaceId;
        interfaces[1] = type(IERC2612).interfaceId;
        interfaces[2] = type(IERC5267).interfaceId;
        interfaces[3] = type(IERC20MintBurn).interfaceId;
        interfaces[4] = type(IOwnable).interfaceId;
        interfaces[5] = type(IOperable).interfaceId;
    }

    function facetFuncs()
    public pure virtual 
    returns(bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IERC20MintBurn.mint.selector;
        funcs[1] = IERC20MintBurn.burn.selector;
    }

    function facetCuts()
    public view virtual returns(IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](4);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(OWNABLE_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: OWNABLE_FACET.facetFuncs()
        });
        facetCuts_[1] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(OPERABLE_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: OPERABLE_FACET.facetFuncs()
        });
        facetCuts_[2] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC20_PERMIT_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC20_PERMIT_FACET.facetFuncs()
        });

        facetCuts_[3] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(SELF),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: facetFuncs()
        });
    }

    function diamondConfig()
    public view virtual returns(IDiamondFactoryPackage.DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({
            facetCuts: facetCuts(),
            interfaces: facetInterfaces()
        });
    }

    function calcSalt(
        bytes memory pkgArgs
    ) public pure returns(bytes32 salt) {
        salt = keccak256(abi.encode(pkgArgs));
    }

    function processArgs(
        bytes memory pkgArgs
    ) public pure returns(
        // bytes32 salt,
        bytes memory processedPkgArgs
    ) {
        // salt = keccak256(abi.encode(pkgArgs));
        processedPkgArgs = pkgArgs;
    }

    /**
     * @dev A standardized proxy initialization function.
     */
    function initAccount(
        bytes memory initArgs
    ) public {
        (
            MintBurnOperableAccountInit memory accountInit
        ) = abi.decode(initArgs, (MintBurnOperableAccountInit));
        _initERC20(accountInit);
    }

    // account
    function postDeploy(address )
    public virtual returns(bytes memory postDeployData) {
        return "";
    }

}