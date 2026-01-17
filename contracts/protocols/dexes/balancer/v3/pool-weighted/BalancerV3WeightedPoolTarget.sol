// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {PoolSwapParams, Rounding, SwapKind} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import {WeightedMath} from "@balancer-labs/v3-solidity-utils/contracts/math/WeightedMath.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3WeightedPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3WeightedPool.sol";
import {BalancerV3WeightedPoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolRepo.sol";

/**
 * @title Balancer V3 Weighted Pool Target
 * @notice Implementation contract for Balancer V3 weighted pool functionality (e.g., 80/20 pools).
 * @dev Swap and invariant calculations use WeightedMath from Balancer V3 libraries.
 * Weights are stored in BalancerV3WeightedPoolRepo and must be initialized before use.
 */
contract BalancerV3WeightedPoolTarget is IBalancerV3Pool, IBalancerV3WeightedPool {
    using FixedPoint for uint256;

    /**
     * @notice Computes and returns the pool's invariant using weighted math.
     * @dev Uses balancesLiveScaled18, which include IRateProvider rates, for consistency with swap calculations.
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
        uint256[] memory weights = BalancerV3WeightedPoolRepo._getNormalizedWeights();

        if (rounding == Rounding.ROUND_DOWN) {
            invariant = WeightedMath.computeInvariantDown(weights, balancesLiveScaled18);
        } else {
            invariant = WeightedMath.computeInvariantUp(weights, balancesLiveScaled18);
        }
    }

    /**
     * @notice Computes the new balance of a token after an operation.
     * @dev Uses rated balances for consistency with swaps and invariant calculations.
     * @param balancesLiveScaled18 Current live balances, adjusted for rates.
     * @param tokenInIndex Index of the token to compute the balance for.
     * @param invariantRatio Ratio of the new invariant to the old.
     * @return newBalance The new balance of the selected token, scaled to 18 decimals.
     */
    function computeBalance(uint256[] memory balancesLiveScaled18, uint256 tokenInIndex, uint256 invariantRatio)
        public
        view
        virtual
        override(IBalancerV3Pool)
        returns (uint256 newBalance)
    {
        uint256[] memory weights = BalancerV3WeightedPoolRepo._getNormalizedWeights();

        newBalance = WeightedMath.computeBalanceOutGivenInvariant(
            balancesLiveScaled18[tokenInIndex],
            weights[tokenInIndex],
            invariantRatio
        );
    }

    /**
     * @notice Execute a swap in the pool using weighted math.
     * @dev Uses balancesScaled18, which include IRateProvider rates if configured, to adjust swap calculations.
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
        uint256[] memory weights = BalancerV3WeightedPoolRepo._getNormalizedWeights();

        uint256 balanceIn = params.balancesScaled18[params.indexIn];
        uint256 balanceOut = params.balancesScaled18[params.indexOut];
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
    }

    /**
     * @notice Returns the normalized weights of the pool tokens.
     * @dev Weights are stored in BalancerV3WeightedPoolRepo.
     * @return weights Array of normalized weights (sum to 1e18).
     */
    function getNormalizedWeights() public view virtual override(IBalancerV3WeightedPool) returns (uint256[] memory weights) {
        return BalancerV3WeightedPoolRepo._getNormalizedWeights();
    }
}
