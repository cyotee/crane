// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

// import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */


/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {IRateProvider} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IRateProvider.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import "@crane/contracts/GeneralErrors.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IERC4626RateProvider} from "@crane/contracts/interfaces/IERC4626RateProvider.sol";
import {ERC4626RateProviderRepo} from "@crane/contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderRepo.sol";
import {BetterSafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";

interface IERC4626RateProviderFacetDFPkg is IDiamondFactoryPackage {
    struct PkgInit {
        IFacet erc4626RateProviderFacet;
        IDiamondPackageCallBackFactory diamondPackageFactory;
    }

    struct PkgArgs {
        IERC4626 erc4626Vault;
    }

    function deployRateProvider(IERC4626 erc4626Vault) external returns (IERC4626RateProvider rateProvider);
}

contract ERC4626RateProviderFacetDFPkg is
    IERC4626RateProviderFacetDFPkg
{
    using BetterEfficientHashLib for bytes;

    IFacet immutable ERC4626_RATE_PROVIDER_FACET;

    IDiamondPackageCallBackFactory public DIAMOND_PACKAGE_FACTORY;

    constructor(PkgInit memory pkgInit) {
        ERC4626_RATE_PROVIDER_FACET = pkgInit.erc4626RateProviderFacet;
        DIAMOND_PACKAGE_FACTORY = pkgInit.diamondPackageFactory;
    }

    /* -------------------------------------------------------------------------- */
    /*                       IERC4626RateProviderFacetDFPkg                       */
    /* -------------------------------------------------------------------------- */

    function deployRateProvider(IERC4626 erc4626Vault)
        external
        returns (IERC4626RateProvider rateProvider)
    {
        rateProvider = IERC4626RateProvider(
            DIAMOND_PACKAGE_FACTORY.deploy(
                this,
                abi.encode(PkgArgs({erc4626Vault: erc4626Vault}))
            )
        );
        return rateProvider;
    }

    /* ---------------------------------------------------------------------- */
    /*                         IDiamondFactoryPackage                         */
    /* ---------------------------------------------------------------------- */

    function packageName() public pure returns (string memory name_) {
        return type(ERC4626RateProviderFacetDFPkg).name;
    }

    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](1);
        facetAddresses_[0] = address(ERC4626_RATE_PROVIDER_FACET);
    }

    function facetInterfaces()
        public
        pure
        returns (bytes4[] memory interfaces)
    {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IRateProvider).interfaceId;
        interfaces[1] = type(IERC4626RateProvider).interfaceId;
    }

    function packageMetadata()
        public
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets)
    {
        name_ = packageName();
        interfaces = facetInterfaces();
        facets = facetAddresses();
    }

    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](1);

        facetCuts_[0] = IDiamond.FacetCut({
            facetAddress: address(ERC4626_RATE_PROVIDER_FACET), action: IDiamond.FacetCutAction.Add, functionSelectors: ERC4626_RATE_PROVIDER_FACET.facetFuncs()
        });
    }

    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        return pkgArgs._hash();
    }

    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        return pkgArgs;
    }

    function updatePkg(address expectedProxy, bytes memory pkgArgs) public returns (bool) {}

    function initAccount(bytes memory initArgs) public {
        PkgArgs memory decodedArgs = abi.decode(initArgs, (PkgArgs));
        if (address(decodedArgs.erc4626Vault) == address(0)) {
            revert ArgumentMustNotBeZero(0);
        }
        ERC4626RateProviderRepo._initialize(
            decodedArgs.erc4626Vault,
            BetterSafeERC20.safeDecimals(IERC20Metadata(address(decodedArgs.erc4626Vault.asset())))
        );
    }

    // account
    function postDeploy(address) public pure returns (bool) {
        return true;
    }

}
