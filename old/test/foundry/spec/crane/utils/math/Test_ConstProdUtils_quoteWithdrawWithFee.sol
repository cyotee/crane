// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import "test/foundry/spec/crane/utils/math/TestBase_ConstProdUtils.sol";
import "contracts/crane/utils/math/ConstProdUtils.sol";

contract Test_ConstProdUtils_quoteWithdrawWithFee is TestBase_ConstProdUtils {
    // Test amounts for withdrawal testing
    uint256 constant TEST_LP_AMOUNT_SMALL = 1000; // 1000 wei
    uint256 constant TEST_LP_AMOUNT_MEDIUM = 1000000; // 1M wei
    uint256 constant TEST_LP_AMOUNT_LARGE = 1000000000; // 1B wei

    function setUp() public override {
        super.setUp();
        console.log("Test_ConstProdUtils_quoteWithdrawWithFee setup complete");
    }

    // ============================================================================
    // UNISWAP V2 TESTS - FEES DISABLED (3 tests)
    // ============================================================================

    function test_quoteWithdrawWithFee_Uniswap_balancedPool_feesDisabled() public {
        console.log("=== Testing Uniswap V2: balancedPool_feesDisabled ===");
        _testWithdrawWithFee(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, false);
        console.log("Uniswap balanced pool fees disabled test passed");
    }

    function test_quoteWithdrawWithFee_Uniswap_unbalancedPool_feesDisabled() public {
        console.log("=== Testing Uniswap V2: unbalancedPool_feesDisabled ===");
        _testWithdrawWithFee(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB, false);
        console.log("Uniswap unbalanced pool fees disabled test passed");
    }

    function test_quoteWithdrawWithFee_Uniswap_extremeUnbalancedPool_feesDisabled() public {
        console.log("=== Testing Uniswap V2: extremeUnbalancedPool_feesDisabled ===");
        _testWithdrawWithFee(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB, false);
        console.log("Uniswap extreme unbalanced pool fees disabled test passed");
    }

    // ============================================================================
    // UNISWAP V2 TESTS - FEES ENABLED (3 tests)
    // ============================================================================

    function test_quoteWithdrawWithFee_Uniswap_balancedPool_feesEnabled() public {
        console.log("=== Testing Uniswap V2: balancedPool_feesEnabled ===");
        _testWithdrawWithFee(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, true);
        console.log("Uniswap balanced pool fees enabled test passed");
    }

    function test_quoteWithdrawWithFee_Uniswap_unbalancedPool_feesEnabled() public {
        console.log("=== Testing Uniswap V2: unbalancedPool_feesEnabled ===");
        _testWithdrawWithFee(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB, true);
        console.log("Uniswap unbalanced pool fees enabled test passed");
    }

    function test_quoteWithdrawWithFee_Uniswap_extremeUnbalancedPool_feesEnabled() public {
        console.log("=== Testing Uniswap V2: extremeUnbalancedPool_feesEnabled ===");
        _testWithdrawWithFee(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB, true);
        console.log("Uniswap extreme unbalanced pool fees enabled test passed");
    }

    // ============================================================================
    // HELPER FUNCTIONS
    // ============================================================================

    struct WithdrawTestData {
        uint256 balanceBeforeA;
        uint256 balanceBeforeB;
        uint256 lpBalanceBefore;
        uint256 lpBalanceAfter;
        uint256 lpTokensReceived;
        uint112 newReserve0;
        uint112 newReserve1;
        uint256 newTotalSupply;
        uint256 newKLast;
        uint256 reserveA;
        uint256 reserveB;
        uint256 amountA;
        uint256 amountB;
        uint256 balanceAfterA;
        uint256 balanceAfterB;
        uint256 actualAmountA;
        uint256 actualAmountB;
    }

    function _testWithdrawWithFee(IUniswapV2Pair pair, IERC20MintBurn tokenA, IERC20MintBurn tokenB, bool feesEnabled)
        internal
    {
        // Setup fees
        _setupUniswapFees(feesEnabled);

        // Initialize test data struct
        WithdrawTestData memory data;

        // Get LP tokens by adding liquidity first (no fees yet)
        data.balanceBeforeA = tokenA.balanceOf(address(this));
        data.balanceBeforeB = tokenB.balanceOf(address(this));
        data.lpBalanceBefore = pair.balanceOf(address(this));

        // Mint tokens and add liquidity to get LP tokens
        tokenA.mint(address(this), TEST_LP_AMOUNT_MEDIUM);
        tokenB.mint(address(this), TEST_LP_AMOUNT_MEDIUM);
        tokenA.approve(address(uniswapV2Router()), TEST_LP_AMOUNT_MEDIUM);
        tokenB.approve(address(uniswapV2Router()), TEST_LP_AMOUNT_MEDIUM);

        uniswapV2Router()
            .addLiquidity(
                address(tokenA),
                address(tokenB),
                TEST_LP_AMOUNT_MEDIUM,
                TEST_LP_AMOUNT_MEDIUM,
                1, // minAmountA
                1, // minAmountB
                address(this),
                block.timestamp
            );

        data.lpBalanceAfter = pair.balanceOf(address(this));
        data.lpTokensReceived = data.lpBalanceAfter - data.lpBalanceBefore;

        console.log("LP tokens received from initial liquidity:", data.lpTokensReceived);

        // Generate trading activity AFTER adding liquidity if fees are enabled
        if (feesEnabled) {
            _generateTradingActivity(pair, tokenA, tokenB, 100); // 1% trading
        }

        // Get updated pool state after trading (if any)
        (data.newReserve0, data.newReserve1,) = pair.getReserves();
        data.newTotalSupply = pair.totalSupply();
        data.newKLast = pair.kLast();

        console.log("Pool state after trading - reserve0:", data.newReserve0, "reserve1:", data.newReserve1);
        console.log("Pool state after trading - totalSupply:", data.newTotalSupply, "kLast:", data.newKLast);

        // Sort reserves to match tokenA/tokenB order
        (data.reserveA, data.reserveB) = ConstProdUtils._sortReserves(
            address(tokenA), // knownToken
            pair.token0(), // token0
            data.newReserve0, // reserve0
            data.newReserve1 // reserve1
        );

        console.log("Sorted reserves - reserveA:", data.reserveA, "reserveB:", data.reserveB);

        // Test the quote function with updated state and actual LP amount
        (data.amountA, data.amountB) = ConstProdUtils._quoteWithdrawWithFee(
            data.lpTokensReceived, // ownedLPAmount (actual LP tokens received)
            data.newTotalSupply, // lpTotalSupply (updated supply)
            data.reserveA, // totalReserveA (sorted reserves)
            data.reserveB, // totalReserveB (sorted reserves)
            data.newKLast, // kLast (updated kLast)
            16666, // ownerFeeShare (1/6 for Uniswap V2)
            feesEnabled // feeOn
        );

        console.log("Quote result - amountA:", data.amountA, "amountB:", data.amountB);

        // Get balances before withdrawal
        uint256 balanceBeforeWithdrawalA = tokenA.balanceOf(address(this));
        uint256 balanceBeforeWithdrawalB = tokenB.balanceOf(address(this));

        // Execute withdrawal via router
        pair.transfer(address(pair), data.lpTokensReceived);
        pair.burn(address(this));

        data.balanceAfterA = tokenA.balanceOf(address(this));
        data.balanceAfterB = tokenB.balanceOf(address(this));

        data.actualAmountA = data.balanceAfterA - balanceBeforeWithdrawalA;
        data.actualAmountB = data.balanceAfterB - balanceBeforeWithdrawalB;

        console.log("Actual amounts - amountA:", data.actualAmountA, "amountB:", data.actualAmountB);

        // Validate that quote matches execution exactly
        assertTrue(data.amountA > 0, "Quoted amountA should be positive");
        assertTrue(data.amountB > 0, "Quoted amountB should be positive");
        assertTrue(data.actualAmountA > 0, "Actual amountA should be positive");
        assertTrue(data.actualAmountB > 0, "Actual amountB should be positive");
        assertEq(data.amountA, data.actualAmountA, "Quote should exactly match actual amountA");
        assertEq(data.amountB, data.actualAmountB, "Quote should exactly match actual amountB");
    }

    function _setupUniswapFees(bool enableProtocolFees) internal {
        address factoryOwner = uniswapV2Factory().feeToSetter();

        if (enableProtocolFees) {
            // Enable protocol fees
            vm.prank(factoryOwner);
            uniswapV2Factory().setFeeTo(address(0x123));
        } else {
            // Disable protocol fees
            vm.prank(factoryOwner);
            uniswapV2Factory().setFeeTo(address(0));
        }
    }

    function _generateTradingActivity(
        IUniswapV2Pair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 swapPercentage // e.g., 100 = 1%, 500 = 5%
    ) internal {
        console.log("Generating Uniswap trading activity:");

        // Get current reserves
        (uint112 reserveA, uint112 reserveB,) = pair.getReserves();
        console.log("  ReserveA:", reserveA, "ReserveB:", reserveB);
        console.log("  SwapPercentage:", swapPercentage);

        // Calculate swap amounts as percentage of reserves
        uint256 swapAmountA = (reserveA * swapPercentage) / 10000; // 10000 = 100%
        uint256 swapAmountB = (reserveB * swapPercentage) / 10000;
        console.log("  SwapAmountA:", swapAmountA, "SwapAmountB:", swapAmountB);

        // Mint tokens
        tokenA.mint(address(this), swapAmountA);
        tokenB.mint(address(this), swapAmountB);

        tokenA.approve(address(uniswapV2Router()), swapAmountA);
        tokenB.approve(address(uniswapV2Router()), swapAmountB);

        // First swap: A -> B
        address[] memory pathAB = new address[](2);
        pathAB[0] = address(tokenA);
        pathAB[1] = address(tokenB);

        uint256[] memory amountsAB = uniswapV2Router()
            .swapExactTokensForTokens(
                swapAmountA,
                1, // minAmountOut
                pathAB,
                address(this),
                block.timestamp
            );

        console.log("  First swap A->B: swapped", swapAmountA, "received", amountsAB[1]);

        // Second swap: B -> A (using what we actually received)
        uint256 receivedB = amountsAB[1];
        tokenB.approve(address(uniswapV2Router()), receivedB);

        address[] memory pathBA = new address[](2);
        pathBA[0] = address(tokenB);
        pathBA[1] = address(tokenA);

        uint256[] memory amountsBA = uniswapV2Router()
            .swapExactTokensForTokens(
                receivedB,
                1, // minAmountOut
                pathBA,
                address(this),
                block.timestamp
            );

        console.log("  Second swap B->A: swapped", receivedB, "received", amountsBA[1]);
        console.log("  Uniswap trading activity complete");
    }
}
