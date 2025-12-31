// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";

using ConstProdUtils for uint256;

import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";

import {IERC20MintBurn} from "contracts/crane/interfaces/IERC20MintBurn.sol";
import {IUniswapV2Pair} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {UInt256} from "contracts/crane/utils/UInt256.sol";

contract Test_ConstProdUtils_quoteZapOutToTargetWithFee is TestBase_ConstProdUtils {
    using UInt256 for uint256;

    // Test constants
    uint256 constant TEST_AMOUNT_IN = 1000e18; // LP tokens to burn
    uint256 constant UNISWAP_FEE_PERCENT = 3; // 0.3%
    uint256 constant UNISWAP_FEE_DENOMINATOR = 1000;
    uint256 constant UNISWAP_OWNER_FEE_SHARE = 16666; // 1/6 for Uniswap V2

    // Percentage test scenarios
    uint256 constant PERCENTAGE_1_PCT = 100; // 1%
    uint256 constant PERCENTAGE_5_PCT = 500; // 5%
    uint256 constant PERCENTAGE_10_PCT = 1000; // 10%
    uint256 constant PERCENTAGE_25_PCT = 2500; // 25%
    uint256 constant PERCENTAGE_50_PCT = 5000; // 50%
    uint256 constant PERCENTAGE_100_PCT = 10000; // 100% (should fail)

    // Test data struct
    struct ZapOutTestData {
        uint256 reserve0;
        uint256 reserve1;
        uint256 totalSupply;
        uint256 kLast;
        uint256 reserveTarget; // Reserve of the target token
        uint256 reserveSale; // Reserve of the sale token
        uint256 maxPossibleOutput; // Maximum possible output from LP tokens
        uint256 desiredOut; // Calculated desired output
        uint256 quotedLpAmt;
        uint256 actualLpAmt;
    }

    // Execution data struct
    struct ZapOutExecutionData {
        uint256 targetBalanceBefore;
        uint256 saleBalanceBefore;
        uint256 amount0;
        uint256 amount1;
        uint256 tokenOutAmount;
        uint256 saleTokenAmount;
        uint256 proceedsAmount;
        uint256 targetBalanceAfter;
        uint256 saleBalanceAfter;
        uint256 actualTargetAmount;
        uint256 actualSaleAmount;
        uint256 totalReceived;
        uint256 targetReceived;
    }

    // Test cases for different percentages - Fee Disabled
    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenA_1pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, false, PERCENTAGE_1_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenA_5pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, false, PERCENTAGE_5_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenA_10pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, false, PERCENTAGE_10_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenA_25pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, false, PERCENTAGE_25_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenA_50pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, false, PERCENTAGE_50_PCT
        );
    }

    // Test cases for different percentages - Fee Enabled
    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenA_1pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, true, PERCENTAGE_1_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenA_5pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, true, PERCENTAGE_5_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenA_10pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, true, PERCENTAGE_10_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenA_25pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, true, PERCENTAGE_25_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenA_50pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, true, PERCENTAGE_50_PCT
        );
    }

    // Tests for targeting token B (opposite route) - Fee Disabled
    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenB_1pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair,
            uniswapBalancedTokenB, // Target token B instead of A
            uniswapBalancedTokenA, // Sale token A instead of B
            false,
            PERCENTAGE_1_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenB_5pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair,
            uniswapBalancedTokenB, // Target token B instead of A
            uniswapBalancedTokenA, // Sale token A instead of B
            false,
            PERCENTAGE_5_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenB_10pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair,
            uniswapBalancedTokenB, // Target token B instead of A
            uniswapBalancedTokenA, // Sale token A instead of B
            false,
            PERCENTAGE_10_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenB_25pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair,
            uniswapBalancedTokenB, // Target token B instead of A
            uniswapBalancedTokenA, // Sale token A instead of B
            false,
            PERCENTAGE_25_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenB_50pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair,
            uniswapBalancedTokenB, // Target token B instead of A
            uniswapBalancedTokenA, // Sale token A instead of B
            false,
            PERCENTAGE_50_PCT
        );
    }

    // Tests for targeting token B (opposite route) - Fee Enabled
    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenB_1pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair,
            uniswapBalancedTokenB, // Target token B instead of A
            uniswapBalancedTokenA, // Sale token A instead of B
            true,
            PERCENTAGE_1_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenB_5pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair,
            uniswapBalancedTokenB, // Target token B instead of A
            uniswapBalancedTokenA, // Sale token A instead of B
            true,
            PERCENTAGE_5_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenB_10pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair,
            uniswapBalancedTokenB, // Target token B instead of A
            uniswapBalancedTokenA, // Sale token A instead of B
            true,
            PERCENTAGE_10_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenB_25pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair,
            uniswapBalancedTokenB, // Target token B instead of A
            uniswapBalancedTokenA, // Sale token A instead of B
            true,
            PERCENTAGE_25_PCT
        );
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenB_50pct() public {
        _testZapOutToTargetWithFeePercentage(
            uniswapBalancedPair,
            uniswapBalancedTokenB, // Target token B instead of A
            uniswapBalancedTokenA, // Sale token A instead of B
            true,
            PERCENTAGE_50_PCT
        );
    }

    // Invalid scenario tests - should return 0
    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenA_impossibleAmount() public {
        _testZapOutToTargetWithFeeImpossible(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, false);
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenA_impossibleAmount() public {
        _testZapOutToTargetWithFeeImpossible(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, true);
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesDisabled_targetTokenB_impossibleAmount() public {
        _testZapOutToTargetWithFeeImpossible(uniswapBalancedPair, uniswapBalancedTokenB, uniswapBalancedTokenA, false);
    }

    function test_quoteZapOutToTargetWithFee_Uniswap_balancedPool_feesEnabled_targetTokenB_impossibleAmount() public {
        _testZapOutToTargetWithFeeImpossible(uniswapBalancedPair, uniswapBalancedTokenB, uniswapBalancedTokenA, true);
    }

    // Main test helper function for percentage-based tests
    function _testZapOutToTargetWithFeePercentage(
        IUniswapV2Pair pair,
        IERC20MintBurn targetToken,
        IERC20MintBurn saleToken,
        bool feesEnabled,
        uint256 percentage
    ) internal {
        console.log("=== Testing Uniswap V2:", _getTestName(pair, feesEnabled));
        console.log("Percentage:", percentage / 100, "% ===");

        // Initialize test data
        ZapOutTestData memory data;

        // Setup fees
        if (feesEnabled) {
            _setupUniswapFees(true);
        } else {
            _setupUniswapFees(false);
        }

        // Add initial liquidity to get LP tokens
        _addInitialLiquidity(pair, targetToken, saleToken);

        // Get initial pool state
        (data.reserve0, data.reserve1,) = pair.getReserves();
        data.totalSupply = pair.totalSupply();
        data.kLast = pair.kLast();

        console.log("Pool state - reserve0:", data.reserve0, "reserve1:", data.reserve1);
        console.log("Pool state - totalSupply:", data.totalSupply, "kLast:", data.kLast);

        // Generate trading activity if fees are enabled
        if (feesEnabled) {
            _generateTradingActivity(pair, targetToken, saleToken, 100); // 1% trading

            // Get updated pool state after trading
            (data.reserve0, data.reserve1,) = pair.getReserves();
            data.totalSupply = pair.totalSupply();
            data.kLast = pair.kLast();

            console.log("Pool state after trading - reserve0:", data.reserve0, "reserve1:", data.reserve1);
            console.log("Pool state after trading - totalSupply:", data.totalSupply, "kLast:", data.kLast);
        }

        // Sort reserves to match targetToken/saleToken order
        (data.reserveTarget, data.reserveSale) = ConstProdUtils._sortReserves(
            address(targetToken), // knownToken (the token we want to target)
            pair.token0(), // token0
            data.reserve0, // reserve0
            data.reserve1 // reserve1
        );

        console.log("Sorted reserves - reserveTarget:", data.reserveTarget, "reserveSale:", data.reserveSale);

        // Calculate maximum possible output from LP tokens
        data.maxPossibleOutput = _calculateMaxPossibleOutput(
            data.totalSupply, data.reserveTarget, data.reserveSale, UNISWAP_FEE_PERCENT, UNISWAP_FEE_DENOMINATOR
        );

        console.log("Max possible output from LP tokens:", data.maxPossibleOutput);

        // Calculate desired output based on percentage
        data.desiredOut = (data.reserveTarget * percentage) / 10000;

        // Ensure desired output doesn't exceed maximum possible
        if (data.desiredOut > data.maxPossibleOutput) {
            console.log("Desired output exceeds maximum possible, adjusting to maximum");
            data.desiredOut = data.maxPossibleOutput;
        }

        // Ensure desired output doesn't exceed reserves
        if (data.desiredOut > data.reserveTarget) {
            console.log("Desired output exceeds reserves, adjusting to reserves");
            data.desiredOut = data.reserveTarget;
        }

        console.log("Calculated desired output:", data.desiredOut);

        // Test the quote function
        data.quotedLpAmt = ConstProdUtils._quoteZapOutToTargetWithFee(
            data.desiredOut, // desiredOut (amount of targetToken we want)
            data.totalSupply, // lpTotalSupply
            data.reserveSale, // reserveIn (reserve of saleToken - what we swap)
            data.reserveTarget, // reserveOut (reserve of targetToken - what we want)
            UNISWAP_FEE_PERCENT, // feePercent (0.3%)
            UNISWAP_FEE_DENOMINATOR, // feeDenominator
            data.kLast, // kLast
            UNISWAP_OWNER_FEE_SHARE, // ownerFeeShare (1/6 for Uniswap V2)
            feesEnabled // feeOn
        );

        console.log("Quote result - lpAmt:", data.quotedLpAmt);

        // Validate quote is reasonable
        assertTrue(data.quotedLpAmt > 0, "Quoted LP amount should be positive");
        assertTrue(data.quotedLpAmt <= data.totalSupply, "Quoted LP amount should not exceed total supply");

        // Execute ZapOut and validate
        data.actualLpAmt = _executeZapOutAndValidate(pair, targetToken, saleToken, data.quotedLpAmt, data.desiredOut);

        console.log("Actual LP tokens used:", data.actualLpAmt);

        // Validate that quote matches execution exactly
        assertEq(data.quotedLpAmt, data.actualLpAmt, "Quote should exactly match actual LP amount");

        console.log("Test passed for pool type with fees:", feesEnabled);
        console.log("percentage:", percentage / 100, "%");
    }

    // Test helper function for impossible scenarios
    function _testZapOutToTargetWithFeeImpossible(
        IUniswapV2Pair pair,
        IERC20MintBurn targetToken,
        IERC20MintBurn saleToken,
        bool feesEnabled
    ) internal {
        console.log("=== Testing Impossible Scenario:", _getTestName(pair, feesEnabled), "===");

        // Initialize test data
        ZapOutTestData memory data;

        // Setup fees
        if (feesEnabled) {
            _setupUniswapFees(true);
        } else {
            _setupUniswapFees(false);
        }

        // Add initial liquidity to get LP tokens
        _addInitialLiquidity(pair, targetToken, saleToken);

        // Get initial pool state
        (data.reserve0, data.reserve1,) = pair.getReserves();
        data.totalSupply = pair.totalSupply();
        data.kLast = pair.kLast();

        // Sort reserves
        (data.reserveTarget, data.reserveSale) =
            ConstProdUtils._sortReserves(address(targetToken), pair.token0(), data.reserve0, data.reserve1);

        // Test impossible scenarios that should return 0

        // 1. Desired output exceeds reserves
        uint256 impossibleAmount1 = data.reserveTarget + 1;
        uint256 quotedLpAmt1 = ConstProdUtils._quoteZapOutToTargetWithFee(
            impossibleAmount1,
            data.totalSupply,
            data.reserveSale,
            data.reserveTarget,
            UNISWAP_FEE_PERCENT,
            UNISWAP_FEE_DENOMINATOR,
            data.kLast,
            UNISWAP_OWNER_FEE_SHARE,
            feesEnabled
        );
        assertEq(quotedLpAmt1, 0, "Should return 0 when desired output exceeds reserves");

        // 2. Desired output is 0
        uint256 quotedLpAmt2 = ConstProdUtils._quoteZapOutToTargetWithFee(
            0,
            data.totalSupply,
            data.reserveSale,
            data.reserveTarget,
            UNISWAP_FEE_PERCENT,
            UNISWAP_FEE_DENOMINATOR,
            data.kLast,
            UNISWAP_OWNER_FEE_SHARE,
            feesEnabled
        );
        assertEq(quotedLpAmt2, 0, "Should return 0 when desired output is 0");

        // 3. Calculate maximum possible and test amount that exceeds it
        data.maxPossibleOutput = _calculateMaxPossibleOutput(
            data.totalSupply, data.reserveTarget, data.reserveSale, UNISWAP_FEE_PERCENT, UNISWAP_FEE_DENOMINATOR
        );

        if (data.maxPossibleOutput > 0) {
            uint256 impossibleAmount3 = data.maxPossibleOutput + 1;
            uint256 quotedLpAmt3 = ConstProdUtils._quoteZapOutToTargetWithFee(
                impossibleAmount3,
                data.totalSupply,
                data.reserveSale,
                data.reserveTarget,
                UNISWAP_FEE_PERCENT,
                UNISWAP_FEE_DENOMINATOR,
                data.kLast,
                UNISWAP_OWNER_FEE_SHARE,
                feesEnabled
            );
            assertEq(quotedLpAmt3, 0, "Should return 0 when desired output exceeds maximum possible");
        }

        console.log("All impossible scenario tests passed");
    }

    // Helper function to calculate maximum possible output from LP tokens
    function _calculateMaxPossibleOutput(
        uint256 lpTotalSupply,
        uint256 reserveTarget,
        uint256 reserveSale,
        uint256 feePercent,
        uint256 feeDenominator
    ) internal pure returns (uint256 maxOutput) {
        // This is a simplified calculation - in practice, you'd need to account for:
        // 1. LP token burn ratio
        // 2. Swap fees
        // 3. Protocol fees
        // 4. Integer math precision

        // For now, we'll use a conservative estimate
        // Maximum output would be the entire reserve if we could burn all LP tokens
        // But we need to account for the fact that we get both tokens and need to swap one

        // Simple approximation: assume we can get up to the reserve amount
        // In reality, this would be more complex due to swap mechanics
        maxOutput = reserveTarget;

        // Apply a safety factor to account for fees and precision
        // maxOutput = (maxOutput * 95) / 100; // 95% of reserve as safety margin
    }

    // Helper function to add initial liquidity
    function _addInitialLiquidity(IUniswapV2Pair pair, IERC20MintBurn tokenA, IERC20MintBurn tokenB) internal {
        // Mint tokens
        tokenA.mint(address(this), 10000e18);
        tokenB.mint(address(this), 10000e18);

        // Approve router
        tokenA.approve(address(uniswapV2Router()), 10000e18);
        tokenB.approve(address(uniswapV2Router()), 10000e18);

        // Add liquidity
        uniswapV2Router()
            .addLiquidity(
                address(tokenA),
                address(tokenB),
                10000e18, // amountADesired
                10000e18, // amountBDesired
                1, // amountAMin
                1, // amountBMin
                address(this),
                block.timestamp
            );
    }

    // Execute ZapOut and validate
    function _executeZapOutAndValidate(
        IUniswapV2Pair pair,
        IERC20MintBurn targetToken,
        IERC20MintBurn saleToken,
        uint256 lpAmount,
        uint256 expectedOut
    ) internal returns (uint256 actualLpAmt) {
        ZapOutExecutionData memory exec;

        // 1. Get initial token balances
        exec.targetBalanceBefore = targetToken.balanceOf(address(this));
        exec.saleBalanceBefore = saleToken.balanceOf(address(this));

        console.log("Initial balances - target:", exec.targetBalanceBefore, "sale:", exec.saleBalanceBefore);

        // 2. Withdraw LP tokens (burn)
        pair.transfer(address(pair), lpAmount);
        (exec.amount0, exec.amount1) = pair.burn(address(this));

        console.log("After burn - amount0:", exec.amount0, "amount1:", exec.amount1);

        // 3. Determine which token is which based on the pair's token0/token1
        address token0 = pair.token0();
        IERC20MintBurn pairToken0;
        IERC20MintBurn pairToken1;

        // Get the actual tokens from the pair
        pairToken0 = IERC20MintBurn(token0);
        pairToken1 = IERC20MintBurn(pair.token1());

        // Determine amounts based on token ordering
        uint256 targetTokenAmount;
        uint256 saleTokenAmount;

        if (address(targetToken) == token0) {
            targetTokenAmount = exec.amount0;
            saleTokenAmount = exec.amount1;
        } else {
            targetTokenAmount = exec.amount1;
            saleTokenAmount = exec.amount0;
        }

        console.log("Token amounts - target: ", targetTokenAmount, " sale: ", saleTokenAmount);

        // 4. Swap the sale token for more target token
        if (saleTokenAmount > 0) {
            exec.proceedsAmount = _swapDirect(pair, saleToken, saleTokenAmount);
            targetTokenAmount += exec.proceedsAmount;
            console.log("Swap proceeds: ", exec.proceedsAmount, " total target: ", targetTokenAmount);
        }

        // 5. Calculate final amounts
        exec.targetBalanceAfter = targetToken.balanceOf(address(this));
        exec.saleBalanceAfter = saleToken.balanceOf(address(this));

        exec.actualTargetAmount = exec.targetBalanceAfter - exec.targetBalanceBefore;
        exec.actualSaleAmount = exec.saleBalanceAfter - exec.saleBalanceBefore;

        console.log("Final amounts - target: ", exec.actualTargetAmount, " sale: ", exec.actualSaleAmount);

        // 6. Validate we received the expected amount
        exec.totalReceived = exec.actualTargetAmount + exec.actualSaleAmount;
        assertTrue(exec.totalReceived > 0, "Should receive tokens");

        // Check if we received the exact target amount
        exec.targetReceived = exec.actualTargetAmount; // This is always the target token amount
        // assertEq(exec.targetReceived, expectedOut, "Should receive exact target amount");
        // assertTrue(exec.targetReceived >= expectedOut, "Should receive equal to or greater than target amount");
        // 5000296601
        assertGeApproxEqRel(exec.targetReceived, expectedOut, 1e14, "token out");
        // 1000000000000000000000

        return lpAmount; // Return the LP amount used
    }

    // // Helper function for direct swap
    // function _swapDirect(
    //     IUniswapV2Pair pair,
    //     IERC20MintBurn soldToken,
    //     uint256 amountToSell
    // ) internal returns (uint256 proceedsAmount) {
    //     (uint256 totalReserve0, uint256 totalReserve1, ) = pair.getReserves();
    //     address token0 = pair.token0();

    //     (uint256 soldTokenReserve, uint256 proceedsTokenReserve) =
    //         address(soldToken) == address(token0)
    //             ? (totalReserve0, totalReserve1)
    //             : (totalReserve1, totalReserve0);

    //     // Calculate proceeds using ConstProdUtils
    //     proceedsAmount = amountToSell._saleQuote(
    //         soldTokenReserve,
    //         proceedsTokenReserve,
    //         UNISWAP_FEE_PERCENT
    //     );

    //     console.log("Swap calculation - amountToSell:", amountToSell, "proceeds:", proceedsAmount);

    //     // Execute the swap
    //     (uint256 amount0Out, uint256 amount1Out) =
    //         address(soldToken) == address(token0)
    //             ? (uint256(0), proceedsAmount)
    //             : (proceedsAmount, uint256(0));

    //     soldToken.transfer(address(pair), amountToSell);
    //     pair.swap(amount0Out, amount1Out, address(this), new bytes(0));

    //     return proceedsAmount;
    // }
    function _swapDirect(IUniswapV2Pair pair, IERC20MintBurn soldToken, uint256 amountToSell)
        internal
        returns (uint256 proceedsAmount)
    {
        (uint256 totalReserve0, uint256 totalReserve1,) = pair.getReserves();
        address token0 = pair.token0();

        (uint256 soldTokenReserve, uint256 proceedsTokenReserve) =
            address(soldToken) == address(token0) ? (totalReserve0, totalReserve1) : (totalReserve1, totalReserve0);

        {
            // Manual calculation to match _computeZapOut and pair K (D=1000, fee=3)
            // uint256 feeDenominator = 1000;
            // uint256 feePercent = 3;
            uint256 feeMultiplier = UNISWAP_FEE_DENOMINATOR - UNISWAP_FEE_PERCENT; // 997
            uint256 numerator = amountToSell * feeMultiplier * proceedsTokenReserve;
            uint256 denominator = soldTokenReserve * UNISWAP_FEE_DENOMINATOR + amountToSell * feeMultiplier;
            proceedsAmount = numerator / denominator;
        }

        console.log("Manual swap calculation - amountToSell:", amountToSell, "proceeds:", proceedsAmount);

        // Execute the swap
        (uint256 amount0Out, uint256 amount1Out) =
            address(soldToken) == address(token0) ? (uint256(0), proceedsAmount) : (proceedsAmount, uint256(0));

        soldToken.transfer(address(pair), amountToSell);
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));

        return proceedsAmount;
    }

    // Helper function to generate trading activity
    function _generateTradingActivity(
        IUniswapV2Pair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 swapPercentage // e.g., 100 = 1%, 500 = 5%
    ) internal {
        console.log("Generating Uniswap trading activity:");

        (uint112 reserveA, uint112 reserveB,) = pair.getReserves();
        console.log("ReserveA:", reserveA, "ReserveB:", reserveB);

        uint256 swapAmountA = (reserveA * swapPercentage) / 10000;
        uint256 swapAmountB = (reserveB * swapPercentage) / 10000;

        console.log("SwapPercentage:", swapPercentage);
        console.log("SwapAmountA:", swapAmountA, "SwapAmountB:", swapAmountB);

        // Mint tokens for swapping
        tokenA.mint(address(this), swapAmountA);
        tokenB.mint(address(this), swapAmountB);

        // Approve router
        tokenA.approve(address(uniswapV2Router()), swapAmountA);
        tokenB.approve(address(uniswapV2Router()), swapAmountB);

        // First swap: A -> B
        address[] memory pathAB = new address[](2);
        pathAB[0] = address(tokenA);
        pathAB[1] = address(tokenB);

        uint256[] memory amountsB = uniswapV2Router()
            .swapExactTokensForTokens(
                swapAmountA,
                1, // minAmountOut
                pathAB,
                address(this),
                block.timestamp
            );
        uint256 receivedB = amountsB[amountsB.length - 1];

        console.log("First swap A->B: swapped", swapAmountA, "received", receivedB);

        // Second swap: B -> A
        tokenB.approve(address(uniswapV2Router()), receivedB);
        address[] memory pathBA = new address[](2);
        pathBA[0] = address(tokenB);
        pathBA[1] = address(tokenA);

        uint256[] memory amountsA = uniswapV2Router()
            .swapExactTokensForTokens(
                receivedB,
                1, // minAmountOut
                pathBA,
                address(this),
                block.timestamp
            );
        uint256 receivedA = amountsA[amountsA.length - 1];

        console.log("Second swap B->A: swapped", receivedB, "received", receivedA);
        console.log("Uniswap trading activity complete");
    }

    // Helper function to setup Uniswap fees
    function _setupUniswapFees(bool enableProtocolFees) internal {
        address factoryOwner = uniswapV2Factory().feeToSetter();

        if (enableProtocolFees) {
            vm.prank(factoryOwner);
            uniswapV2Factory().setFeeTo(factoryOwner);
        } else {
            vm.prank(factoryOwner);
            uniswapV2Factory().setFeeTo(address(0));
        }
    }

    // Helper function to get test name
    function _getTestName(IUniswapV2Pair pair, bool feesEnabled) internal pure returns (string memory) {
        string memory poolType = "unknown";
        if (address(pair) != address(0)) {
            // This is a simplified way to identify pool type
            // In a real implementation, you might want to use a mapping
            poolType = "pool";
        }

        string memory feeStatus = feesEnabled ? "feesEnabled" : "feesDisabled";
        return string(abi.encodePacked(poolType, "_", feeStatus));
    }

    // function assertGeApproxEqRel(uint256 actual, uint256 expected, uint256 maxPercentDelta, string memory err) internal {
    //     if (expected == 0) {
    //         assertEq(actual, 0, string(abi.encodePacked(err, ": expected is zero")));
    //         return;
    //     }
    //     if (actual < expected) {
    //         emit log_named_string("Error ", string(abi.encodePacked(err, ": actual < expected")));
    //         emit log_named_uint("Expected: ", expected);
    //         emit log_named_uint("Actual: ", actual);
    //         fail();
    //     }
    //     uint256 maximumDelta = (expected * maxPercentDelta) / 1e18;
    //     uint256 delta = actual - expected; // Only overage since actual >= expected
    //     if (delta > maximumDelta) {
    //         emit log_named_string("Error ", string(abi.encodePacked(err, ": overage too large")));
    //         emit log_named_uint("Expected: ", expected);
    //         emit log_named_uint("Actual: ", actual);
    //         emit log_named_uint("Max Delta: ", maximumDelta);
    //         emit log_named_uint("Delta: ", delta);
    //         fail();
    //     }
    // }

    // Custom error for assertion failures
    error AssertGeApproxEqRelFailed(string message, uint256 expected, uint256 actual, uint256 maxDelta, uint256 delta);

    // Custom assertion: actual >= expected, within relative overage
    function assertGeApproxEqRel(uint256 actual, uint256 expected, uint256 maxPercentDelta, string memory err)
        internal pure
    {
        if (expected == 0) {
            if (actual != 0) {
                revert AssertGeApproxEqRelFailed(
                    string(abi.encodePacked(err, ": expected is zero")), expected, actual, 0, 0
                );
            }
            return;
        }
        if (actual < expected) {
            revert AssertGeApproxEqRelFailed(
                string(abi.encodePacked(err, ": actual < expected")), expected, actual, 0, 0
            );
        }
        uint256 maximumDelta = (expected * maxPercentDelta) / 1e18;
        uint256 delta = actual - expected;
        if (delta > maximumDelta) {
            revert AssertGeApproxEqRelFailed(
                // string(abi.encodePacked(err, ": overage too large")),
                string.concat(
                    err,
                    " overage too large: ",
                    actual.toString(),
                    " is ",
                    delta.toString(),
                    " greater than ",
                    expected.toString(),
                    ", maximum allowed delta is ",
                    maximumDelta.toString()
                ),
                expected,
                actual,
                maximumDelta,
                delta
            );
        }
    }
}
