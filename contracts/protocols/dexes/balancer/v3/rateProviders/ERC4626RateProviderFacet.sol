// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

import {EfficientHashLib} from "@solady/utils/EfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

// import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "@crane/contracts/GeneralErrors.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IERC4626RateProvider} from "@crane/contracts/interfaces/IERC4626RateProvider.sol";
import {ERC4626RateProviderRepo} from "contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderRepo.sol";
import {BetterSafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";
import {ERC4626RateProviderTarget} from "@crane/contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderTarget.sol";

contract ERC4626RateProviderFacet is
    ERC4626RateProviderTarget,
    IFacet
{
    // using EfficientHashLib for bytes;

    /* ---------------------------------------------------------------------- */
    /*                                 IFacet                                 */
    /* ---------------------------------------------------------------------- */

    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     */
    function facetName() public pure returns (string memory name) {
        return type(ERC4626RateProviderFacet).name;
    }
    // end::facetName[]

    function facetInterfaces()
        public
        pure
        returns (bytes4[] memory interfaces)
    {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IRateProvider).interfaceId;
        interfaces[1] = type(IERC4626RateProvider).interfaceId;
    }

    function facetFuncs() public pure virtual override(IFacet) returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IRateProvider.getRate.selector;
        funcs[1] = IERC4626RateProvider.erc4626Vault.selector;
    }

    // tag::facetMetadata()[]
    /**
     * @inheritdoc IFacet
     */
    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
    // end::facetMetadata()[]
}
