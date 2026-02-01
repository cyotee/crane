// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IBasePoolFactory} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    LiquidityManagement,
    TokenConfig,
    PoolSwapParams,
    HookFlags
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import {BaseHooksTarget} from "./BaseHooksTarget.sol";

/* -------------------------------------------------------------------------- */
/*                        DirectionalFeeHookExample                           */
/* -------------------------------------------------------------------------- */

/**
 * @title DirectionalFeeHookExample
 * @notice Increases swap fees on trades that move pools away from equilibrium.
 * @dev This hook implements dynamic swap fees that penalize imbalancing trades.
 * Most applicable to stable pools with approximately linear math.
 *
 * Fee calculation:
 * - Swaps moving toward equilibrium: static fee
 * - Swaps moving away: fee = (balance difference) / (total liquidity)
 * - Higher fee is always charged
 *
 * Example: If tokenIn balance becomes 100 and tokenOut becomes 40:
 *   Fee = (100 - 40) / (100 + 40) = 60/140 ≈ 42.85%
 *
 * NOTE: This is a simplified example. Production hooks should:
 * - Establish a neutral range around equilibrium
 * - Implement smooth, symmetrical fee curves
 * - Consider token decimal differences
 *
 * @custom:security-contact security@example.com
 */
contract DirectionalFeeHookExample is BaseHooksTarget {
    using FixedPoint for uint256;

    /* ========================================================================== */
    /*                                   STORAGE                                  */
    /* ========================================================================== */

    /// @notice The only factory whose pools can use this hook.
    address private immutable _allowedStablePoolFactory;

    /* ========================================================================== */
    /*                                   EVENTS                                   */
    /* ========================================================================== */

    /**
     * @notice Emitted when this hook is successfully registered.
     * @param hooksContract This contract's address.
     * @param factory The factory that created the pool.
     * @param pool The pool address.
     */
    event DirectionalFeeHookExampleRegistered(
        address indexed hooksContract,
        address indexed factory,
        address indexed pool
    );

    /* ========================================================================== */
    /*                                 CONSTRUCTOR                                */
    /* ========================================================================== */

    /**
     * @notice Creates a new DirectionalFeeHookExample.
     * @param vault_ The Balancer V3 Vault address.
     * @param allowedStablePoolFactory_ The factory whose pools can register this hook.
     */
    constructor(
        IVault vault_,
        address allowedStablePoolFactory_
    ) BaseHooksTarget(vault_) {
        _allowedStablePoolFactory = allowedStablePoolFactory_;
    }

    /* ========================================================================== */
    /*                               HOOK CALLBACKS                               */
    /* ========================================================================== */

    /// @inheritdoc BaseHooksTarget
    function onRegister(
        address factory,
        address pool,
        TokenConfig[] memory,
        LiquidityManagement calldata
    ) public override onlyVault returns (bool) {
        emit DirectionalFeeHookExampleRegistered(address(this), factory, pool);

        // Only allow pools from the designated stable pool factory
        return factory == _allowedStablePoolFactory &&
            IBasePoolFactory(factory).isPoolFromFactory(pool);
    }

    /// @inheritdoc BaseHooksTarget
    function getHookFlags() public pure override returns (HookFlags memory hookFlags) {
        hookFlags.shouldCallComputeDynamicSwapFee = true;
    }

    /// @inheritdoc BaseHooksTarget
    function onComputeDynamicSwapFeePercentage(
        PoolSwapParams calldata params,
        address pool,
        uint256 staticSwapFeePercentage
    ) public view override onlyVault returns (bool, uint256) {
        // Get current pool balances
        (, , , uint256[] memory lastBalancesLiveScaled18) = _vault.getPoolTokenInfo(pool);

        uint256 calculatedSwapFeePercentage = _calculateDirectionalFeePercentage(
            lastBalancesLiveScaled18,
            params.amountGivenScaled18,
            params.indexIn,
            params.indexOut
        );

        // Charge the higher of static or calculated fee
        return (
            true,
            calculatedSwapFeePercentage > staticSwapFeePercentage
                ? calculatedSwapFeePercentage
                : staticSwapFeePercentage
        );
    }

    /* ========================================================================== */
    /*                              INTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Calculates the directional fee based on balance imbalance.
     * @dev Assumes linear pool math and 1:1 token rates (suitable for stable pools).
     *
     * Formula: fee = |balanceIn - balanceOut| / (balanceIn + balanceOut)
     *
     * Only charges if the swap increases imbalance (balanceIn > balanceOut after swap).
     *
     * @param poolBalances Current pool balances scaled to 18 decimals.
     * @param swapAmount The swap amount scaled to 18 decimals.
     * @param indexIn Index of the token being swapped in.
     * @param indexOut Index of the token being swapped out.
     * @return feePercentage The calculated fee percentage (0 if swap improves balance).
     */
    function _calculateDirectionalFeePercentage(
        uint256[] memory poolBalances,
        uint256 swapAmount,
        uint256 indexIn,
        uint256 indexOut
    ) private pure returns (uint256 feePercentage) {
        // Estimate final balances (assumes linear math, 1:1 swap)
        uint256 finalBalanceTokenIn = poolBalances[indexIn] + swapAmount;
        uint256 finalBalanceTokenOut = poolBalances[indexOut] - swapAmount;

        // Only charge if swap moves pool further from equilibrium
        if (finalBalanceTokenIn > finalBalanceTokenOut) {
            uint256 diff = finalBalanceTokenIn - finalBalanceTokenOut;
            uint256 totalLiquidity = finalBalanceTokenIn + finalBalanceTokenOut;

            // Fee approaches 100% as pool becomes extremely imbalanced
            feePercentage = diff.divDown(totalLiquidity);
        }
        // If finalBalanceTokenOut >= finalBalanceTokenIn, fee is 0 (swap improves balance)
    }
}
