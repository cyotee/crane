// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

// import { IBasePool } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import {PoolSwapParams, Rounding, SwapKind} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

/* -------------------------------------------------------------------------- */
/*                                  OpenZeppelin                              */
/* -------------------------------------------------------------------------- */

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import {Create3AwareContract} from "@crane/contracts/crane/factories/create2/aware/Create3AwareContract.sol";
// import {BalancerV3PoolFacet} from "@crane/contracts/crane/protocols/dexes/balancer/v3/vault/BalancerV3PoolFacet.sol";

import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

/* -------------------------------------------------------------------------- */
/*                                  Indexedex                                 */
/* -------------------------------------------------------------------------- */

/**
 * @title Balancer V3 Pool Facet
 * @notice A facet implementing Balancer V3 pool functionality with constant product AMM (x * y = k).
 * @dev Swap calculations use balancesScaled18, which include IRateProvider rates if configured.
 * Based on the original ConstantProductPool implementation.
 */
contract BalancerV3ConstantProductPoolTarget is IBalancerV3Pool {
    using FixedPoint for uint256;

    /**
     * @notice Computes and returns the pool's invariant.
     * @dev Uses balancesLiveScaled18, which include IRateProvider rates, for consistency with swap calculations.
     * @param balancesLiveScaled18 Token balances after applying decimal scaling and rates.
     * @param rounding Rounding direction for the invariant calculation.
     * @return invariant The calculated invariant, scaled to 18 decimals.
     */
    function computeInvariant(uint256[] memory balancesLiveScaled18, Rounding rounding)
        public
        pure
        virtual
        override
        returns (uint256 invariant)
    {
        // Expects exactly 2 tokens
        invariant = FixedPoint.ONE;
        for (uint256 i = 0; i < balancesLiveScaled18.length; ++i) {
            invariant = rounding == Rounding.ROUND_DOWN
                ? invariant.mulDown(balancesLiveScaled18[i])
                : invariant.mulUp(balancesLiveScaled18[i]);
        }
        // Scale the invariant to 1e18
        invariant = Math.sqrt(invariant) * 1e9;
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
        pure
        virtual
        override
        returns (uint256 newBalance)
    {
        uint256 otherTokenIndex = tokenInIndex == 0 ? 1 : 0;
        uint256 newInvariant = computeInvariant(balancesLiveScaled18, Rounding.ROUND_DOWN).mulDown(invariantRatio);
        newBalance = ((newInvariant * newInvariant) / balancesLiveScaled18[otherTokenIndex]);
    }

    /**
     * @notice Execute a swap in the pool.
     * @dev Uses balancesScaled18, which include IRateProvider rates if configured, to adjust swap calculations.
     * For AMM math, see https://www.youtube.com/watch?v=QNPyFs8Wybk
     * @param params Swap parameters, including balancesScaled18 adjusted by rates.
     * @return amountCalculatedScaled18 Calculated amount for the swap in scaled 18-decimal format.
     */
    function onSwap(PoolSwapParams calldata params)
        public
        pure
        virtual
        override
        returns (uint256 amountCalculatedScaled18)
    {
        uint256 poolBalanceTokenIn = params.balancesScaled18[params.indexIn]; // X, adjusted by rate if IRateProvider set
        uint256 poolBalanceTokenOut = params.balancesScaled18[params.indexOut]; // Y, adjusted by rate if IRateProvider set

        if (params.kind == SwapKind.EXACT_IN) {
            uint256 amountTokenIn = params.amountGivenScaled18; // dx
            // dy = (Y * dx) / (X + dx)
            amountCalculatedScaled18 = (poolBalanceTokenOut * amountTokenIn) / (poolBalanceTokenIn + amountTokenIn);
        } else {
            uint256 amountTokenOut = params.amountGivenScaled18; // dy
            // dx = (X * dy) / (Y - dy)
            amountCalculatedScaled18 = (poolBalanceTokenIn * amountTokenOut) / (poolBalanceTokenOut - amountTokenOut);
        }
    }
}
