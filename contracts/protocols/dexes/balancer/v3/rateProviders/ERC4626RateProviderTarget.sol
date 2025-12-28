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

contract ERC4626RateProviderTarget is
    IERC4626RateProvider
{
    /* ---------------------------------------------------------------------- */
    /*                              IRateProvider                             */
    /* ---------------------------------------------------------------------- */

    function getRate() public view returns (uint256 rate) {
        // Deliberately NOT using convertToAssets.
        // Typical expectation for a rate is to capture the actual redeemable value.
        // convertToAssets is specified to NOT capture fees and other redemption amount adjustments.
        // I use previewRedeem so I ensure I am capturing all relevant redeemed amount adjustments.
        rate = ERC4626RateProviderRepo._erc4626Vault().previewRedeem(1e18);
        return rate * (10 ** (18 - ERC4626RateProviderRepo._assetDecimals()));
    }

    /* ---------------------------------------------------------------------- */
    /*                          IERC4626RateProvider                          */
    /* ---------------------------------------------------------------------- */

    function erc4626Vault() public view returns (IERC4626) {
        return ERC4626RateProviderRepo._erc4626Vault();
    }
}
