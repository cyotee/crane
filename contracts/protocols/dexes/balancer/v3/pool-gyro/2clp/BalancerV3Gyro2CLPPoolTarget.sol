// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {PoolSwapParams, Rounding, SwapKind} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";

import {Gyro2CLPMath} from "@crane/contracts/external/balancer/v3/pool-gyro/contracts/lib/Gyro2CLPMath.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IBalancerV3Gyro2CLPPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/gyro/IBalancerV3Gyro2CLPPool.sol";
import {BalancerV3Gyro2CLPPoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/2clp/BalancerV3Gyro2CLPPoolRepo.sol";

/**
 * @title Balancer V3 Gyro 2-CLP Pool Target
 * @notice Implementation contract for Balancer V3 Gyro 2-CLP pool functionality.
 * @dev 2-CLP pools use concentrated liquidity with a simple invariant:
 * L^2 = (x + a)(y + b) where:
 * - a = L / sqrtBeta
 * - b = L * sqrtAlpha
 *
 * Pool parameters are stored in BalancerV3Gyro2CLPPoolRepo and must be initialized before use.
 */
contract BalancerV3Gyro2CLPPoolTarget is IBalancerV3Pool, IBalancerV3Gyro2CLPPool {
    using FixedPoint for uint256;

    /* -------------------------------------------------------------------------- */
    /*                               Invariant                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Computes and returns the pool's invariant using 2-CLP math.
     * @dev Uses the stored sqrtAlpha and sqrtBeta parameters.
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
        (uint256 sqrtAlpha, uint256 sqrtBeta) = BalancerV3Gyro2CLPPoolRepo._get2CLPParams();

        invariant = Gyro2CLPMath.calculateInvariant(balancesLiveScaled18, sqrtAlpha, sqrtBeta, rounding);
    }

    /**
     * @notice Computes the new balance of a token after an operation.
     * @dev Uses 2-CLP math to solve for the new balance given an invariant ratio change.
     *
     * The 2-CLP invariant formula is: L^2 = (x + a)(y + b)
     * where a = L/sqrtBeta and b = L*sqrtAlpha
     *
     * To find newX: newX = (squareNewInv/(y + b)) - a
     * To find newY: newY = (squareNewInv/(x + a)) - b
     *
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
        (uint256 sqrtAlpha, uint256 sqrtBeta) = BalancerV3Gyro2CLPPoolRepo._get2CLPParams();

        // computeBalance is used to calculate unbalanced adds and removes.
        // A bigger invariant means more tokens are required (add) or less tokens out (remove).
        // So, the invariant should always be rounded up.
        uint256 invariant =
            Gyro2CLPMath.calculateInvariant(balancesLiveScaled18, sqrtAlpha, sqrtBeta, Rounding.ROUND_UP);

        // New invariant
        invariant = invariant.mulUp(invariantRatio);
        uint256 squareNewInv = invariant * invariant;

        // L / sqrt(beta), rounded down to maximize newBalance.
        uint256 a = invariant.divDown(sqrtBeta);
        // L * sqrt(alpha), rounded down to maximize newBalance (b is in the denominator).
        uint256 b = invariant.mulDown(sqrtAlpha);

        if (tokenInIndex == 0) {
            // if newBalance = newX
            newBalance = squareNewInv.divUpRaw(b + balancesLiveScaled18[1]) - a;
        } else {
            // if newBalance = newY
            newBalance = squareNewInv.divUpRaw(a + balancesLiveScaled18[0]) - b;
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Swaps                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Execute a swap in the pool using 2-CLP math.
     * @dev Uses the stored sqrtAlpha and sqrtBeta parameters for swap calculations.
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
        bool tokenInIsToken0 = params.indexIn == 0;
        uint256 balanceTokenInScaled18 = params.balancesScaled18[params.indexIn];
        uint256 balanceTokenOutScaled18 = params.balancesScaled18[params.indexOut];

        // Calculate virtual offsets
        (uint256 virtualParamIn, uint256 virtualParamOut) =
            _getVirtualOffsets(balanceTokenInScaled18, balanceTokenOutScaled18, tokenInIsToken0);

        if (params.kind == SwapKind.EXACT_IN) {
            amountCalculatedScaled18 = Gyro2CLPMath.calcOutGivenIn(
                balanceTokenInScaled18,
                balanceTokenOutScaled18,
                params.amountGivenScaled18,
                virtualParamIn,
                virtualParamOut
            );
        } else {
            amountCalculatedScaled18 = Gyro2CLPMath.calcInGivenOut(
                balanceTokenInScaled18,
                balanceTokenOutScaled18,
                params.amountGivenScaled18,
                virtualParamIn,
                virtualParamOut
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                              Virtual Offsets                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Calculate the virtual offsets for swap calculations.
     * @dev The 2-CLP invariant is L=(x+a)(y+b). "x" and "y" are real balances,
     * "a" and "b" are offsets to concentrate liquidity.
     * @param balanceTokenInScaled18 Balance of the input token.
     * @param balanceTokenOutScaled18 Balance of the output token.
     * @param tokenInIsToken0 Whether the input token is token 0.
     * @return virtualBalanceIn Virtual offset for input token.
     * @return virtualBalanceOut Virtual offset for output token.
     */
    function _getVirtualOffsets(
        uint256 balanceTokenInScaled18,
        uint256 balanceTokenOutScaled18,
        bool tokenInIsToken0
    ) internal view returns (uint256 virtualBalanceIn, uint256 virtualBalanceOut) {
        uint256[] memory balances = new uint256[](2);
        balances[0] = tokenInIsToken0 ? balanceTokenInScaled18 : balanceTokenOutScaled18;
        balances[1] = tokenInIsToken0 ? balanceTokenOutScaled18 : balanceTokenInScaled18;

        (uint256 sqrtAlpha, uint256 sqrtBeta) = BalancerV3Gyro2CLPPoolRepo._get2CLPParams();

        uint256 currentInvariant =
            Gyro2CLPMath.calculateInvariant(balances, sqrtAlpha, sqrtBeta, Rounding.ROUND_DOWN);

        // virtualBalanceIn is always rounded up (conservative for protocol)
        // virtualBalanceOut is always rounded down (conservative for protocol)
        if (tokenInIsToken0) {
            virtualBalanceIn = Gyro2CLPMath.calculateVirtualParameter0(currentInvariant, sqrtBeta, Rounding.ROUND_UP);
            virtualBalanceOut =
                Gyro2CLPMath.calculateVirtualParameter1(currentInvariant, sqrtAlpha, Rounding.ROUND_DOWN);
        } else {
            virtualBalanceIn = Gyro2CLPMath.calculateVirtualParameter1(currentInvariant, sqrtAlpha, Rounding.ROUND_UP);
            virtualBalanceOut =
                Gyro2CLPMath.calculateVirtualParameter0(currentInvariant, sqrtBeta, Rounding.ROUND_DOWN);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                              2-CLP Parameters                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get the 2-CLP parameters.
     * @return sqrtAlpha Square root of alpha (lower price bound).
     * @return sqrtBeta Square root of beta (upper price bound).
     */
    function get2CLPParams()
        public
        view
        virtual
        override(IBalancerV3Gyro2CLPPool)
        returns (uint256 sqrtAlpha, uint256 sqrtBeta)
    {
        return BalancerV3Gyro2CLPPoolRepo._get2CLPParams();
    }

    /* -------------------------------------------------------------------------- */
    /*                              Pool Bounds                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get the minimum swap fee percentage allowed.
     * @dev Liquidity Approximation tests show that add/remove liquidity combinations
     * are more profitable than a swap if the swap fee percentage is 0%.
     * @return The minimum swap fee percentage (1e12 = 0.0001%).
     */
    function getMinimumSwapFeePercentage() public pure virtual override(IBalancerV3Gyro2CLPPool) returns (uint256) {
        return 1e12; // 0.0001%
    }

    /**
     * @notice Get the maximum swap fee percentage allowed.
     * @return The maximum swap fee percentage (1e18 = 100%).
     */
    function getMaximumSwapFeePercentage() public pure virtual override(IBalancerV3Gyro2CLPPool) returns (uint256) {
        return 1e18; // 100%
    }

    /**
     * @notice Get the minimum invariant ratio for unbalanced liquidity operations.
     * @return The minimum invariant ratio (0 for 2-CLP - no limit).
     */
    function getMinimumInvariantRatio() public pure virtual override(IBalancerV3Gyro2CLPPool) returns (uint256) {
        return 0;
    }

    /**
     * @notice Get the maximum invariant ratio for unbalanced liquidity operations.
     * @return The maximum invariant ratio (type(uint256).max for 2-CLP - no limit).
     */
    function getMaximumInvariantRatio() public pure virtual override(IBalancerV3Gyro2CLPPool) returns (uint256) {
        return type(uint256).max;
    }
}
