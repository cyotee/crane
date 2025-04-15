// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {
    IDiamondFactoryPackage
} from "../../../interfaces/IDiamondFactoryPackage.sol";
import {IFacet} from "../../../interfaces/IFacet.sol";
import {IDiamond} from "../../../interfaces/IDiamond.sol";
import {
    IERC20PermitStorage,
    ERC20PermitStorage
} from "./utils/ERC20PermitStorage.sol";
import {BetterERC20Permit} from "./BetterERC20Permit.sol";
import {
    Create3AwareContract
} from "../../../factories/create2/aware/Create3AwareContract.sol";
import {
    ICreate3Aware
} from "../../../interfaces/ICreate3Aware.sol";

interface IERC20PermitDFPkg
{

    struct ERC20PermitDFPkgInit {
        IFacet erc20PermitFacet;
    }

    struct ERC20PermitDFPkgArgs {
        IERC20PermitStorage.ERC20PermitTargetInit erc20PermitTargetInit;
    }

}

contract ERC20PermitDFPkg
is
ERC20PermitStorage,
Create3AwareContract,
IERC20PermitDFPkg,
IDiamondFactoryPackage
{

    IFacet immutable ERC20_PERMIT_FACET;

    constructor(ICreate3Aware.CREATE3InitData memory create3InitData) Create3AwareContract(create3InitData) {
        ERC20PermitDFPkgInit memory erc20PermitDFPkgInit_ = abi.decode(initData, (ERC20PermitDFPkgInit));
        ERC20_PERMIT_FACET = erc20PermitDFPkgInit_.erc20PermitFacet;
    }

    function facetInterfaces()
    public view returns(bytes4[] memory interfaces) {
        return ERC20_PERMIT_FACET.facetInterfaces();
    }

    function facetCuts()
    public view returns(IDiamond.FacetCut[] memory facetCuts_) {

        facetCuts_ = new IDiamond.FacetCut[](1);

        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(ERC20_PERMIT_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: ERC20_PERMIT_FACET.facetFuncs()
        });

    }

    /**
     * @return config Unified function to retrieved `facetInterfaces()` AND `facetCuts()` in one call.
     */
    function diamondConfig()
    public view returns(DiamondConfig memory config) {

        config = IDiamondFactoryPackage.DiamondConfig({
            facetCuts: facetCuts(),
            interfaces: facetInterfaces()
        });
    }

    function calcSalt(
        bytes memory pkgArgs
    ) public pure returns(bytes32 salt) {
        (
            ERC20PermitDFPkgArgs memory decodedArgs
        ) = abi.decode(pkgArgs, (ERC20PermitDFPkgArgs));

        if(
            bytes(decodedArgs.erc20PermitTargetInit.erc20Init.name).length == 0
        ) {
            if(
                bytes(decodedArgs.erc20PermitTargetInit.erc20Init.symbol).length != 0
            ) {
                decodedArgs.erc20PermitTargetInit.erc20Init.name
                = decodedArgs.erc20PermitTargetInit.erc20Init.symbol;
            }
            else {
                revert NoNameAndSymbol();
            }
        }
        else
        if(
            bytes(decodedArgs.erc20PermitTargetInit.erc20Init.symbol).length == 0
        ) {
            decodedArgs.erc20PermitTargetInit.erc20Init.symbol
            = decodedArgs.erc20PermitTargetInit.erc20Init.name;
        }

        if(decodedArgs.erc20PermitTargetInit.erc20Init.totalSupply != 0) {
            if(decodedArgs.erc20PermitTargetInit.erc20Init.recipient == address(0)) {
                revert NoRecipient();
            }
        }

        if(decodedArgs.erc20PermitTargetInit.erc20Init.decimals == 0) {
            decodedArgs.erc20PermitTargetInit.erc20Init.decimals = 18;
        }

        if(bytes(decodedArgs.erc20PermitTargetInit.version).length == 0) {
            decodedArgs.erc20PermitTargetInit.version = "1";
        }

        return keccak256(abi.encode(decodedArgs));
    }

    error NoNameAndSymbol();

    error NoRecipient();

    function processArgs(
        bytes memory pkgArgs
    ) public pure returns(
        bytes memory processedPkgArgs
    ) {
        (
            ERC20PermitDFPkgArgs memory decodedArgs
        ) = abi.decode(pkgArgs, (ERC20PermitDFPkgArgs));

        if(
            bytes(decodedArgs.erc20PermitTargetInit.erc20Init.name).length == 0
        ) {
            if(
                bytes(decodedArgs.erc20PermitTargetInit.erc20Init.symbol).length != 0
            ) {
                decodedArgs.erc20PermitTargetInit.erc20Init.name
                = decodedArgs.erc20PermitTargetInit.erc20Init.symbol;
            }
            else {
                revert NoNameAndSymbol();
            }
        }
        else
        if(
            bytes(decodedArgs.erc20PermitTargetInit.erc20Init.symbol).length == 0
        ) {
            decodedArgs.erc20PermitTargetInit.erc20Init.symbol
            = decodedArgs.erc20PermitTargetInit.erc20Init.name;
        }

        if(decodedArgs.erc20PermitTargetInit.erc20Init.totalSupply != 0) {
            if(decodedArgs.erc20PermitTargetInit.erc20Init.recipient == address(0)) {
                revert NoRecipient();
            }
        }

        if(decodedArgs.erc20PermitTargetInit.erc20Init.decimals == 0) {
            decodedArgs.erc20PermitTargetInit.erc20Init.decimals = 18;
        }

        if(bytes(decodedArgs.erc20PermitTargetInit.version).length == 0) {
            decodedArgs.erc20PermitTargetInit.version = "1";
        }

        return abi.encode(decodedArgs.erc20PermitTargetInit);
    }

    function updatePkg(
        address , // expectedProxy,
        bytes memory // pkgArgs
    ) public virtual returns(bool) {
        return true;
    }

    function initAccount(
        bytes memory initArgs
    ) public {
        
        (
            IERC20PermitStorage.ERC20PermitTargetInit
            memory decodedArgs
        ) = abi.decode(initArgs, (IERC20PermitStorage.ERC20PermitTargetInit));

        _initERC20Permit(decodedArgs);

    }

    // account
    function postDeploy(address)
    public pure returns(bytes memory postDeployData) {
        return "";
    }

}