// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {BetterSafeERC20 as SafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";

import {
    IMorpho,
    Id,
    MarketParams,
    Market,
    Position
} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";
import {MarketParamsLib} from "@crane/contracts/external/morpho/blue/libraries/MarketParamsLib.sol";
import {MorphoBalancesLib} from "@crane/contracts/external/morpho/blue/libraries/periphery/MorphoBalancesLib.sol";
import {MorphoLib} from "@crane/contracts/external/morpho/blue/libraries/periphery/MorphoLib.sol";

// tag::MorphoBlueService[]
/**
 * @title MorphoBlueService - Stateless helpers for Morpho Blue market ops.
 * @author Crane
 * @dev Internal API (`_`). Structs avoid stack-too-deep. Approves Morpho as needed then calls core methods.
 */
library MorphoBlueService {
    using SafeERC20 for IERC20;
    using MarketParamsLib for MarketParams;
    using MorphoBalancesLib for IMorpho;
    using MorphoLib for IMorpho;

    // tag::MarketCreateParams[]
    struct MarketCreateParams {
        IMorpho morpho;
        MarketParams marketParams;
    }
    // end::MarketCreateParams[]

    // tag::SupplyParams[]
    struct SupplyParams {
        IMorpho morpho;
        MarketParams marketParams;
        uint256 assets;
        uint256 shares;
        address onBehalf;
        bytes data;
    }
    // end::SupplyParams[]

    // tag::BorrowParams[]
    struct BorrowParams {
        IMorpho morpho;
        MarketParams marketParams;
        uint256 assets;
        uint256 shares;
        address onBehalf;
        address receiver;
    }
    // end::BorrowParams[]

    // tag::RepayParams[]
    struct RepayParams {
        IMorpho morpho;
        MarketParams marketParams;
        uint256 assets;
        uint256 shares;
        address onBehalf;
        bytes data;
    }
    // end::RepayParams[]

    // tag::WithdrawParams[]
    struct WithdrawParams {
        IMorpho morpho;
        MarketParams marketParams;
        uint256 assets;
        uint256 shares;
        address onBehalf;
        address receiver;
    }
    // end::WithdrawParams[]

    // tag::CollateralParams[]
    struct CollateralParams {
        IMorpho morpho;
        MarketParams marketParams;
        uint256 assets;
        address onBehalf;
        bytes data;
    }
    // end::CollateralParams[]

    // tag::WithdrawCollateralParams[]
    struct WithdrawCollateralParams {
        IMorpho morpho;
        MarketParams marketParams;
        uint256 assets;
        address onBehalf;
        address receiver;
    }
    // end::WithdrawCollateralParams[]

    // tag::LiquidateParams[]
    struct LiquidateParams {
        IMorpho morpho;
        MarketParams marketParams;
        address borrower;
        uint256 seizedAssets;
        uint256 repaidShares;
        bytes data;
    }
    // end::LiquidateParams[]

    /* ---------------------------------------------------------------------- */
    /*                              Id / market                               */
    /* ---------------------------------------------------------------------- */

    // tag::_id(MarketParams)[]
    function _id(MarketParams memory marketParams) internal pure returns (Id) {
        return marketParams.id();
    }
    // end::_id(MarketParams)[]

    // tag::_createMarket(MarketCreateParams)[]
    function _createMarket(MarketCreateParams memory p) internal {
        p.morpho.createMarket(p.marketParams);
    }
    // end::_createMarket(MarketCreateParams)[]

    // tag::_createMarket(IMorpho-MarketParams)[]
    function _createMarket(IMorpho morpho, MarketParams memory marketParams) internal {
        morpho.createMarket(marketParams);
    }
    // end::_createMarket(IMorpho-MarketParams)[]

    /* ---------------------------------------------------------------------- */
    /*                                 Supply                                 */
    /* ---------------------------------------------------------------------- */

    // tag::_supply(SupplyParams)[]
    /// @return assetsSupplied Actual assets transferred in.
    /// @return sharesMinted Supply shares minted to `onBehalf`.
    function _supply(SupplyParams memory p) internal returns (uint256 assetsSupplied, uint256 sharesMinted) {
        if (p.assets > 0) {
            IERC20(p.marketParams.loanToken).safeApprove(address(p.morpho), p.assets);
        }
        (assetsSupplied, sharesMinted) =
            p.morpho.supply(p.marketParams, p.assets, p.shares, p.onBehalf, p.data);
    }
    // end::_supply(SupplyParams)[]

    // tag::_supply(IMorpho-MarketParams-uint256-address)[]
    function _supply(IMorpho morpho, MarketParams memory marketParams, uint256 assets, address onBehalf)
        internal
        returns (uint256 assetsSupplied, uint256 sharesMinted)
    {
        return _supply(
            SupplyParams({
                morpho: morpho,
                marketParams: marketParams,
                assets: assets,
                shares: 0,
                onBehalf: onBehalf,
                data: ""
            })
        );
    }
    // end::_supply(IMorpho-MarketParams-uint256-address)[]

    /* ---------------------------------------------------------------------- */
    /*                                Withdraw                                */
    /* ---------------------------------------------------------------------- */

    // tag::_withdraw(WithdrawParams)[]
    function _withdraw(WithdrawParams memory p) internal returns (uint256 assetsWithdrawn, uint256 sharesBurned) {
        (assetsWithdrawn, sharesBurned) =
            p.morpho.withdraw(p.marketParams, p.assets, p.shares, p.onBehalf, p.receiver);
    }
    // end::_withdraw(WithdrawParams)[]

    // tag::_withdraw(IMorpho-MarketParams-uint256-address-address)[]
    function _withdraw(
        IMorpho morpho,
        MarketParams memory marketParams,
        uint256 assets,
        address onBehalf,
        address receiver
    ) internal returns (uint256 assetsWithdrawn, uint256 sharesBurned) {
        return _withdraw(
            WithdrawParams({
                morpho: morpho,
                marketParams: marketParams,
                assets: assets,
                shares: 0,
                onBehalf: onBehalf,
                receiver: receiver
            })
        );
    }
    // end::_withdraw(IMorpho-MarketParams-uint256-address-address)[]

    /* ---------------------------------------------------------------------- */
    /*                                 Borrow                                 */
    /* ---------------------------------------------------------------------- */

    // tag::_borrow(BorrowParams)[]
    function _borrow(BorrowParams memory p) internal returns (uint256 assetsBorrowed, uint256 sharesBorrowed) {
        (assetsBorrowed, sharesBorrowed) =
            p.morpho.borrow(p.marketParams, p.assets, p.shares, p.onBehalf, p.receiver);
    }
    // end::_borrow(BorrowParams)[]

    // tag::_borrow(IMorpho-MarketParams-uint256-address-address)[]
    function _borrow(
        IMorpho morpho,
        MarketParams memory marketParams,
        uint256 assets,
        address onBehalf,
        address receiver
    ) internal returns (uint256 assetsBorrowed, uint256 sharesBorrowed) {
        return _borrow(
            BorrowParams({
                morpho: morpho,
                marketParams: marketParams,
                assets: assets,
                shares: 0,
                onBehalf: onBehalf,
                receiver: receiver
            })
        );
    }
    // end::_borrow(IMorpho-MarketParams-uint256-address-address)[]

    /* ---------------------------------------------------------------------- */
    /*                                  Repay                                 */
    /* ---------------------------------------------------------------------- */

    // tag::_repay(RepayParams)[]
    function _repay(RepayParams memory p) internal returns (uint256 assetsRepaid, uint256 sharesRepaid) {
        if (p.assets > 0) {
            IERC20(p.marketParams.loanToken).safeApprove(address(p.morpho), p.assets);
        }
        (assetsRepaid, sharesRepaid) = p.morpho.repay(p.marketParams, p.assets, p.shares, p.onBehalf, p.data);
    }
    // end::_repay(RepayParams)[]

    // tag::_repay(IMorpho-MarketParams-uint256-address)[]
    function _repay(IMorpho morpho, MarketParams memory marketParams, uint256 assets, address onBehalf)
        internal
        returns (uint256 assetsRepaid, uint256 sharesRepaid)
    {
        return _repay(
            RepayParams({
                morpho: morpho,
                marketParams: marketParams,
                assets: assets,
                shares: 0,
                onBehalf: onBehalf,
                data: ""
            })
        );
    }
    // end::_repay(IMorpho-MarketParams-uint256-address)[]

    /* ---------------------------------------------------------------------- */
    /*                               Collateral                               */
    /* ---------------------------------------------------------------------- */

    // tag::_supplyCollateral(CollateralParams)[]
    function _supplyCollateral(CollateralParams memory p) internal {
        IERC20(p.marketParams.collateralToken).safeApprove(address(p.morpho), p.assets);
        p.morpho.supplyCollateral(p.marketParams, p.assets, p.onBehalf, p.data);
    }
    // end::_supplyCollateral(CollateralParams)[]

    // tag::_supplyCollateral(IMorpho-MarketParams-uint256-address)[]
    function _supplyCollateral(IMorpho morpho, MarketParams memory marketParams, uint256 assets, address onBehalf)
        internal
    {
        _supplyCollateral(
            CollateralParams({
                morpho: morpho, marketParams: marketParams, assets: assets, onBehalf: onBehalf, data: ""
            })
        );
    }
    // end::_supplyCollateral(IMorpho-MarketParams-uint256-address)[]

    // tag::_withdrawCollateral(WithdrawCollateralParams)[]
    function _withdrawCollateral(WithdrawCollateralParams memory p) internal {
        p.morpho.withdrawCollateral(p.marketParams, p.assets, p.onBehalf, p.receiver);
    }
    // end::_withdrawCollateral(WithdrawCollateralParams)[]

    // tag::_withdrawCollateral(IMorpho-MarketParams-uint256-address-address)[]
    function _withdrawCollateral(
        IMorpho morpho,
        MarketParams memory marketParams,
        uint256 assets,
        address onBehalf,
        address receiver
    ) internal {
        _withdrawCollateral(
            WithdrawCollateralParams({
                morpho: morpho,
                marketParams: marketParams,
                assets: assets,
                onBehalf: onBehalf,
                receiver: receiver
            })
        );
    }
    // end::_withdrawCollateral(IMorpho-MarketParams-uint256-address-address)[]

    /* ---------------------------------------------------------------------- */
    /*                               Liquidate                                */
    /* ---------------------------------------------------------------------- */

    // tag::_liquidate(LiquidateParams)[]
    function _liquidate(LiquidateParams memory p)
        internal
        returns (uint256 assetsSeized, uint256 assetsRepaid)
    {
        // Repay may pull loan tokens from liquidator when repaidShares > 0.
        IERC20(p.marketParams.loanToken).safeApprove(address(p.morpho), type(uint256).max);
        (assetsSeized, assetsRepaid) =
            p.morpho.liquidate(p.marketParams, p.borrower, p.seizedAssets, p.repaidShares, p.data);
        IERC20(p.marketParams.loanToken).safeApprove(address(p.morpho), 0);
    }
    // end::_liquidate(LiquidateParams)[]

    /* ---------------------------------------------------------------------- */
    /*                                 Views                                  */
    /* ---------------------------------------------------------------------- */

    // tag::_market(IMorpho-Id)[]
    function _market(IMorpho morpho, Id id) internal view returns (Market memory) {
        return morpho.market(id);
    }
    // end::_market(IMorpho-Id)[]

    // tag::_position(IMorpho-Id-address)[]
    function _position(IMorpho morpho, Id id, address user) internal view returns (Position memory) {
        return morpho.position(id, user);
    }
    // end::_position(IMorpho-Id-address)[]

    // tag::_expectedSupplyAssets(IMorpho-MarketParams-address)[]
    function _expectedSupplyAssets(IMorpho morpho, MarketParams memory marketParams, address user)
        internal
        view
        returns (uint256)
    {
        return morpho.expectedSupplyAssets(marketParams, user);
    }
    // end::_expectedSupplyAssets(IMorpho-MarketParams-address)[]

    // tag::_expectedBorrowAssets(IMorpho-MarketParams-address)[]
    function _expectedBorrowAssets(IMorpho morpho, MarketParams memory marketParams, address user)
        internal
        view
        returns (uint256)
    {
        return morpho.expectedBorrowAssets(marketParams, user);
    }
    // end::_expectedBorrowAssets(IMorpho-MarketParams-address)[]

    // tag::_accrueInterest(IMorpho-MarketParams)[]
    function _accrueInterest(IMorpho morpho, MarketParams memory marketParams) internal {
        morpho.accrueInterest(marketParams);
    }
    // end::_accrueInterest(IMorpho-MarketParams)[]
}
// end::MorphoBlueService[]
