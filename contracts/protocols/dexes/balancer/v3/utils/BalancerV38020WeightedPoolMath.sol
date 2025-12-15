// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import {WeightedMath} from "@balancer-labs/v3-solidity-utils/contracts/math/WeightedMath.sol";

import {betterconsole as console} from "@crane/contracts/utils/vm/foundry/tools/betterconsole.sol";
import {BetterMath} from "@crane/contracts/utils/math/BetterMath.sol";

library BalancerV38020WeightedPoolMath {
    using FixedPoint for uint256;
    // Minimum total supply amount.
    uint256 internal constant _POOL_MINIMUM_TOTAL_SUPPLY = 1e6;

    /**
     * @dev Calculate equivalent proportional amounts given amount of one token (for 80/20 pool).
     * Assumes the given amount is for tokenIndex; computes the other token amount to make it proportional.
     * Also computes the resulting BPT out if deposited proportionally (no fees, using UNBALANCED if proportional).
     * @param balances Current pool balances [token0, token1] (scaled).
     * @param normalizedWeights Normalized weights [0.8e18, 0.2e18].
     * @param tokenIndex Index of the given token (0 or 1).
     * @param amountIn Amount of the given token.
     * @return otherAmount Amount of the other token needed for proportionality (rounded up).
     */
    function _calcEquivalentProportionalGivenSingle(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 totalSupply,
        uint256 tokenIndex,
        uint256 amountIn
    ) internal pure returns (uint256 otherAmount) {
        require(balances.length == 2 && normalizedWeights.length == 2, "80/20 pool only");
        require(normalizedWeights[0] + normalizedWeights[1] == FixedPoint.ONE, "weights sum != 1e18");

        if (amountIn == 0) return 0;

        uint256 otherIndex = 1 - tokenIndex;

        if (totalSupply == 0) {
            // ─── EMPTY POOL: force initial ratio to match the configured weights ───
            // (this sets clean 80/20 starting prices with no arbitrage opportunity)
            otherAmount = amountIn.mulUp(
                normalizedWeights[otherIndex].divDown(normalizedWeights[tokenIndex])
            );
        } else {
            // ─── NORMAL CASE: keep current balance ratio exactly the same (zero price impact) ───
            // Using divUp here is more pool-favourable than the original divDown
            otherAmount = amountIn.mulUp(
                balances[otherIndex].divUp(balances[tokenIndex])
            );
        }
    }

    /**
     * @dev Calculate equivalent proportional amounts given amount of one token (for 80/20 pool).
     * Assumes the given amount is for tokenIndex; computes the other token amount to make it proportional.
     * Also computes the resulting BPT out if deposited proportionally (no fees, using UNBALANCED if proportional).
     * @param balances Current pool balances [token0, token1] (scaled).
     * @param normalizedWeights Normalized weights [0.8e18, 0.2e18].
     * @param totalSupply Current total BPT supply.
     * @param tokenIndex Index of the given token (0 or 1).
     * @param amountIn Amount of the given token.
     * @return otherAmount Amount of the other token needed for proportionality (rounded up).
     * @return bptOut BPT minted if deposited proportionally (rounded down).
     */
    function _calcEquivalentProportionalGivenSingleAndBPTOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 totalSupply,
        uint256 tokenIndex,
        uint256 amountIn
    ) internal pure returns (uint256 otherAmount, uint256 bptOut) {
        console.log("Entering calcEquivalentProportionalGivenSingle with bptOut calculation");
        // require(balances.length == 2 && normalizedWeights.length == 2, "80/20 pool only");
        // if (amountIn == 0) return (0, 0);

        // uint256 otherIndex = 1 - tokenIndex;
        // // Round up for otherAmount to favor protocol (user pays more)
        // otherAmount = amountIn.mulUp(balances[otherIndex].divUp(balances[tokenIndex]));

        // // BPT out using ratio from the given token (round down)
        // uint256 ratio = amountIn.divDown(balances[tokenIndex]);
        // bptOut = totalSupply.mulDown(ratio);
        require(balances.length == 2 && normalizedWeights.length == 2, "80/20 only");
        console.log("normalizedWeights[0] = ", normalizedWeights[0]);
        console.log("normalizedWeights[1] = ", normalizedWeights[1]);
        require(normalizedWeights[0] + normalizedWeights[1] == FixedPoint.ONE, "weights must sum to 1e18");
        if (amountIn == 0) return (0, 0);

        uint256 otherIndex = 1 - tokenIndex;
        console.log("Checking toal supply");
        if (totalSupply == 0) {
            console.log("Total supply is zero");
            // ───── INITIAL DEPOSIT (pool empty) ─────
            // Proportional = deposit in weight ratio so post-deposit normalized balances are proportional to weights
            // (this sets clean initial prices with no arb).
            console.log("Calculating other amount based on weights");
            console.log("normalizedWeights[otherIndex] = ", normalizedWeights[otherIndex]);
            console.log("normalizedWeights[tokenIndex] = ", normalizedWeights[tokenIndex]);
            otherAmount = amountIn.mulUp(
                normalizedWeights[otherIndex].divDown(normalizedWeights[tokenIndex])
            );
            console.log("otherAmount = ", otherAmount);

            uint256[] memory postDepositBalances = new uint256[](2);
            postDepositBalances[tokenIndex] = amountIn;
            postDepositBalances[otherIndex] = otherAmount;
            console.log("postDepositBalances[tokenIndex] = ", postDepositBalances[tokenIndex]);
            console.log("postDepositBalances[otherIndex] = ", postDepositBalances[otherIndex]);
            bptOut = WeightedMath.computeInvariantDown(normalizedWeights, postDepositBalances);
            console.log("Initial BPT out (before min supply adjustment) = ", bptOut);
            bptOut -= _POOL_MINIMUM_TOTAL_SUPPLY;
            console.log("BPT out (after min supply adjustment) = ", bptOut);

            // No minimum liquidity is subtracted from the first LP in standard WeightedPool.
            // (If you ever encounter a custom/hook pool that does it, subtract here.)
            // uint256 constant _POOL_MINIMUM_TOTAL_SUPPLY = 1e6;
            // bptOut = bptOut > _POOL_MINIMUM_TOTAL_SUPPLY ? bptOut - _POOL_MINIMUM_TOTAL_SUPPLY : 0;
        } else {
            // ───── NORMAL (already initialized) ─────
            // Proportional = keep current balance ratio
            otherAmount = amountIn.mulUp(balances[otherIndex].divUp(balances[tokenIndex]));

            // BPT minted = totalSupply * (amountIn / balances[tokenIndex]) rounded down
            uint256 ratio = amountIn.divDown(balances[tokenIndex]);
            bptOut = totalSupply.mulDown(ratio);
        }
        console.log("Exiting calcEquivalentProportionalGivenSingle with bptOut =", bptOut);
    }

    /**
     * @dev Calculate BPT out for an unbalanced deposit (exact amounts in, possibly multiple tokens).
     * @param balances Current pool balances (live scaled to 18 decimals).
     * @param normalizedWeights Normalized weights array (e.g., [0.8e18, 0.2e18]).
     * @param amountsIn Exact amounts of tokens to deposit (scaled; can be non-zero for multiple).
     * @param totalSupply Current total BPT supply.
     * @param swapFeePercentage Pool swap fee (e.g., 0.01e18 for 1%).
     * @return bptOut BPT minted (rounded down to favor protocol).
     */
    function _calcBptOutGivenUnbalancedIn(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsIn,
        uint256 totalSupply,
        uint256 swapFeePercentage
    ) internal pure returns (uint256) {
        require(balances.length == 2 && normalizedWeights.length == 2 && amountsIn.length == 2, "80/20 pool only");
        if (totalSupply == 0) return 0;

        // Check if all amountsIn are zero
        bool allZero = true;
        for (uint256 i = 0; i < 2; ++i) {
            if (amountsIn[i] > 0) {
                allZero = false;
                // Check max in ratio per token
                require(amountsIn[i] <= balances[i].mulDown(WeightedMath._MAX_IN_RATIO), "Exceeds max in ratio");
            }
        }
        if (allZero) return 0;

        // Compute new balances with full amountsIn
        uint256[] memory newBalances = new uint256[](2);
        for (uint256 i = 0; i < 2; ++i) {
            newBalances[i] = balances[i] + amountsIn[i];
        }

        // Compute invariants
        uint256 currentInvariant = WeightedMath.computeInvariantUp(normalizedWeights, balances);
        uint256 newInvariant = WeightedMath.computeInvariantDown(normalizedWeights, newBalances);

        // Compute invariant ratio
        uint256 invariantRatio = newInvariant.divDown(currentInvariant);
        if (invariantRatio <= FixedPoint.ONE) return 0;
        require(invariantRatio <= WeightedMath._MAX_INVARIANT_RATIO, "Exceeds max invariant ratio");

        // Compute proportional balances, taxable amounts, and fees for each token
        for (uint256 i = 0; i < 2; ++i) {
            uint256 proportionalBalance = balances[i].mulDown(invariantRatio);
            uint256 taxableAmount = newBalances[i] > proportionalBalance ? newBalances[i] - proportionalBalance : 0;
            uint256 swapFee = taxableAmount.mulUp(swapFeePercentage);
            // Adjust new balance for fee
            newBalances[i] -= swapFee;
        }

        // Compute new invariant with fees applied
        uint256 invariantWithFeesApplied = WeightedMath.computeInvariantDown(normalizedWeights, newBalances);

        // Compute BPT out = totalSupply * (invariantWithFeesApplied - currentInvariant) / currentInvariant, floored
        return (totalSupply * (invariantWithFeesApplied - currentInvariant)) / currentInvariant;
    }

    error ZeroInvariant();

    /**
     * @dev Calculate BPT out for a proportional deposit into an 80/20 weighted pool.
     * @param balances Current pool balances [token0, token1] (live scaled to 18 decimals).
     * @param totalSupply Current total BPT supply.
     * @param amountsIn Proportional amounts of tokens to deposit (scaled).
     * @return bptOut BPT minted (rounded down to favor protocol).
     */
    function _calcBptOutGivenProportionalIn(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 totalSupply, 
        uint256[] memory amountsIn
    )
        internal
        pure
        returns (uint256 bptOut)
    {
        require(balances.length == 2 && amountsIn.length == 2 && normalizedWeights.length == 2, "80/20 pool only");
        require(normalizedWeights[0] + normalizedWeights[1] == FixedPoint.ONE, "weights must sum to 1e18");

        if (amountsIn[0] == 0 && amountsIn[1] == 0) return 0;

        uint256 DELTA = 1e9; // same absolute tolerance as your original code

        if (totalSupply == 0) {
            // ───── INITIAL DEPOSIT (totalSupply == 0) ─────
            // Proportional = normalized amounts must be in weight ratio
            // i.e. amountsIn[i] / normalizedWeights[i] must be ~ equal (the "pool size" factor)
            uint256 sizeFactor0 = amountsIn[0].divDown(normalizedWeights[0]);
            uint256 sizeFactor1 = amountsIn[1].divDown(normalizedWeights[1]);

            require(
                sizeFactor0 >= sizeFactor1
                    ? sizeFactor0 - sizeFactor1 <= DELTA
                    : sizeFactor1 - sizeFactor0 <= DELTA,
                "Non-proportional amounts (initial)"
            );

            // Compute invariant from the post-deposit normalized balances (= amountsIn)
            uint256[] memory postBalances = new uint256[](2);
            postBalances[0] = amountsIn[0];
            postBalances[1] = amountsIn[1];

            uint256 invariant = WeightedMath.computeInvariantDown(normalizedWeights, postBalances);

            // Vault mints a tiny minimum BPT (1e6 wei) to address(0) on the very first mint
            bptOut = invariant > _POOL_MINIMUM_TOTAL_SUPPLY ? invariant - _POOL_MINIMUM_TOTAL_SUPPLY : 0;

            if (invariant == 0 || bptOut == 0) revert ZeroInvariant();
            return bptOut;
        } else {
            // ───── NORMAL (already initialized) CASE ─────
            require(balances[0] > 0 && balances[1] > 0, "Zero balance");

            uint256 ratio = amountsIn[0].divDown(balances[0]);
            uint256 ratioOther = amountsIn[1].divDown(balances[1]);

            require(
                ratio >= ratioOther
                    ? ratio - ratioOther <= DELTA
                    : ratioOther - ratio <= DELTA,
                "Non-proportional amounts"
            );

            require(ratio <= WeightedMath._MAX_IN_RATIO, "Exceeds max in ratio");

            bptOut = totalSupply.mulDown(ratio);
        }
    }

    /**
     * @dev Calculate the minimal BPT amount to burn (bptIn) for a proportional withdrawal
     * to receive at least the desired amount out for a specific token.
     * This uses ceiling division to ensure the actual amount out >= desiredAmountOut
     * after flooring in the proportional calculation.
     * Assumes no fees (RemoveLiquidityKind.PROPORTIONAL).
     * @param balances Current pool balances [token0, token1] (live scaled to 18 decimals).
     * @param totalSupply Current total BPT supply.
     * @param desiredTokenIndex Index of the token for which the desired amount out is specified (0 or 1).
     * @param desiredAmountOut Desired minimum amount out for the specified token (scaled).
     * @return bptIn Minimal BPT to burn to achieve at least desiredAmountOut for the specified token (rounded up).
     */
    function _calcBptInGivenProportionalOut(
        uint256[] memory balances,
        uint256 totalSupply,
        uint256 desiredTokenIndex,
        uint256 desiredAmountOut
    ) internal pure returns (uint256 bptIn) {
        require(balances.length == 2, "80/20 pool only");
        require(totalSupply > 0, "Zero total supply");
        require(desiredTokenIndex < 2, "Invalid token index");
        if (desiredAmountOut == 0) return 0;

        uint256 balance = balances[desiredTokenIndex];
        require(balance > 0, "Zero balance for desired token");
        require(desiredAmountOut <= balance.mulDown(WeightedMath._MAX_OUT_RATIO), "Exceeds max out ratio");

        // Compute bptIn = ceil(desiredAmountOut * totalSupply / balance)
        // Using integer math: (desiredAmountOut * totalSupply + balance - 1) / balance
        // Safe from overflow since desiredAmountOut <= balance * _MAX_OUT_RATIO (0.1e18),
        // and totalSupply is reasonable.
        uint256 numerator = desiredAmountOut.mulDown(totalSupply) + balance - 1;
        bptIn = numerator / balance;

        // Cap at totalSupply
        if (bptIn > totalSupply) {
            bptIn = totalSupply;
        }
    }

    // /**
    //  * @dev Proportional deposit: Amounts in given exact BPT out (AddLiquidityKind.PROPORTIONAL, no fees).
    //  * @param balances Current pool balances (scaled).
    //  * @param totalSupply Current total BPT supply.
    //  * @param bptOut Exact BPT minted.
    //  * @return amountsIn Proportional amounts in for each token (rounded up).
    //  */
    // function calcProportionalAmountsInGivenBptOut(
    //     uint256[] memory balances,
    //     uint256 totalSupply,
    //     uint256 bptOut
    // ) internal pure returns (uint256[] memory amountsIn) {
    //     if (bptOut == 0) return new uint256[](balances.length);
    //     require(bptOut <= totalSupply.mulDown(WeightedMath._MAX_IN_RATIO), "Exceeds max ratio"); // Proxy limit

    //     uint256 invariantRatio = (totalSupply + bptOut).divUp(totalSupply); // Round up to increase amountsIn
    //     amountsIn = new uint256[](balances.length);
    //     for (uint256 i = 0; i < balances.length; ++i) {
    //         amountsIn[i] = balances[i].mulUp(invariantRatio.complement()); // (ratio - 1) * balance, round up
    //     }
    // }

    // /**
    //  * @dev Proportional withdrawal: Amounts out given exact BPT in (RemoveLiquidityKind.PROPORTIONAL, no fees).
    //  * @param balances Current pool balances (scaled).
    //  * @param totalSupply Current total BPT supply.
    //  * @param bptIn Exact BPT burned.
    //  * @return amountsOut Proportional amounts out for each token (rounded down).
    //  */
    // function calcProportionalAmountsOutGivenBptIn(
    //     uint256[] memory balances,
    //     uint256 totalSupply,
    //     uint256 bptIn
    // ) internal pure returns (uint256[] memory amountsOut) {
    //     if (bptIn == 0) return new uint256[](balances.length);
    //     require(bptIn <= totalSupply, "Exceeds total supply");

    //     uint256 ratio = bptIn.divDown(totalSupply); // Round down to decrease amountsOut
    //     amountsOut = new uint256[](balances.length);
    //     for (uint256 i = 0; i < balances.length; ++i) {
    //         amountsOut[i] = balances[i].mulDown(ratio);
    //     }
    // }

    /**
     * @dev Proportional withdrawal: Amounts out given exact BPT in (RemoveLiquidityKind.PROPORTIONAL, no fees).
     * @param balances Current pool balances (scaled).
     * @param totalSupply Current total BPT supply.
     * @param bptIn Exact BPT burned.
     * @return amountsOut Proportional amounts out for each token (exact match to pool's raw calculation, rounded down).
     */
    function _calcProportionalAmountsOutGivenBptIn(uint256[] memory balances, uint256 totalSupply, uint256 bptIn)
        internal
        pure
        returns (uint256[] memory amountsOut)
    {
        if (bptIn == 0) return new uint256[](balances.length);
        require(bptIn <= totalSupply, "Exceeds total supply");

        amountsOut = new uint256[](balances.length);
        for (uint256 i = 0; i < balances.length; ++i) {
            // Direct mulDivDown: (balances[i] * bptIn) / totalSupply floored – matches Balancer's raw calc
            amountsOut[i] = BetterMath._mulDivDown(balances[i], bptIn, totalSupply);
        }
    }

    /**
     * @dev Inline mulDivDown if FixedPoint.mulDivDown is unavailable (Solidity 0.8+ safe).
     * Computes (x * y) / z floored, with overflow revert.
     */
    function __mulDivDown(uint256 x, uint256 y, uint256 z) private pure returns (uint256) {
        // No need for fixed-point scaling here – raw integer math matches Balancer's exit calc
        return (x * y) / z;
    }

    /**
     * @dev Calculate BPT out for a single token deposit (exact amount in).
     * @param balances Current pool balances [token0, token1] (live scaled to 18 decimals).
     * @param normalizedWeights Normalized weights [0.2e18, 0.8e18].
     * @param tokenIndex Index of the deposited token (0 or 1).
     * @param amountIn Exact amount deposited (scaled).
     * @param totalSupply Current BPT total supply.
     * @param swapFeePercentage Pool swap fee (e.g., 0.01e18 for 1%).
     * @return bptOut BPT minted (rounded down to favor protocol).
     */
    function _calcBptOutGivenSingleIn(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 tokenIndex,
        uint256 amountIn,
        uint256 totalSupply,
        uint256 swapFeePercentage
    ) internal pure returns (uint256) {
        if (amountIn == 0) return 0;
        require(balances.length == 2 && normalizedWeights.length == 2, "80/20 pool only");
        require(amountIn <= balances[tokenIndex].mulDown(WeightedMath._MAX_IN_RATIO), "Exceeds max in ratio");
        // Compute new balances with full amountIn
        uint256[] memory newBalances = new uint256[](2);
        for (uint256 i = 0; i < 2; ++i) {
            // start from current balances
            newBalances[i] = balances[i];
        }
        newBalances[tokenIndex] += amountIn;
        // Compute invariants
        uint256 currentInvariant = WeightedMath.computeInvariantUp(normalizedWeights, balances);
        uint256 newInvariant = WeightedMath.computeInvariantDown(normalizedWeights, newBalances);
        // Compute invariant ratio
        uint256 invariantRatio = newInvariant.divDown(currentInvariant);
        if (invariantRatio <= FixedPoint.ONE) return 0;
        if (invariantRatio > WeightedMath._MAX_INVARIANT_RATIO) revert WeightedMath.MaxInRatio();
        // Compute proportional balance for tokenIndex
        uint256 proportionalTokenBalance = invariantRatio.mulDown(balances[tokenIndex]);
        // Compute taxable amount and fee
        uint256 taxableAmount =
            newBalances[tokenIndex] > proportionalTokenBalance ? newBalances[tokenIndex] - proportionalTokenBalance : 0;
        uint256 swapFee = taxableAmount.mulUp(swapFeePercentage);
        // Adjust new balance for fee
        newBalances[tokenIndex] = newBalances[tokenIndex] - swapFee;
        // Compute new invariant with fees applied
        uint256 invariantWithFeesApplied = WeightedMath.computeInvariantDown(normalizedWeights, newBalances);
        // Compute BPT out = totalSupply * (invariantWithFeesApplied - currentInvariant) / currentInvariant, rounded down
        uint256 bptOut = (totalSupply * (invariantWithFeesApplied - currentInvariant)) / currentInvariant;
        return bptOut;
    }

    /**
     * @notice Compute the maximum single-token amount that can be deposited without causing the
     * pool invariant ratio (newInvariant / currentInvariant) to exceed WeightedMath._MAX_INVARIANT_RATIO.
     * This mirrors the check performed in `calcBptOutGivenSingleIn` where a revert occurs if the
     * invariant ratio is above the allowed maximum. The returned value is additionally bounded by
     * the per-token max in ratio: balances[tokenIndex] * WeightedMath._MAX_IN_RATIO.
     *
     * @param balances Current pool balances (scaled to 18 decimals).
     * @param normalizedWeights Normalized weights array (WAD-scaled).
     * @param tokenIndex Index of the token being deposited (0 or 1).
     * @return maxAmountIn Maximum deposit amount (in token native units) that will not exceed the max invariant ratio.
     */
    function _maxSingleInGivenMaxInvariantRatio(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 tokenIndex
    ) internal pure returns (uint256) {
        require(balances.length == 2 && normalizedWeights.length == 2, "80/20 pool only");

        // Current invariant: use the same direction as calcBptOutGivenSingleIn
        uint256 currentInvariant = WeightedMath.computeInvariantUp(normalizedWeights, balances);

        // Upper bound per-token: balances[tokenIndex] * _MAX_IN_RATIO
        uint256 perTokenMax = balances[tokenIndex].mulDown(WeightedMath._MAX_IN_RATIO);

        // If per-token bound is zero, nothing can be deposited
        if (perTokenMax == 0) return 0;

        // Quick check: if depositing the full perTokenMax still keeps invariant within limits, return it
        {
            uint256[] memory tmp = new uint256[](2);
            tmp[0] = balances[0];
            tmp[1] = balances[1];
            tmp[tokenIndex] += perTokenMax;
            uint256 newInvariant = WeightedMath.computeInvariantDown(normalizedWeights, tmp);
            uint256 invariantRatio = newInvariant.divDown(currentInvariant);
            if (invariantRatio <= WeightedMath._MAX_INVARIANT_RATIO) return perTokenMax;
        }

        // Binary search between 0 and perTokenMax to find the largest amount that keeps invariantRatio <= MAX_INVARIANT_RATIO
        uint256 low = 0;
        uint256 high = perTokenMax;

        while (low < high) {
            // mid biased up to avoid infinite loop
            uint256 mid = (low + high + 1) / 2;

            uint256[] memory tmp2 = new uint256[](2);
            tmp2[0] = balances[0];
            tmp2[1] = balances[1];
            tmp2[tokenIndex] += mid;

            uint256 newInvariant2 = WeightedMath.computeInvariantDown(normalizedWeights, tmp2);
            uint256 invariantRatio2 = newInvariant2.divDown(currentInvariant);

            if (invariantRatio2 <= WeightedMath._MAX_INVARIANT_RATIO) {
                // mid is allowed
                low = mid;
            } else {
                // mid exceeds allowed invariant, reduce high
                high = mid - 1;
            }
        }

        return low;
    }

    /**
     * @dev Calculate token out for a single token withdrawal (exact BPT in).
     * @param balances Current pool balances [token0, token1] (live scaled to 18 decimals).
     * @param normalizedWeights Normalized weights [0.2e18, 0.8e18].
     * @param tokenIndex Index of the withdrawn token (0 or 1).
     * @param bptIn Exact BPT burned (scaled).
     * @param totalSupply Current BPT total supply.
     * @param swapFeePercentage Pool swap fee (e.g., 0.01e18 for 1%).
     * @return amountOut Token withdrawn (rounded down to favor protocol).
     */
    function _calcSingleOutGivenBptIn(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 tokenIndex,
        uint256 bptIn,
        uint256 totalSupply,
        uint256 swapFeePercentage
    ) internal pure returns (uint256) {
        if (bptIn == 0) return 0;
        require(balances.length == 2 && normalizedWeights.length == 2, "80/20 pool only");
        require(bptIn <= totalSupply, "Exceeds total supply");
        require(bptIn <= totalSupply.mulDown(WeightedMath._MAX_OUT_RATIO), "Exceeds max out ratio");

        uint256 newBalance;
        {
            // Calculate invariant ratio = (totalSupply - bptIn) / totalSupply, rounded up for withdrawals
            uint256 invariantRatio = FixedPoint.divUp(totalSupply - bptIn, totalSupply);

            // Compute new balance using WeightedMath
            newBalance = WeightedMath.computeBalanceOutGivenInvariant(
                balances[tokenIndex], normalizedWeights[tokenIndex], invariantRatio
            );
        }

        // Amount out before fee = current balance - new balance
        uint256 amountOutBeforeFee = balances[tokenIndex] - newBalance;

        // Proportional balance = newSupply * balance / totalSupply, rounded up
        uint256 newSupply = totalSupply - bptIn;
        uint256 newBalanceBeforeTax = newSupply.mulDivUp(balances[tokenIndex], totalSupply);

        // Taxable amount = newBalanceBeforeTax - newBalance
        uint256 taxableAmount;
        unchecked {
            taxableAmount = newBalanceBeforeTax - newBalance;
        }

        // Swap fee on taxable amount, rounded up to favor protocol
        uint256 swapFee = taxableAmount.mulUp(swapFeePercentage);

        // Final amount out, rounded down
        uint256 amountOut = amountOutBeforeFee - swapFee;

        // Validate max out ratio
        if (amountOut > balances[tokenIndex].mulDown(WeightedMath._MAX_OUT_RATIO)) {
            revert WeightedMath.MaxOutRatio();
        }

        return amountOut;
    }

    /**
     * @dev Calculate BPT in for a single token withdrawal (exact amount out).
     * Uses binary search to find the BPT amount that yields the desired token out.
     * @param balances Current pool balances [token0, token1] (live scaled to 18 decimals).
     * @param normalizedWeights Normalized weights [0.2e18, 0.8e18].
     * @param tokenIndex Index of the withdrawn token (0 or 1).
     * @param amountOut Desired exact token out (scaled).
     * @param totalSupply Current BPT total supply.
     * @param swapFeePercentage Pool swap fee (e.g., 0.01e18 for 1%).
     * @return bptIn BPT to burn (rounded up to favor protocol).
     */
    function _calcBptInGivenSingleOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 tokenIndex,
        uint256 amountOut,
        uint256 totalSupply,
        uint256 swapFeePercentage
    ) internal pure returns (uint256) {
        if (amountOut == 0) return 0;
        require(balances.length == 2 && normalizedWeights.length == 2, "80/20 pool only");
        require(amountOut <= balances[tokenIndex].mulDown(WeightedMath._MAX_OUT_RATIO), "Exceeds max out ratio");

        // Binary search bounds: low=0, high=upper bound (e.g., totalSupply * _MAX_OUT_RATIO)
        uint256 low = 0;
        uint256 high = totalSupply.mulDown(WeightedMath._MAX_OUT_RATIO);

        while (low < high) {
            uint256 mid = (low + high + 1) / 2; // Bias up for rounding favor to protocol
            uint256 calculatedOut =
                _calcSingleOutGivenBptIn(balances, normalizedWeights, tokenIndex, mid, totalSupply, swapFeePercentage);
            if (calculatedOut >= amountOut) {
                high = mid - 1; // Too much BPT; reduce
            } else {
                low = mid; // Too little; increase
            }
        }

        // Verify and return (low + 1 if needed to meet exact, but since up-biased, check final)
        uint256 finalOut =
            _calcSingleOutGivenBptIn(balances, normalizedWeights, tokenIndex, low, totalSupply, swapFeePercentage);
        if (finalOut < amountOut) {
            low += 1; // Increment to ensure >= amountOut, favoring protocol
        }
        return low;
    }

    /* -------------------------------------------------------------------- */
    /*                      Additional helpers for DETF                   */
    /* -------------------------------------------------------------------- */

    uint256 private constant WAD = 1e18;

    /// @notice Returns spot price (token0 per token1) scaled to WAD
    function _priceFromReserves(
        uint256 baseCurrencyReserve,
        uint256 quoteCurrencyReserve,
        uint256 baseCurrencyWeight,
        uint256 quoteCurrencyWeight
    ) internal pure returns (uint256) {
        require(quoteCurrencyReserve > 0 && baseCurrencyWeight > 0, "BalancerV3Math:DIV0");
        return (baseCurrencyReserve * quoteCurrencyWeight * WAD) / (quoteCurrencyReserve * baseCurrencyWeight);
    }

    /// @notice Returns spot price (token0 per token1) scaled to WAD
    function _priceFromReserves(
        uint256 balance0,
        uint8 decimals0,
        uint256 balance1,
        uint8 decimals1,
        uint256 weight0,
        uint256 weight1
    ) internal pure returns (uint256) {
        uint256 a = BetterMath._convertDecimalsFromTo(balance0, decimals0, 18);
        uint256 b = BetterMath._convertDecimalsFromTo(balance1, decimals1, 18);
        require(b > 0 && weight0 > 0, "BalancerV3Math:DIV0");
        return (a * weight1 * WAD) / (b * weight0);
    }

    /**
     * @notice Unified helper: compute amount of token (specified by `tokenIndex`) to add so that
     * the spot price (token0 per token1, scaled WAD) reaches `targetPriceWad`.
     * @param balance0 Balance of token0
     * @param decimals0 Decimals for token0
     * @param balance1 Balance of token1
     * @param decimals1 Decimals for token1
     * @param weight0 Normalized weight for token0 (WAD)
     * @param weight1 Normalized weight for token1 (WAD)
     * @param targetPriceWad Target spot price (token0 per token1) scaled to WAD
     * @param tokenIndex Which token to compute the delta for: 0 => token0, 1 => token1
     * @return delta Amount of the selected token to add (in token's native units)
     */
    function _deltaTokenToReachTarget(
        uint256 balance0,
        uint8 decimals0,
        uint256 balance1,
        uint8 decimals1,
        uint256 weight0,
        uint256 weight1,
        uint256 targetPriceWad,
        uint8 tokenIndex
    ) internal pure returns (uint256) {
        // Token0 delta
        if (tokenIndex == 0) {
            uint256 a = BetterMath._convertDecimalsFromTo(balance0, decimals0, 18);
            uint256 b = BetterMath._convertDecimalsFromTo(balance1, decimals1, 18);
            uint256 cur = _priceFromReserves(a, 18, b, 18, weight0, weight1);
            if (targetPriceWad <= cur) return 0;
            uint256 numerator = targetPriceWad * b * weight0; // note: target has WAD
            uint256 denom = weight1 * WAD;
            uint256 targetA = numerator / denom;
            if (targetA <= a) return 0;
            return targetA - a;
        }

        // Token1 delta (tokenIndex == 1)
        if (tokenIndex == 1) {
            uint256 a = BetterMath._convertDecimalsFromTo(balance0, decimals0, 18);
            uint256 b = BetterMath._convertDecimalsFromTo(balance1, decimals1, 18);
            uint256 cur = _priceFromReserves(a, 18, b, 18, weight0, weight1);
            if (targetPriceWad >= cur) return 0;
            uint256 numerator = a * weight1 * WAD;
            uint256 denom = targetPriceWad * weight0;
            uint256 targetB = numerator / denom;
            if (targetB <= b) return 0;
            return targetB - b;
        }

        revert("BalancerV3Math:INVALID_TOKEN_INDEX");
    }

    /// @notice Virtual price assuming virtual token0 balance equals virtualSupply (token decimals must match inputs)
    function _virtualPriceGivenVirtualToken0(
        uint256 virtualToken0,
        uint8 decimals0,
        uint256 balance1,
        uint8 decimals1,
        uint256 weight0,
        uint256 weight1
    ) internal pure returns (uint256) {
        uint256 a = BetterMath._convertDecimalsFromTo(virtualToken0, decimals0, 18);
        uint256 b = BetterMath._convertDecimalsFromTo(balance1, decimals1, 18);
        return _priceFromReserves(a, 18, b, 18, weight0, weight1);
    }

    /**
     * @notice Convenience wrapper matching PRD naming: compute virtual price using a `totalSupply`-like virtual
     * token0 balance. This treats `totalSupply` as the virtual token0 amount (decimals provided by `decimals0`).
     */
    function _virtualPriceGivenTotalSupply(
        uint256 totalSupply,
        uint8 decimals0,
        uint256 balance1,
        uint8 decimals1,
        uint256 weight0,
        uint256 weight1
    ) internal pure returns (uint256) {
        // Reuse the existing virtualPriceGivenVirtualToken0 implementation
        return _virtualPriceGivenVirtualToken0(totalSupply, decimals0, balance1, decimals1, weight0, weight1);
    }

    /// @notice Calculates the spot price of tokenA per tokenB, scaled to WAD (1e18).
    /// @param balanceA Balance of tokenA in native decimals.
    /// @param decimalsA Decimals of tokenA.
    /// @param balanceB Balance of tokenB in native decimals.
    /// @param decimalsB Decimals of tokenB.
    /// @param weightA Normalized weight of tokenA (in WAD, e.g., 0.2e18 for 20%).
    /// @param weightB Normalized weight of tokenB (in WAD, e.g., 0.8e18 for 80%).
    /// @return spotPriceWad Spot price (tokenA per tokenB) scaled to WAD.
    function _spotPriceAPerB(
        uint256 balanceA,
        uint8 decimalsA,
        uint256 balanceB,
        uint8 decimalsB,
        uint256 weightA,
        uint256 weightB
    ) internal pure returns (uint256) {
        uint256 normA = BetterMath._convertDecimalsFromTo(balanceA, decimalsA, 18);
        uint256 normB = BetterMath._convertDecimalsFromTo(balanceB, decimalsB, 18);
        require(normB > 0 && weightA > 0, "BalancerV3Math: DIVISION_BY_ZERO");
        return (normA * weightB * WAD) / (normB * weightA);
    }

    /// @notice Computes the amount of tokenA to add to reach a target spot price (tokenA per tokenB).
    /// @param balanceA Current balance of tokenA in native decimals.
    /// @param decimalsA Decimals of tokenA.
    /// @param balanceB Current balance of tokenB in native decimals.
    /// @param decimalsB Decimals of tokenB.
    /// @param weightA Normalized weight of tokenA (in WAD).
    /// @param weightB Normalized weight of tokenB (in WAD).
    /// @param targetPriceWad Target spot price (tokenA per tokenB) scaled to WAD.
    /// @return deltaA Amount of tokenA to add, in native decimals of tokenA.
    function _deltaAToReachTargetPrice(
        uint256 balanceA,
        uint8 decimalsA,
        uint256 balanceB,
        uint8 decimalsB,
        uint256 weightA,
        uint256 weightB,
        uint256 targetPriceWad
    ) internal pure returns (uint256) {
        uint256 normA = BetterMath._convertDecimalsFromTo(balanceA, decimalsA, 18);
        uint256 normB = BetterMath._convertDecimalsFromTo(balanceB, decimalsB, 18);
        uint256 currentPriceWad = _spotPriceAPerB(balanceA, decimalsA, balanceB, decimalsB, weightA, weightB);
        if (targetPriceWad <= currentPriceWad) return 0;

        uint256 numerator = targetPriceWad * normB * weightA;
        uint256 denominator = weightB * WAD;
        uint256 targetNormA = numerator / denominator;
        if (targetNormA <= normA) return 0;

        uint256 normDeltaA = targetNormA - normA;
        // Convert delta back to native decimals of tokenA
        return BetterMath._convertDecimalsFromTo(normDeltaA, 18, decimalsA);
    }

    /// @notice Computes the amount of tokenB to add to reach a target spot price (tokenA per tokenB).
    /// @param balanceA Current balance of tokenA in native decimals.
    /// @param decimalsA Decimals of tokenA.
    /// @param balanceB Current balance of tokenB in native decimals.
    /// @param decimalsB Decimals of tokenB.
    /// @param weightA Normalized weight of tokenA (in WAD).
    /// @param weightB Normalized weight of tokenB (in WAD).
    /// @param targetPriceWad Target spot price (tokenA per tokenB) scaled to WAD.
    /// @return deltaB Amount of tokenB to add, in native decimals of tokenB.
    function _deltaBToReachTargetPrice(
        uint256 balanceA,
        uint8 decimalsA,
        uint256 balanceB,
        uint8 decimalsB,
        uint256 weightA,
        uint256 weightB,
        uint256 targetPriceWad
    ) internal pure returns (uint256) {
        uint256 normA = BetterMath._convertDecimalsFromTo(balanceA, decimalsA, 18);
        uint256 normB = BetterMath._convertDecimalsFromTo(balanceB, decimalsB, 18);
        uint256 currentPriceWad = _spotPriceAPerB(balanceA, decimalsA, balanceB, decimalsB, weightA, weightB);
        if (targetPriceWad >= currentPriceWad) return 0;

        uint256 numerator = normA * weightB * WAD;
        uint256 denominator = targetPriceWad * weightA;
        uint256 targetNormB = numerator / denominator;
        if (targetNormB <= normB) return 0;

        uint256 normDeltaB = targetNormB - normB;
        // Convert delta back to native decimals of tokenB
        return BetterMath._convertDecimalsFromTo(normDeltaB, 18, decimalsB);
    }

    /// @notice Calculates the virtual spot price (tokenA per tokenB) assuming a virtual balance for tokenA.
    /// @param virtualBalanceA Virtual balance of tokenA in native decimals.
    /// @param decimalsA Decimals of tokenA.
    /// @param balanceB Balance of tokenB in native decimals.
    /// @param decimalsB Decimals of tokenB.
    /// @param weightA Normalized weight of tokenA (in WAD).
    /// @param weightB Normalized weight of tokenB (in WAD).
    /// @return virtualPriceWad Virtual spot price scaled to WAD.
    function _virtualSpotPriceAPerB(
        uint256 virtualBalanceA,
        uint8 decimalsA,
        uint256 balanceB,
        uint8 decimalsB,
        uint256 weightA,
        uint256 weightB
    ) internal pure returns (uint256) {
        // Reuse spotPriceAPerB with virtualBalanceA as balanceA
        return _spotPriceAPerB(virtualBalanceA, decimalsA, balanceB, decimalsB, weightA, weightB);
    }

    /// @notice Convenience wrapper: virtual spot price assuming virtual tokenA balance equals totalSupply.
    /// @param totalSupply Virtual balance for tokenA (e.g., total supply assuming tokenA decimals).
    /// @param decimalsA Decimals for the virtual tokenA (totalSupply decimals).
    /// @param balanceB Balance of tokenB in native decimals.
    /// @param decimalsB Decimals of tokenB.
    /// @param weightA Normalized weight of tokenA (in WAD).
    /// @param weightB Normalized weight of tokenB (in WAD).
    /// @return virtualPriceWad Virtual spot price scaled to WAD.
    function _virtualSpotPriceGivenTotalSupply(
        uint256 totalSupply,
        uint8 decimalsA,
        uint256 balanceB,
        uint8 decimalsB,
        uint256 weightA,
        uint256 weightB
    ) internal pure returns (uint256) {
        // Reuse virtualSpotPriceAPerB with totalSupply as virtualBalanceA
        return _virtualSpotPriceAPerB(totalSupply, decimalsA, balanceB, decimalsB, weightA, weightB);
    }
}
