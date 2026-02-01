// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {Arrays} from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/Arrays.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

/* -------------------------------------------------------------------------- */
/*                          StableSurgeMedianMath                             */
/* -------------------------------------------------------------------------- */

/**
 * @title StableSurgeMedianMath
 * @notice Math library for calculating pool imbalance using median-based metrics.
 * @dev Used by StableSurgeHook to determine when to apply surge pricing.
 *
 * The imbalance metric is calculated as:
 *   imbalance = sum(|balance[i] - median|) / sum(balance[i])
 *
 * This gives a normalized measure of how far pool balances deviate from
 * the median, scaled to [0, 1] where 0 means perfectly balanced.
 */
library StableSurgeMedianMath {
    using Arrays for uint256[];
    using FixedPoint for uint256;

    /**
     * @notice Calculates the total imbalance of pool balances relative to the median.
     * @dev Returns a value in [0, 1) representing the normalized deviation from median.
     * @param balances Array of token balances (scaled to 18 decimals).
     * @return imbalance The normalized imbalance metric.
     */
    function calculateImbalance(uint256[] memory balances) internal pure returns (uint256) {
        uint256 median = findMedian(balances);

        uint256 totalBalance = 0;
        uint256 totalDiff = 0;

        for (uint256 i = 0; i < balances.length; i++) {
            totalBalance += balances[i];
            totalDiff += absSub(balances[i], median);
        }

        return totalDiff.divDown(totalBalance);
    }

    /**
     * @notice Finds the median value of an array of balances.
     * @dev Creates a sorted copy to preserve the original array order.
     * @param balances Array of token balances.
     * @return median The median value.
     */
    function findMedian(uint256[] memory balances) internal pure returns (uint256) {
        uint256[] memory sortedBalances = balances.sort();
        uint256 mid = sortedBalances.length / 2;

        if (sortedBalances.length % 2 == 0) {
            return (sortedBalances[mid - 1] + sortedBalances[mid]) / 2;
        } else {
            return sortedBalances[mid];
        }
    }

    /**
     * @notice Returns the absolute difference between two values.
     * @param a First value.
     * @param b Second value.
     * @return diff The absolute difference |a - b|.
     */
    function absSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a > b ? a - b : b - a;
        }
    }
}
