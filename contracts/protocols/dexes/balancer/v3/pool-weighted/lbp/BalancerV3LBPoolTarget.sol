// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {PoolSwapParams, Rounding, SwapKind} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";
import {WeightedMath} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/WeightedMath.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3LBPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3LBPool.sol";
import {BalancerV3LBPoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/lbp/BalancerV3LBPoolRepo.sol";
import {GradualValueChange} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/lbp/GradualValueChange.sol";

/**
 * @title Balancer V3 LBPool Target
 * @notice Implementation contract for Balancer V3 Liquidity Bootstrapping Pool functionality.
 * @dev LBPs have time-based weight transitions for token launches.
 *
 * Key features:
 * - Gradual weight changes between start and end weights over the sale period
 * - Optional blocking of project token sell-backs (buy-only mode)
 * - Optional virtual reserve balance for "seedless" LBPs
 * - Swaps only enabled during the sale period
 */
contract BalancerV3LBPoolTarget is IBalancerV3Pool, IBalancerV3LBPool {
    using FixedPoint for uint256;

    /// @notice Swaps are disabled except during the sale (i.e., between start and end times).
    error SwapsDisabled();

    /// @notice The LBP configuration prohibits selling the project token back into the pool.
    error SwapOfProjectTokenIn();

    /// @notice Insufficient real reserve balance to fulfill the swap.
    error InsufficientRealReserveBalance(uint256 requested, uint256 available);

    /**
     * @notice Computes and returns the pool's invariant using weighted math.
     * @dev Uses current interpolated weights based on time progress.
     * For seedless LBPs, adds virtual balance to reserve token.
     * @param balancesLiveScaled18 Token balances after applying decimal scaling and rates.
     * @param rounding Rounding direction for the invariant calculation.
     * @return invariant The calculated invariant, scaled to 18 decimals.
     */
    function computeInvariant(uint256[] memory balancesLiveScaled18, Rounding rounding)
        public
        view
        virtual
        override(IBalancerV3Pool)
        returns (uint256 invariant)
    {
        uint256[] memory weights = _getNormalizedWeights();
        uint256 virtualBalance = BalancerV3LBPoolRepo._getReserveTokenVirtualBalanceScaled18();

        if (virtualBalance > 0) {
            // Seedless LBP: add virtual balance to reserve token
            uint256 reserveIndex = BalancerV3LBPoolRepo._getReserveTokenIndex();
            uint256 originalReserveBalance = balancesLiveScaled18[reserveIndex];
            balancesLiveScaled18[reserveIndex] += virtualBalance;

            if (rounding == Rounding.ROUND_DOWN) {
                invariant = WeightedMath.computeInvariantDown(weights, balancesLiveScaled18);
            } else {
                invariant = WeightedMath.computeInvariantUp(weights, balancesLiveScaled18);
            }

            // Restore original balance
            balancesLiveScaled18[reserveIndex] = originalReserveBalance;
        } else {
            if (rounding == Rounding.ROUND_DOWN) {
                invariant = WeightedMath.computeInvariantDown(weights, balancesLiveScaled18);
            } else {
                invariant = WeightedMath.computeInvariantUp(weights, balancesLiveScaled18);
            }
        }
    }

    /**
     * @notice Computes the new balance of a token after an operation.
     * @dev LBPs do not support single-token liquidity operations.
     */
    function computeBalance(uint256[] memory, uint256, uint256)
        public
        pure
        virtual
        override(IBalancerV3Pool)
        returns (uint256)
    {
        // LBPs do not support single-token liquidity operations
        revert("LBP: unsupported operation");
    }

    /**
     * @notice Execute a swap in the pool using weighted math with current weights.
     * @dev Enforces:
     *   - Swaps only during sale period
     *   - Optional blocking of project token swaps in
     *   - Virtual balance adjustment for seedless LBPs
     * @param params Swap parameters, including balancesScaled18 adjusted by rates.
     * @return amountCalculatedScaled18 Calculated amount for the swap in scaled 18-decimal format.
     */
    function onSwap(PoolSwapParams calldata params)
        public
        view
        virtual
        override(IBalancerV3Pool)
        returns (uint256 amountCalculatedScaled18)
    {
        // Block if the sale has not started or has ended
        if (!BalancerV3LBPoolRepo._isSwapEnabled()) {
            revert SwapsDisabled();
        }

        uint256 projectTokenIndex = BalancerV3LBPoolRepo._getProjectTokenIndex();

        // If project token swaps are blocked, project token must be the token out
        if (BalancerV3LBPoolRepo._isBlockProjectTokenSwapsIn() && params.indexOut != projectTokenIndex) {
            revert SwapOfProjectTokenIn();
        }

        uint256[] memory weights = _getNormalizedWeights();
        uint256 virtualBalance = BalancerV3LBPoolRepo._getReserveTokenVirtualBalanceScaled18();
        uint256 reserveTokenIndex = BalancerV3LBPoolRepo._getReserveTokenIndex();

        uint256 balanceIn = params.balancesScaled18[params.indexIn];
        uint256 balanceOut = params.balancesScaled18[params.indexOut];

        // Add virtual balance for seedless LBPs
        if (virtualBalance > 0) {
            if (params.indexIn == reserveTokenIndex) {
                balanceIn += virtualBalance;
            }
            if (params.indexOut == reserveTokenIndex) {
                balanceOut += virtualBalance;
            }
        }

        uint256 weightIn = weights[params.indexIn];
        uint256 weightOut = weights[params.indexOut];

        if (params.kind == SwapKind.EXACT_IN) {
            amountCalculatedScaled18 = WeightedMath.computeOutGivenExactIn(
                balanceIn,
                weightIn,
                balanceOut,
                weightOut,
                params.amountGivenScaled18
            );
        } else {
            amountCalculatedScaled18 = WeightedMath.computeInGivenExactOut(
                balanceIn,
                weightIn,
                balanceOut,
                weightOut,
                params.amountGivenScaled18
            );
        }

        // For seedless LBPs, ensure we have enough real balance if returning reserve tokens
        if (virtualBalance > 0 && params.indexOut == reserveTokenIndex) {
            uint256 realReserveBalance = params.balancesScaled18[reserveTokenIndex];
            if (amountCalculatedScaled18 > realReserveBalance) {
                revert InsufficientRealReserveBalance(amountCalculatedScaled18, realReserveBalance);
            }
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                          IBalancerV3LBPool                              */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Returns the current normalized weights based on time progress.
     * @dev Weights are interpolated between start and end weights based on
     * how much time has elapsed since the sale start.
     * @return weights Array of current normalized weights (sum to 1e18).
     */
    function getNormalizedWeights() public view virtual override(IBalancerV3LBPool) returns (uint256[] memory weights) {
        return _getNormalizedWeights();
    }

    /**
     * @notice Returns the gradual weight update parameters.
     * @return startTime Sale start timestamp.
     * @return endTime Sale end timestamp.
     * @return startWeights Array of starting weights.
     * @return endWeights Array of ending weights.
     */
    function getGradualWeightUpdateParams()
        public
        view
        virtual
        override(IBalancerV3LBPool)
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256[] memory startWeights,
            uint256[] memory endWeights
        )
    {
        return BalancerV3LBPoolRepo._getGradualWeightUpdateParams();
    }

    /**
     * @notice Returns whether swaps are currently enabled.
     * @return True if within the sale period (startTime <= now <= endTime).
     */
    function isSwapEnabled() public view virtual override(IBalancerV3LBPool) returns (bool) {
        return BalancerV3LBPoolRepo._isSwapEnabled();
    }

    /**
     * @notice Returns the token indices.
     * @return projectTokenIndex Index of the project token.
     * @return reserveTokenIndex Index of the reserve token.
     */
    function getTokenIndices()
        public
        view
        virtual
        override(IBalancerV3LBPool)
        returns (uint256 projectTokenIndex, uint256 reserveTokenIndex)
    {
        projectTokenIndex = BalancerV3LBPoolRepo._getProjectTokenIndex();
        reserveTokenIndex = BalancerV3LBPoolRepo._getReserveTokenIndex();
    }

    /**
     * @notice Returns whether project token swaps in are blocked.
     * @return True if project token can only be bought, not sold back.
     */
    function isProjectTokenSwapInBlocked() public view virtual override(IBalancerV3LBPool) returns (bool) {
        return BalancerV3LBPoolRepo._isBlockProjectTokenSwapsIn();
    }

    /* ---------------------------------------------------------------------- */
    /*                           Internal Functions                            */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Returns current normalized weights based on time interpolation.
     */
    function _getNormalizedWeights() internal view virtual returns (uint256[] memory weights) {
        uint256 startTime = BalancerV3LBPoolRepo._getStartTime();
        uint256 endTime = BalancerV3LBPoolRepo._getEndTime();
        uint256 projectTokenIndex = BalancerV3LBPoolRepo._getProjectTokenIndex();
        uint256 reserveTokenIndex = BalancerV3LBPoolRepo._getReserveTokenIndex();

        // Calculate current project token weight
        uint256 projectTokenWeight = GradualValueChange.getInterpolatedValue(
            BalancerV3LBPoolRepo._getProjectTokenStartWeight(),
            BalancerV3LBPoolRepo._getProjectTokenEndWeight(),
            startTime,
            endTime
        );

        // Reserve token weight is the complement
        uint256 reserveTokenWeight = FixedPoint.ONE - projectTokenWeight;

        weights = new uint256[](2);
        weights[projectTokenIndex] = projectTokenWeight;
        weights[reserveTokenIndex] = reserveTokenWeight;
    }
}
