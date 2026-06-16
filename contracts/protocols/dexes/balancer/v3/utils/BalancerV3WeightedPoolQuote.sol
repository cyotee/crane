// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";
import {WeightedMath} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/WeightedMath.sol";

library BalancerV3WeightedPoolQuote {
    using FixedPoint for uint256;

    function computeOutGivenExactInAfterFee(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountIn,
        uint256 swapFeePercentage
    ) internal pure returns (uint256 amountOut) {
        if (amountIn == 0) {
            return 0;
        }

        uint256 amountInAfterFee = amountIn.mulDown(FixedPoint.ONE - swapFeePercentage);
        if (amountInAfterFee == 0) {
            return 0;
        }

        amountOut = WeightedMath.computeOutGivenExactIn(balanceIn, weightIn, balanceOut, weightOut, amountInAfterFee);
    }

    function computeInGivenExactOutBeforeFee(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountOut,
        uint256 swapFeePercentage
    ) internal pure returns (uint256 amountIn) {
        if (amountOut == 0) {
            return 0;
        }

        uint256 amountInAfterFee =
            WeightedMath.computeInGivenExactOut(balanceIn, weightIn, balanceOut, weightOut, amountOut);
        amountIn = amountInAfterFee.divUp(FixedPoint.ONE - swapFeePercentage);
    }
}
