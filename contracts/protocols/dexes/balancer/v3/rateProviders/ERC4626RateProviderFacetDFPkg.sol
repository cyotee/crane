// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import { IRateProvider } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { Create3AwareContract } from "contracts/factories/create2/aware/Create3AwareContract.sol";
import { IDiamond } from "contracts/interfaces/IDiamond.sol";
import { IFacet } from "contracts/interfaces/IFacet.sol";
import { IDiamondFactoryPackage } from "contracts/interfaces/IDiamondFactoryPackage.sol";

import { IERC4626RateProvider } from "contracts/interfaces/IERC4626RateProvider.sol";
import { ERC4626RateProviderStorage } from "contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderStorage.sol";

contract ERC4626RateProviderFacetDFPkg
is
    ERC4626RateProviderStorage,
    Create3AwareContract,
    IFacet,
    IDiamondFactoryPackage,
    // IRateProvider,
    IERC4626RateProvider
{

    address immutable SELF;

    constructor(CREATE3InitData memory create3InitData_)
    Create3AwareContract(create3InitData_){
        SELF = address(this);
    }
    
    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    function facetInterfaces()
    public pure virtual override(IFacet, IDiamondFactoryPackage) returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IRateProvider).interfaceId;
        interfaces[1] = type(IERC4626RateProvider).interfaceId;
    }
    
    function facetFuncs()
    public pure virtual override(IFacet) returns(bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IRateProvider.getRate.selector;
        funcs[1] = IERC4626RateProvider.erc4626Vault.selector;
    }

    /* ---------------------------------------------------------------------- */
    /*                         IDiamondFactoryPackage                         */
    /* ---------------------------------------------------------------------- */

    function facetCuts()
    public view returns(IDiamond.FacetCut[] memory facetCuts_) {

        facetCuts_ = new IDiamond.FacetCut[](1);

        facetCuts_[0] = IDiamond.FacetCut({
            facetAddress: address(SELF),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: facetFuncs()
        });
    }

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
        return keccak256(pkgArgs);
    }

    function processArgs(
        bytes memory pkgArgs
    ) public pure returns(
        bytes memory processedPkgArgs
    ) {
        return pkgArgs;
    }

    function updatePkg(
        address expectedProxy,
        bytes memory pkgArgs
    ) public returns (bool) {}

    function initAccount(
        bytes memory initArgs
    ) public {
        IERC4626 decodedArgs
            = abi.decode(initArgs, (IERC4626));
        _initERC4626RateProvider(
            decodedArgs
        );
    }

    // account
    function postDeploy(address)
    public pure returns(bytes memory postDeployData) {
        return "";
    }

    /* ---------------------------------------------------------------------- */
    /*                              IRateProvider                             */
    /* ---------------------------------------------------------------------- */

    function getRate() public view returns (uint256) {
        return _erc4626Vault().previewRedeem(1e18);
    }

    /* ---------------------------------------------------------------------- */
    /*                          IERC4626RateProvider                          */
    /* ---------------------------------------------------------------------- */

    function erc4626Vault() public view returns (IERC4626) {
        return _erc4626Vault();
    }

}