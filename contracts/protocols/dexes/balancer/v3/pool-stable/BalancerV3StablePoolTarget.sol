// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {PoolSwapParams, Rounding, SwapKind} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import {StableMath} from "@balancer-labs/v3-solidity-utils/contracts/math/StableMath.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3StablePool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3StablePool.sol";
import {BalancerV3StablePoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-stable/BalancerV3StablePoolRepo.sol";

/**
 * @title Balancer V3 Stable Pool Target
 * @notice Implementation contract for Balancer V3 stable pool functionality.
 * @dev Stable pools use StableMath for swap and invariant calculations, optimized
 * for assets that trade near parity (e.g., stablecoins).
 *
 * The amplification parameter controls the curve flatness:
 * - Higher amp: Lower slippage when prices are near parity
 * - Lower amp: Better handling of price deviations
 *
 * Amplification state is stored in BalancerV3StablePoolRepo and must be initialized before use.
 */
contract BalancerV3StablePoolTarget is IBalancerV3Pool, IBalancerV3StablePool {
    using FixedPoint for uint256;

    /**
     * @notice Computes and returns the pool's invariant using stable math.
     * @dev Uses the current (possibly interpolated) amplification parameter.
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
        (uint256 currentAmp,) = BalancerV3StablePoolRepo._getAmplificationParameter();

        invariant = StableMath.computeInvariant(currentAmp, balancesLiveScaled18);

        // Apply rounding adjustment (invariant is always computed as if rounding down)
        if (invariant > 0 && rounding == Rounding.ROUND_UP) {
            invariant = invariant + 1;
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
        (uint256 currentAmp,) = BalancerV3StablePoolRepo._getAmplificationParameter();

        // Compute current invariant (round up for computing target balance)
        uint256 invariant = StableMath.computeInvariant(currentAmp, balancesLiveScaled18);
        if (invariant > 0) {
            invariant = invariant + 1; // Round up
        }

        // Compute new balance given the target invariant
        newBalance = StableMath.computeBalance(
            currentAmp,
            balancesLiveScaled18,
            invariant.mulUp(invariantRatio),
            tokenInIndex
        );
    }

    /**
     * @notice Execute a swap in the pool using stable math.
     * @dev Uses the current (possibly interpolated) amplification parameter.
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
        (uint256 currentAmp,) = BalancerV3StablePoolRepo._getAmplificationParameter();

        // Compute invariant for swap calculations (round down)
        uint256 invariant = StableMath.computeInvariant(currentAmp, params.balancesScaled18);

        if (params.kind == SwapKind.EXACT_IN) {
            amountCalculatedScaled18 = StableMath.computeOutGivenExactIn(
                currentAmp,
                params.balancesScaled18,
                params.indexIn,
                params.indexOut,
                params.amountGivenScaled18,
                invariant
            );
        } else {
            amountCalculatedScaled18 = StableMath.computeInGivenExactOut(
                currentAmp,
                params.balancesScaled18,
                params.indexIn,
                params.indexOut,
                params.amountGivenScaled18,
                invariant
            );
        }
    }

    /**
     * @notice Get the current amplification parameter.
     * @return value Current amplification value (includes precision).
     * @return isUpdating True if currently transitioning.
     * @return precision The precision multiplier (always 1000).
     */
    function getAmplificationParameter()
        public
        view
        virtual
        override(IBalancerV3StablePool)
        returns (uint256 value, bool isUpdating, uint256 precision)
    {
        (value, isUpdating) = BalancerV3StablePoolRepo._getAmplificationParameter();
        precision = StableMath.AMP_PRECISION;
    }

    /**
     * @notice Get the full amplification state including transition parameters.
     * @return startValue Starting amplification value for current/last transition.
     * @return endValue Ending amplification value for current/last transition.
     * @return startTime Start timestamp of the transition.
     * @return endTime End timestamp of the transition.
     * @return precision The precision multiplier (always 1000).
     */
    function getAmplificationState()
        public
        view
        virtual
        override(IBalancerV3StablePool)
        returns (
            uint256 startValue,
            uint256 endValue,
            uint256 startTime,
            uint256 endTime,
            uint256 precision
        )
    {
        (startValue, endValue, startTime, endTime) = BalancerV3StablePoolRepo._getAmplificationState();
        precision = StableMath.AMP_PRECISION;
    }
}
