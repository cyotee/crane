// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_BalancerV3_8020WeightedPool} from "@crane/contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3_8020WeightedPool.sol";
import {BalancerV38020WeightedPoolMath} from "@crane/contracts/protocols/dexes/balancer/v3/utils/BalancerV38020WeightedPoolMath.sol";

contract BalancerV38020WeightedPoolMath_Test is TestBase_BalancerV3_8020WeightedPool {

    function createPool() internal virtual override returns (address newPool, bytes memory poolArgs) {
        (newPool, poolArgs) = createDaiUsdc8020WeightedPool();
        return (newPool, poolArgs);
    }

    // function initPool() internal virtual override {
    //     initDaiUsdc8020WeightedPool();
    // }
    
    function test_calcBptOutGivenProportionalIn_Initial_Deposit() public {
        (,, uint256[] memory poolReserves,) = vault.getPoolTokenInfo(address(daiUsdc8020WeightedPool));
        uint256 bptTotalSupply = daiUsdc8020WeightedPool.totalSupply();

        // Calculate proportional amounts based on current reserves (e.g., 10% of each reserve)
        // uint256[] memory amountsIn = new uint256[](2);
        // amountsIn[daiIndexInDaiUsdc8020Pool] = poolReserves[daiIndexInDaiUsdc8020Pool] / 10;
        // amountsIn[usdcIndexInDaiUsdc8020Pool] = poolReserves[usdcIndexInDaiUsdc8020Pool] / 10;

        uint256[] memory weights = daiUsdc8020WeightedPool.getNormalizedWeights();

        uint256 estimatedBptOut =
            BalancerV38020WeightedPoolMath._calcBptOutGivenProportionalIn(poolReserves, weights, bptTotalSupply, daiUsdc8020WeightedPoolTokenAmounts);

        uint256 initialBptBal = daiUsdc8020WeightedPool.balanceOf(address(lp));

        vm.startPrank(lp);
        // Mint and approve tokens based on dynamic indices
        dai.mint(lp, daiUsdc8020WeightedPoolTokenAmounts[daiIndexInDaiUsdc8020Pool]);
        usdc.mint(lp, daiUsdc8020WeightedPoolTokenAmounts[usdcIndexInDaiUsdc8020Pool]);
        // dai.approve(address(router), daiUsdc8020WeightedPoolTokenAmounts[daiIndexInDaiUsdc8020Pool]);
        // usdc.approve(address(router), daiUsdc8020WeightedPoolTokenAmounts[usdcIndexInDaiUsdc8020Pool]);

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[daiIndexInDaiUsdc8020Pool] = daiUsdc8020WeightedPoolTokenAmounts[daiIndexInDaiUsdc8020Pool];
        maxAmountsIn[usdcIndexInDaiUsdc8020Pool] = daiUsdc8020WeightedPoolTokenAmounts[usdcIndexInDaiUsdc8020Pool];

        // Try the proportional add; if the library itself is wrong we will skip the test later
        // router.addLiquidityProportional(address(daiUsdc8020WeightedPool), maxAmountsIn, estimatedBptOut, false, "");
        _initPool(address(daiUsdc8020WeightedPool), daiUsdc8020WeightedPoolTokenAmounts, 0);
        vm.stopPrank();

        uint256 postBptBal = daiUsdc8020WeightedPool.balanceOf(address(lp));

        // Verify BPT minted matches estimate; if this check fails due to known library mismatch,
        // maintainers requested skipping such tests at runtime (use `vm.skip(true)` when appropriate).
        // For now assert exactness and allow test harness to be updated if a library bug is found.
        assertEq(
            postBptBal - initialBptBal,
            estimatedBptOut,
            "Actual BPT out should match estimated for proportional deposit"
        );
        assertEq(
            daiUsdc8020WeightedPool.balanceOf(lp),
            initialBptBal + estimatedBptOut,
            "BPT balance should increase by actualBptOut"
        );
    }

    function test_calcBptOutGivenProportionalIn_Second_Deposit() public {
        initDaiUsdc8020WeightedPool();
        (,, uint256[] memory poolReserves,) = vault.getPoolTokenInfo(address(daiUsdc8020WeightedPool));
        uint256 bptTotalSupply = daiUsdc8020WeightedPool.totalSupply();

        // Calculate proportional amounts based on current reserves (e.g., 10% of each reserve)
        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[daiIndexInDaiUsdc8020Pool] = poolReserves[daiIndexInDaiUsdc8020Pool] / 10;
        amountsIn[usdcIndexInDaiUsdc8020Pool] = poolReserves[usdcIndexInDaiUsdc8020Pool] / 10;

        uint256[] memory weights = daiUsdc8020WeightedPool.getNormalizedWeights();

        uint256 estimatedBptOut =
            BalancerV38020WeightedPoolMath._calcBptOutGivenProportionalIn(poolReserves, weights, bptTotalSupply, amountsIn);

        uint256 initialBptBal = daiUsdc8020WeightedPool.balanceOf(address(lp));

        vm.startPrank(lp);
        // Mint and approve tokens based on dynamic indices
        dai.mint(lp, amountsIn[daiIndexInDaiUsdc8020Pool]);
        usdc.mint(lp, amountsIn[usdcIndexInDaiUsdc8020Pool]);
        dai.approve(address(router), amountsIn[daiIndexInDaiUsdc8020Pool]);
        usdc.approve(address(router), amountsIn[usdcIndexInDaiUsdc8020Pool]);

        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[daiIndexInDaiUsdc8020Pool] = amountsIn[daiIndexInDaiUsdc8020Pool];
        maxAmountsIn[usdcIndexInDaiUsdc8020Pool] = amountsIn[usdcIndexInDaiUsdc8020Pool];

        // Try the proportional add; if the library itself is wrong we will skip the test later
        router.addLiquidityProportional(address(daiUsdc8020WeightedPool), maxAmountsIn, estimatedBptOut, false, "");
        vm.stopPrank();

        uint256 postBptBal = daiUsdc8020WeightedPool.balanceOf(address(lp));

        // Verify BPT minted matches estimate; if this check fails due to known library mismatch,
        // maintainers requested skipping such tests at runtime (use `vm.skip(true)` when appropriate).
        // For now assert exactness and allow test harness to be updated if a library bug is found.
        assertEq(
            postBptBal - initialBptBal,
            estimatedBptOut,
            "Actual BPT out should match estimated for proportional deposit"
        );
        assertEq(
            daiUsdc8020WeightedPool.balanceOf(lp),
            initialBptBal + estimatedBptOut,
            "BPT balance should increase by actualBptOut"
        );
    }

    function test_calcProportionalAmountsOutGivenBptIn() public {
        initDaiUsdc8020WeightedPool();
        uint256 bptBal = daiUsdc8020WeightedPool.balanceOf(address(lp));
        uint256 bptIn = bptBal / 10; // Burn 10% of LP's BPT balance

        (,, uint256[] memory poolReserves,) = vault.getPoolTokenInfo(address(daiUsdc8020WeightedPool));
        uint256 bptTotalSupply = daiUsdc8020WeightedPool.totalSupply();

        uint256[] memory estimatedAmountsOut =
            BalancerV38020WeightedPoolMath._calcProportionalAmountsOutGivenBptIn(poolReserves, bptTotalSupply, bptIn);

        uint256 initialDaiBal = dai.balanceOf(lp);
        uint256 initialUsdcBal = usdc.balanceOf(lp);
        uint256 initialBptBal = daiUsdc8020WeightedPool.balanceOf(lp);

        vm.startPrank(lp);
        daiUsdc8020WeightedPool.approve(address(router), bptIn);
        uint256[] memory actualAmountsOut =
            router.removeLiquidityProportional(address(daiUsdc8020WeightedPool), bptIn, estimatedAmountsOut, false, "");
        vm.stopPrank();

        assertEq(
            actualAmountsOut[daiIndexInDaiUsdc8020Pool],
            estimatedAmountsOut[daiIndexInDaiUsdc8020Pool],
            "Actual DAI out should match estimated"
        );
        assertEq(
            actualAmountsOut[usdcIndexInDaiUsdc8020Pool],
            estimatedAmountsOut[usdcIndexInDaiUsdc8020Pool],
            "Actual USDC out should match estimated"
        );
        assertEq(
            dai.balanceOf(lp),
            initialDaiBal + actualAmountsOut[daiIndexInDaiUsdc8020Pool],
            "DAI balance should increase"
        );
        assertEq(
            usdc.balanceOf(lp),
            initialUsdcBal + actualAmountsOut[usdcIndexInDaiUsdc8020Pool],
            "USDC balance should increase"
        );
        assertEq(daiUsdc8020WeightedPool.balanceOf(lp), initialBptBal - bptIn, "BPT balance should decrease by bptIn");
    }

    function test_calcEquivalentProportionalGivenSingle() public {
        initDaiUsdc8020WeightedPool();
        (,, uint256[] memory poolReserves,) = vault.getPoolTokenInfo(address(daiUsdc8020WeightedPool));
        uint256[] memory normalizedWeights = daiUsdc8020WeightedPool.getNormalizedWeights();
        uint256 bptTotalSupply = daiUsdc8020WeightedPool.totalSupply();

        uint256 tokenIndex = daiIndexInDaiUsdc8020Pool;
        uint256 amountIn = 100e18;

        // Use the helper that also returns expected BPT out for the deposit
        (uint256 otherAmount, uint256 expectedBptOut) = BalancerV38020WeightedPoolMath._calcEquivalentProportionalGivenSingleAndBPTOut(
            poolReserves, normalizedWeights, bptTotalSupply, tokenIndex, amountIn
        );

        uint256 initialBptBal = daiUsdc8020WeightedPool.balanceOf(address(lp));

        vm.startPrank(lp);
        uint256[] memory maxAmountsIn = new uint256[](2);
        maxAmountsIn[tokenIndex] = amountIn;
        maxAmountsIn[1 - tokenIndex] = otherAmount;

        // Mint and approve tokens based on dynamic indices
        dai.mint(lp, maxAmountsIn[daiIndexInDaiUsdc8020Pool]);
        usdc.mint(lp, maxAmountsIn[usdcIndexInDaiUsdc8020Pool]);
        dai.approve(address(router), maxAmountsIn[daiIndexInDaiUsdc8020Pool]);
        usdc.approve(address(router), maxAmountsIn[usdcIndexInDaiUsdc8020Pool]);

        uint256[] memory actualAmountsIn =
            router.addLiquidityProportional(address(daiUsdc8020WeightedPool), maxAmountsIn, expectedBptOut, false, "");
        vm.stopPrank();

        uint256 actualBptOut = daiUsdc8020WeightedPool.balanceOf(lp) - initialBptBal;
        assertEq(actualBptOut, expectedBptOut, "Actual BPT out should match expected");
        assertEq(
            actualAmountsIn[daiIndexInDaiUsdc8020Pool],
            maxAmountsIn[daiIndexInDaiUsdc8020Pool],
            "Actual DAI in should match expected"
        );
        assertEq(
            actualAmountsIn[usdcIndexInDaiUsdc8020Pool],
            maxAmountsIn[usdcIndexInDaiUsdc8020Pool],
            "Actual USDC in should match expected"
        );
    }

    function test_calcBptOutGivenSingleIn() public {
        initDaiUsdc8020WeightedPool();
        (,, uint256[] memory poolReserves,) = vault.getPoolTokenInfo(address(daiUsdc8020WeightedPool));
        uint256[] memory normalizedWeights = daiUsdc8020WeightedPool.getNormalizedWeights();
        uint256 daiAmtIn = 100e18;
        uint256 estimatedBptOut = BalancerV38020WeightedPoolMath._calcBptOutGivenSingleIn(
            poolReserves,
            normalizedWeights,
            daiIndexInDaiUsdc8020Pool,
            daiAmtIn,
            daiUsdc8020WeightedPool.totalSupply(),
            vault.getStaticSwapFeePercentage(address(daiUsdc8020WeightedPool))
        );
        uint256 initialDaiUsdcBptBal = daiUsdc8020WeightedPool.balanceOf(address(lp));
        vm.startPrank(lp);
        dai.mint(lp, daiAmtIn);
        dai.approve(address(router), daiAmtIn); // Approve Router
        uint256[] memory exactAmountsIn = new uint256[](2);
        exactAmountsIn[daiIndexInDaiUsdc8020Pool] = daiAmtIn;
        uint256 actualBptOut =
            router.addLiquidityUnbalanced(address(daiUsdc8020WeightedPool), exactAmountsIn, estimatedBptOut, false, "");
        vm.stopPrank();
        assertEq(actualBptOut, estimatedBptOut, "Actual BPT out should be equal to expected BPT out");
        assertEq(
            daiUsdc8020WeightedPool.balanceOf(lp),
            initialDaiUsdcBptBal + actualBptOut,
            "LP DAI USDC BPT balance should be equal to initial plus BPT out"
        );
    }

    /**
     * @dev Test the calcSingleOutGivenBptIn function.
     */
    function test_calcSingleOutGivenBptIn() public {
        initDaiUsdc8020WeightedPool();
        uint256 weightedLPBal = daiUsdc8020WeightedPool.balanceOf(address(lp));
        uint256 lpBurnAmt = weightedLPBal / 8;
        (,, uint256[] memory poolReserves,) = vault.getPoolTokenInfo(address(daiUsdc8020WeightedPool));
        uint256[] memory normalizedWeights = daiUsdc8020WeightedPool.getNormalizedWeights();
        uint256 estimatedDaiOut = BalancerV38020WeightedPoolMath._calcSingleOutGivenBptIn(
            poolReserves,
            normalizedWeights,
            daiIndexInDaiUsdc8020Pool,
            lpBurnAmt,
            daiUsdc8020WeightedPool.totalSupply(),
            vault.getStaticSwapFeePercentage(address(daiUsdc8020WeightedPool))
        );
        uint256 daiInitialBal = dai.balanceOf(lp);

        vm.startPrank(lp);

        uint256 actualDaiOut = router.removeLiquiditySingleTokenExactIn(
            // address pool,
            address(daiUsdc8020WeightedPool),
            // uint256 exactBptAmountIn,
            lpBurnAmt,
            // IERC20 tokenOut,
            dai,
            // uint256 minAmountOut,
            1,
            // bool wethIsEth,
            false,
            // bytes memory userData
            ""
        );

        vm.stopPrank();

        // 122752430377245679462
        // 121752430377245681112
        assertEq(actualDaiOut, estimatedDaiOut, "Actual DAI out should be equal to expected DAI out");
        assertEq(
            dai.balanceOf(lp),
            daiInitialBal + actualDaiOut,
            "LP DAI balance should be equal to initial DAI balance minus actual DAI out"
        );
    }

    /// @notice Synthetic unit test for price/delta helpers (does not touch on-chain pools)
    function test_price_and_delta_helpers_synthetic() public pure {
        // initDaiUsdc8020WeightedPool();
        // balances: token0 = 100, token1 = 200 (18 decimals)
        uint256 token0Balance = 100e18;
        uint256 token1Balance = 200e18;
        uint8 token0Decimals = 18;
        uint8 token1Decimals = 18;
        uint256 token0Weight = 80e16; // 0.8
        uint256 token1Weight = 20e16; // 0.2

        uint256 spotPrice = BalancerV38020WeightedPoolMath._priceFromReserves(
            token0Balance, token0Decimals, token1Balance, token1Decimals, token0Weight, token1Weight
        );
        // expected 0.125 * 1e18
        assertEq(spotPrice, 125e15);

        uint256 targetPrice = spotPrice * 2; // double the price
        // Use consolidated helper (tokenIndex = 0)
        uint256 deltaToken0 = BalancerV38020WeightedPoolMath._deltaTokenToReachTarget(
            token0Balance, token0Decimals, token1Balance, token1Decimals, token0Weight, token1Weight, targetPrice, 0
        );
        assertTrue(deltaToken0 > 0, "deltaToken0 should be positive when target > current");

        uint256 newSpotPrice = BalancerV38020WeightedPoolMath._priceFromReserves(
            token0Balance + deltaToken0, token0Decimals, token1Balance, token1Decimals, token0Weight, token1Weight
        );
        // allow tiny rounding tolerance
        assertTrue(
            newSpotPrice >= targetPrice - 1 && newSpotPrice <= targetPrice + 1,
            "newSpotPrice approximately equals target"
        );

        // Now test the other orientation: compute token1 delta to halve the price (tokenIndex = 1)
        uint256 targetPrice2 = spotPrice / 2;
        uint256 deltaToken1 = BalancerV38020WeightedPoolMath._deltaTokenToReachTarget(
            token0Balance, token0Decimals, token1Balance, token1Decimals, token0Weight, token1Weight, targetPrice2, 1
        );
        assertTrue(deltaToken1 > 0, "deltaToken1 should be positive when target < current");
        uint256 newSpotPrice2 = BalancerV38020WeightedPoolMath._priceFromReserves(
            token0Balance, token0Decimals, token1Balance + deltaToken1, token1Decimals, token0Weight, token1Weight
        );
        assertTrue(
            newSpotPrice2 >= targetPrice2 - 1 && newSpotPrice2 <= targetPrice2 + 1,
            "newSpotPrice2 approximately equals target"
        );
    }

    /// @notice Integration test: calculate expected spot price after adding unbalanced liquidity,
    /// then perform an unbalanced add and assert the actual pool reserves produce the expected price.
    function test_virtualPrice_after_unbalanced_add() public {
        initDaiUsdc8020WeightedPool();
        // Get current pool reserves
        (,, uint256[] memory poolReserves,) = vault.getPoolTokenInfo(address(daiUsdc8020WeightedPool));
        uint256 reserveToken0 = poolReserves[daiIndexInDaiUsdc8020Pool];
        uint256 reserveToken1 = poolReserves[usdcIndexInDaiUsdc8020Pool];

        // Token decimals and weights
        uint8 decimalsToken0 = dai.decimals();
        uint8 decimalsToken1 = usdc.decimals();
        uint256[] memory normalizedWeights = daiUsdc8020WeightedPool.getNormalizedWeights();
        uint256 weightToken0 = normalizedWeights[daiIndexInDaiUsdc8020Pool];
        uint256 weightToken1 = normalizedWeights[usdcIndexInDaiUsdc8020Pool];

        // Choose an amount to add to token0 (DAI) as unbalanced liquidity
        uint256 amountIn = 50e18; // 50 DAI

        // Expected price after naive addition (ignoring fees) using library
        uint256 expectedPrice = BalancerV38020WeightedPoolMath._priceFromReserves(
            reserveToken0 + amountIn, decimalsToken0, reserveToken1, decimalsToken1, weightToken0, weightToken1
        );

        // Mint and approve tokens to LP and perform unbalanced add via Router
        vm.startPrank(lp);
        dai.mint(lp, amountIn);
        dai.approve(address(router), amountIn);
        uint256[] memory exactAmountsIn = new uint256[](2);
        exactAmountsIn[daiIndexInDaiUsdc8020Pool] = amountIn;

        // Use minBptOut = 1 to avoid revert from zero, wethIsEth = false, empty userData
        router.addLiquidityUnbalanced(address(daiUsdc8020WeightedPool), exactAmountsIn, 1, false, "");
        vm.stopPrank();

        // Read new reserves and compute actual price
        (,, uint256[] memory newReserves,) = vault.getPoolTokenInfo(address(daiUsdc8020WeightedPool));
        uint256 newReserveToken0 = newReserves[daiIndexInDaiUsdc8020Pool];
        uint256 newReserveToken1 = newReserves[usdcIndexInDaiUsdc8020Pool];

        uint256 actualPrice = BalancerV38020WeightedPoolMath._priceFromReserves(
            newReserveToken0, decimalsToken0, newReserveToken1, decimalsToken1, weightToken0, weightToken1
        );

        // Allow for tiny rounding differences; assert near-equality
        uint256 TOL = 1e12; // ~0.000001 relative tolerance on 1e18
        // assertApproxEqAbs(actualPrice, expectedPrice, TOL, "Actual price should match expected within tolerance");
        assertEq(actualPrice, expectedPrice, "Actual price should match expected within tolerance");
    }

    /// @notice Integration test for deltaTokenToReachTarget (tokenIndex=1): compute required USDC addition to reach a lower target price,
    /// perform the unbalanced add and assert the pool price reaches the target.
    function test_deltaToken1_after_unbalanced_add() public {
        initDaiUsdc8020WeightedPool();
        // Get current pool reserves
        (,, uint256[] memory poolReserves,) = vault.getPoolTokenInfo(address(daiUsdc8020WeightedPool));
        uint256 reserveToken0 = poolReserves[daiIndexInDaiUsdc8020Pool];
        uint256 reserveToken1 = poolReserves[usdcIndexInDaiUsdc8020Pool];

        // Token decimals and weights
        uint8 decimalsToken0 = dai.decimals();
        uint8 decimalsToken1 = usdc.decimals();
        uint256[] memory normalizedWeights = daiUsdc8020WeightedPool.getNormalizedWeights();
        uint256 weightToken0 = normalizedWeights[daiIndexInDaiUsdc8020Pool];
        uint256 weightToken1 = normalizedWeights[usdcIndexInDaiUsdc8020Pool];

        // Current spot price
        uint256 currentPrice = BalancerV38020WeightedPoolMath._priceFromReserves(
            reserveToken0, decimalsToken0, reserveToken1, decimalsToken1, weightToken0, weightToken1
        );

        // Target: halve the price
        uint256 targetPrice = currentPrice / 2;

        // Compute delta for token1 (USDC) required to reach target (should be > 0)
        uint256 deltaToken1 = BalancerV38020WeightedPoolMath._deltaTokenToReachTarget(
            reserveToken0, decimalsToken0, reserveToken1, decimalsToken1, weightToken0, weightToken1, targetPrice, 1
        );
        assertTrue(deltaToken1 > 0, "deltaToken1 should be positive when target < current");

        // Mint and approve token1 to LP and perform unbalanced add via Router
        vm.startPrank(lp);
        usdc.mint(lp, deltaToken1);
        usdc.approve(address(router), deltaToken1);
        uint256[] memory exactAmountsIn = new uint256[](2);
        exactAmountsIn[usdcIndexInDaiUsdc8020Pool] = deltaToken1;
        router.addLiquidityUnbalanced(address(daiUsdc8020WeightedPool), exactAmountsIn, 1, false, "");
        vm.stopPrank();

        // Read new reserves and compute actual price
        (,, uint256[] memory newReserves,) = vault.getPoolTokenInfo(address(daiUsdc8020WeightedPool));
        uint256 newReserveToken0 = newReserves[daiIndexInDaiUsdc8020Pool];
        uint256 newReserveToken1 = newReserves[usdcIndexInDaiUsdc8020Pool];

        uint256 actualPrice = BalancerV38020WeightedPoolMath._priceFromReserves(
            newReserveToken0, decimalsToken0, newReserveToken1, decimalsToken1, weightToken0, weightToken1
        );

        // uint256 TOL = 1e12;
        // assertApproxEqAbs(actualPrice, targetPrice, TOL, "Actual price should be approx target after adding USDC");
        assertEq(actualPrice, targetPrice, "Actual price should be approx target after adding USDC");
    }

    /// @notice Integration test symmetric to `test_deltaToken1_after_unbalanced_add` — add DAI to reach higher price
    function test_deltaToken0_after_unbalanced_add() public {
        initDaiUsdc8020WeightedPool();
        // Get current pool reserves
        (,, uint256[] memory poolReserves,) = vault.getPoolTokenInfo(address(daiUsdc8020WeightedPool));
        uint256 reserveToken0 = poolReserves[daiIndexInDaiUsdc8020Pool];
        uint256 reserveToken1 = poolReserves[usdcIndexInDaiUsdc8020Pool];

        // Token decimals and weights
        uint8 decimalsToken0 = dai.decimals();
        uint8 decimalsToken1 = usdc.decimals();
        uint256[] memory normalizedWeights = daiUsdc8020WeightedPool.getNormalizedWeights();
        uint256 weightToken0 = normalizedWeights[daiIndexInDaiUsdc8020Pool];
        uint256 weightToken1 = normalizedWeights[usdcIndexInDaiUsdc8020Pool];

        // Current spot price
        uint256 currentPrice = BalancerV38020WeightedPoolMath._priceFromReserves(
            reserveToken0, decimalsToken0, reserveToken1, decimalsToken1, weightToken0, weightToken1
        );

        // Target: double the price
        uint256 targetPrice = currentPrice * 2;

        // Compute delta for token0 (DAI) required to reach target
        uint256 deltaToken0 = BalancerV38020WeightedPoolMath._deltaTokenToReachTarget(
            reserveToken0, decimalsToken0, reserveToken1, decimalsToken1, weightToken0, weightToken1, targetPrice, 0
        );
        assertTrue(deltaToken0 > 0, "deltaToken0 should be positive when target > current");

        // Mint and approve token0 to LP and perform unbalanced add via Router
        vm.startPrank(lp);
        dai.mint(lp, deltaToken0);
        dai.approve(address(router), deltaToken0);
        uint256[] memory exactAmountsIn = new uint256[](2);
        exactAmountsIn[daiIndexInDaiUsdc8020Pool] = deltaToken0;
        router.addLiquidityUnbalanced(address(daiUsdc8020WeightedPool), exactAmountsIn, 1, false, "");
        vm.stopPrank();

        // Read new reserves and compute actual price
        (,, uint256[] memory newReserves,) = vault.getPoolTokenInfo(address(daiUsdc8020WeightedPool));
        uint256 newReserveToken0 = newReserves[daiIndexInDaiUsdc8020Pool];
        uint256 newReserveToken1 = newReserves[usdcIndexInDaiUsdc8020Pool];

        uint256 actualPrice = BalancerV38020WeightedPoolMath._priceFromReserves(
            newReserveToken0, decimalsToken0, newReserveToken1, decimalsToken1, weightToken0, weightToken1
        );

        uint256 TOL = 1e12;
        // assertApproxEqAbs(actualPrice, targetPrice, TOL, "Actual price should be approx target after adding DAI");
        assertEq(actualPrice, targetPrice, "Actual price should be approx target after adding DAI");
    }

}