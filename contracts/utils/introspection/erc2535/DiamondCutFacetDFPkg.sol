// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    BetterAddress as Address
} from "../../BetterAddress.sol";
import {
    IOwnable
} from "../../../access/ownable/IOwnable.sol";
import {
    IDiamond
} from "./IDiamond.sol";
import {
    IDiamondCut
} from "./IDiamondCut.sol";
import {
    DiamondCutTarget
} from "./DiamondCutTarget.sol";
import {
    IDiamondFactoryPackage
} from "../../../factories/create2/callback/diamondPkg/IDiamondFactoryPackage.sol";
import {
    Create2CallbackContract
} from "../../../factories/create2/callback/Create2CallbackContract.sol";
import {
    IFacet
} from "../../../factories/create2/callback/diamondPkg/IFacet.sol";
import {
    ERC165Storage
} from "../erc165/ERC165Storage.sol";

interface IDiamondCutFacetDFPkg {

    struct DiamondCutPkgInit {
        IFacet ownableFacet;
    }

    struct AccountInit {
        address owner;
        bytes diamondCutData;
    }

}

contract DiamondCutFacetDFPkg
is
ERC165Storage,
DiamondCutTarget,
Create2CallbackContract,
IDiamondFactoryPackage,
IDiamondCutFacetDFPkg
{
    using Address for address;

    IDiamondFactoryPackage immutable SELF;
    IFacet immutable ownableFacet;

    constructor(
        // address ownableFacet_
    ) {
        DiamondCutPkgInit memory pkgInitArgs = abi.decode(initData, (DiamondCutPkgInit));
        SELF = this;
        ownableFacet = pkgInitArgs.ownableFacet;
    }
    
    function facetInterfaces()
    public view virtual
    returns(bytes4[] memory interfaces) {
        interfaces =  new bytes4[](2);
        interfaces[0] = type(IOwnable).interfaceId;
        interfaces[1] = type(IDiamondCut).interfaceId;
    }

    function facetFuncs()
    public pure virtual
    returns(bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IDiamondCut.diamondCut.selector;
    }


    function _ownableFacetFuncs()
    internal view virtual returns(bytes4[] memory funcs) {
        funcs = new bytes4[](5);
        funcs[0] = IOwnable.owner.selector;
        funcs[1] = IOwnable.proposedOwner.selector;
        funcs[2] = IOwnable.transferOwnership.selector;
        funcs[3] = IOwnable.acceptOwnership.selector;
        funcs[4] = IOwnable.renounceOwnership.selector;
    }

    function facetCuts()
    public view virtual override returns(IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](2);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ownableFacet),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ownableFacet.facetFuncs()
        });
        facetCuts_[1] = IDiamond.FacetCut({
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

    function initAccount(
        bytes memory initArgs
    ) public virtual override {
        (
            AccountInit memory accountInit
        ) = abi.decode(initArgs, (AccountInit));
        _initOwner(accountInit.owner);
        if(accountInit.diamondCutData.length > 0) {
            (
                IDiamond.FacetCut[] memory diamondCut_,
                bytes4[] memory supportedInterfaces_,
                address initTarget,
                bytes memory initCalldata
            ) = abi.decode(
                accountInit.diamondCutData,
                (
                    IDiamond.FacetCut[],
                    bytes4[],
                    address,
                    bytes
                )
            );
            if(diamondCut_.length > 0) {
                _diamondCut(
                    diamondCut_,
                    initTarget,
                    initCalldata
                );
            }
            if(supportedInterfaces_.length > 0) {
                _initERC165(
                    supportedInterfaces_
                );
            }
        }
    }

    /**
     * @dev account The address of the account on which to call the post-deploy hook.
     * @return postDeployData The data to be returned from the post-deploy hook.
     */
    function postDeploy(address)
    public virtual returns(bytes memory postDeployData) {
        return "";
    }

}