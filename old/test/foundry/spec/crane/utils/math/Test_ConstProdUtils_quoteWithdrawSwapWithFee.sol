// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";

using ConstProdUtils for uint256;

import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {FEE_DENOMINATOR} from "@crane/src/constants/Constants.sol";

import {IERC20MintBurn} from "contracts/crane/interfaces/IERC20MintBurn.sol";
import {IUniswapV2Pair} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

contract Test_ConstProdUtils_quoteWithdrawSwapWithFee is TestBase_ConstProdUtils {
    using ConstProdUtils for uint256;

    // Test percentages for LP token withdrawal
    uint256 constant LOW_PERCENTAGE = 10; // 10%
    uint256 constant MEDIUM_PERCENTAGE = 50; // 50%
    uint256 constant HIGH_PERCENTAGE = 90; // 90%

    // Test fee percentages - using same as reference test
    uint256 constant UNISWAP_FEE_PERCENT = 300; // 0.3% fee (300/100000) - same as reference test
    uint256 constant UNISWAP_OWNER_FEE_SHARE = 16666; // 1/6 for Uniswap V2 - same as reference test

    // Helper function to calculate percentage of LP tokens
    function _calculateLPAmount(uint256 totalLP, uint256 percentage) internal pure returns (uint256) {
        return (totalLP * percentage) / 100;
    }

    // Helper function to get kLast from a pool
    function _getKLast(address pool) internal view returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        return pair.kLast();
    }

    // Helper function to get pool reserves and determine which token is which
    function _getPoolReserves(address pool)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB, address tokenA, address tokenB)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        address token0 = pair.token0();
        address token1 = pair.token1();
        return (reserve0, reserve1, token0, token1);
    }

    // Struct to hold withdrawal swap data
    struct WithdrawSwapData {
        IUniswapV2Pair pair;
        IUniswapV2Router router;
        uint256 reserveA;
        uint256 reserveB;
        address tokenA;
        address tokenB;
        uint256 totalSupply;
        uint256 tokenAAmount;
        uint256 tokenBAmount;
        uint256 actualTokenA;
        uint256 actualTokenB;
        uint256 remainingReserveA;
        uint256 remainingReserveB;
        uint256 swapAmount;
        address[] path;
        uint256[] amounts;
        uint256 lpAmount;
        uint256 kLast;
        uint256 ownerFeeShare;
        uint256 quote;
        uint256 actualAmount;
    }

    // Helper function to perform actual withdrawal and swap for validation
    function _performActualWithdrawSwap(address pool, uint256 lpAmount, uint256 feePercent)
        internal
        returns (uint256 actualTokenAAmount)
    {
        WithdrawSwapData memory data;
        data.pair = IUniswapV2Pair(pool);
        data.router = IUniswapV2Router(uniswapV2Router());

        // Get current reserves
        (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(pool);

        // Calculate expected withdrawal amounts
        data.totalSupply = data.pair.totalSupply();
        data.tokenAAmount = (data.reserveA * lpAmount) / data.totalSupply;
        data.tokenBAmount = (data.reserveB * lpAmount) / data.totalSupply;

        // Snapshot balances, then withdraw LP tokens to get both tokens
        uint256 balABefore = IERC20MintBurn(data.tokenA).balanceOf(address(this));
        uint256 balBBefore = IERC20MintBurn(data.tokenB).balanceOf(address(this));
        data.pair.transfer(pool, lpAmount);
        data.pair.burn(address(this));

        // Compute withdrawn amounts (exclude any pre-existing balances from fee-gen trades)
        uint256 balAAfter = IERC20MintBurn(data.tokenA).balanceOf(address(this));
        uint256 balBAfter = IERC20MintBurn(data.tokenB).balanceOf(address(this));
        data.actualTokenA = balAAfter - balABefore;
        data.actualTokenB = balBAfter - balBBefore;

        // Swap tokenB for tokenA
        if (data.actualTokenB > 0) {
            // Approve router to spend only withdrawn tokenB
            IERC20MintBurn(data.tokenB).approve(address(data.router), data.actualTokenB);

            // Calculate expected swap amount using the same logic as the function
            data.remainingReserveA = data.reserveA - data.tokenAAmount;
            data.remainingReserveB = data.reserveB - data.tokenBAmount;

            // Apply fee if enabled
            if (feePercent > 0) {
                data.remainingReserveA = data.remainingReserveA * (FEE_DENOMINATOR - feePercent) / FEE_DENOMINATOR;
            }

            // Calculate swap amount
            data.swapAmount =
                (data.actualTokenB * data.remainingReserveA) / (data.remainingReserveB + data.actualTokenB);

            // Perform swap
            data.path = new address[](2);
            data.path[0] = data.tokenB;
            data.path[1] = data.tokenA;

            data.amounts = data.router
                .swapExactTokensForTokens(
                    data.actualTokenB,
                    0, // Accept any amount of tokenA
                    data.path,
                    address(this),
                    block.timestamp + 300
                );

            actualTokenAAmount = data.actualTokenA + data.amounts[1];
        } else {
            actualTokenAAmount = data.actualTokenA;
        }
    }

    /**
     * @dev Performs actual withdrawal and swap for Token B extraction validation
     * @param pool The pool address
     * @param lpAmount The amount of LP tokens to burn
     * @param feePercent The swap fee percentage
     * @return actualTokenBAmount The actual amount of Token B received
     */
    function _performActualWithdrawSwapTokenB(address pool, uint256 lpAmount, uint256 feePercent)
        internal
        returns (uint256 actualTokenBAmount)
    {
        WithdrawSwapData memory data;
        data.pair = IUniswapV2Pair(pool);
        data.router = IUniswapV2Router(uniswapV2Router());

        // Get current reserves
        (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(pool);

        // Calculate expected withdrawal amounts
        data.totalSupply = data.pair.totalSupply();
        data.tokenAAmount = (data.reserveA * lpAmount) / data.totalSupply;
        data.tokenBAmount = (data.reserveB * lpAmount) / data.totalSupply;

        // Snapshot balances, then withdraw LP tokens to get both tokens
        uint256 balABefore = IERC20MintBurn(data.tokenA).balanceOf(address(this));
        uint256 balBBefore = IERC20MintBurn(data.tokenB).balanceOf(address(this));
        data.pair.transfer(pool, lpAmount);
        data.pair.burn(address(this));

        // Compute withdrawn amounts (exclude any pre-existing balances from fee-gen trades)
        uint256 balAAfter = IERC20MintBurn(data.tokenA).balanceOf(address(this));
        uint256 balBAfter = IERC20MintBurn(data.tokenB).balanceOf(address(this));
        data.actualTokenA = balAAfter - balABefore;
        data.actualTokenB = balBAfter - balBBefore;

        // Swap tokenA for tokenB
        if (data.actualTokenA > 0) {
            // Approve router to spend only withdrawn tokenA
            IERC20MintBurn(data.tokenA).approve(address(data.router), data.actualTokenA);

            // Calculate expected swap amount using the same logic as the function
            data.remainingReserveA = data.reserveA - data.tokenAAmount;
            data.remainingReserveB = data.reserveB - data.tokenBAmount;

            // Apply fee if enabled
            if (feePercent > 0) {
                data.remainingReserveB = data.remainingReserveB * (FEE_DENOMINATOR - feePercent) / FEE_DENOMINATOR;
            }

            // Calculate swap amount
            data.swapAmount =
                (data.actualTokenA * data.remainingReserveB) / (data.remainingReserveA + data.actualTokenA);

            // Perform swap
            data.path = new address[](2);
            data.path[0] = data.tokenA;
            data.path[1] = data.tokenB;

            data.amounts = data.router
                .swapExactTokensForTokens(
                    data.actualTokenA,
                    0, // Accept any amount of tokenB
                    data.path,
                    address(this),
                    block.timestamp + 300
                );

            actualTokenBAmount = data.actualTokenB + data.amounts[1];
        } else {
            actualTokenBAmount = data.actualTokenB;
        }
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

    // Helper function to generate trading activity for fees
    function _generateTradingActivity(
        IUniswapV2Pair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 swapPercentage // e.g., 100 = 1%, 500 = 5%
    ) internal {
        console.log("Generating Uniswap trading activity:");

        (uint112 reserveA, uint112 reserveB,) = pair.getReserves();
        console.log("ReserveA:", reserveA, "ReserveB:", reserveB);
        console.log("SwapPercentage:", swapPercentage);

        uint256 swapAmountA = (reserveA * swapPercentage) / 10000;
        uint256 swapAmountB = (reserveB * swapPercentage) / 10000;
        console.log("SwapAmountA:", swapAmountA, "SwapAmountB:", swapAmountB);

        // Mint tokens for trading
        tokenA.mint(address(this), swapAmountA);
        tokenB.mint(address(this), swapAmountB);

        // First swap: A -> B
        tokenA.approve(address(uniswapV2Router()), swapAmountA);
        address[] memory pathAB = new address[](2);
        pathAB[0] = address(tokenA);
        pathAB[1] = address(tokenB);

        uint256 balanceBeforeB = tokenB.balanceOf(address(this));
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                swapAmountA,
                1, // minAmountOut
                pathAB,
                address(this),
                block.timestamp
            );
        uint256 receivedB = tokenB.balanceOf(address(this)) - balanceBeforeB;
        console.log("First swap A->B: swapped", swapAmountA, "received", receivedB);

        // Second swap: B -> A
        tokenB.approve(address(uniswapV2Router()), receivedB);
        address[] memory pathBA = new address[](2);
        pathBA[0] = address(tokenB);
        pathBA[1] = address(tokenA);

        uint256 balanceBeforeA = tokenA.balanceOf(address(this));
        IUniswapV2Router(address(uniswapV2Router()))
            .swapExactTokensForTokens(
                receivedB,
                1, // minAmountOut
                pathBA,
                address(this),
                block.timestamp
            );
        uint256 receivedA = tokenA.balanceOf(address(this)) - balanceBeforeA;
        console.log("Second swap B->A: swapped", receivedB, "received", receivedA);

        console.log("Uniswap trading activity complete");
    }

    // Struct to hold test data
    struct TestData {
        address pool;
        uint256 totalLP;
        uint256 lpAmount;
        uint256 reserveA;
        uint256 reserveB;
        address tokenA;
        address tokenB;
        uint256 kLast;
        uint256 ownerFeeShare;
        uint256 quote;
        uint256 actualAmount;
    }

    // Helper function to test withdraw swap with fee
    function _testWithdrawSwapWithFee(IUniswapV2Pair pair, uint256 percentage, bool feesEnabled) internal {
        TestData memory data;
        data.pool = address(pair);
        data.totalLP = pair.totalSupply();
        data.lpAmount = _calculateLPAmount(data.totalLP, percentage);

        (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(data.pool);
        data.kLast = _getKLast(data.pool);

        // Setup fees if enabled
        if (feesEnabled) {
            _setupUniswapFees(true);
            _generateTradingActivity(pair, IERC20MintBurn(data.tokenA), IERC20MintBurn(data.tokenB), 100); // 1% trading activity

            // Get updated reserves and kLast after trading activity
            (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(data.pool);
            data.kLast = _getKLast(data.pool);
            data.totalLP = pair.totalSupply(); // Update total supply after trading activity

            // Sort reserves to match the quote function's expectations
            (data.reserveA, data.reserveB) = ConstProdUtils._sortReserves(
                data.tokenA, // knownToken
                pair.token0(), // token0
                data.reserveA, // reserve0
                data.reserveB // reserve1
            );
        }

        // Set owner fee share
        data.ownerFeeShare = feesEnabled ? UNISWAP_OWNER_FEE_SHARE : 0;

        // Get quote
        data.quote = ConstProdUtils._quoteWithdrawSwapWithFee(
            data.lpAmount,
            data.totalLP,
            data.reserveA,
            data.reserveB,
            3,
            1000,
            data.kLast,
            data.ownerFeeShare,
            feesEnabled
        );

        // Perform actual withdrawal and swap for validation
        data.actualAmount = _performActualWithdrawSwap(data.pool, data.lpAmount, UNISWAP_FEE_PERCENT);

        // Validate quote matches actual execution
        assertEq(data.quote, data.actualAmount, "Quote should match actual execution");
    }

    /**
     * @dev Helper function to test _quoteWithdrawSwapWithFee for Token B extraction
     * @param pair The Uniswap V2 pair to test
     * @param percentage The percentage of LP tokens to withdraw (in basis points)
     * @param feesEnabled Whether protocol fees are enabled
     */
    function _testWithdrawSwapWithFeeTokenB(IUniswapV2Pair pair, uint256 percentage, bool feesEnabled) internal {
        WithdrawSwapData memory data;

        // Get pool reserves and tokens
        (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(address(pair));
        data.totalSupply = pair.totalSupply();
        data.kLast = _getKLast(address(pair));

        // Calculate LP amount to withdraw
        data.lpAmount = _calculateLPAmount(data.totalSupply, percentage);

        // Setup fees if enabled
        if (feesEnabled) {
            _setupUniswapFees(true);
            _generateTradingActivity(pair, IERC20MintBurn(data.tokenA), IERC20MintBurn(data.tokenB), 100); // 1% trading activity

            // Get updated reserves and kLast after trading activity
            (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(address(pair));
            data.kLast = _getKLast(address(pair));
            data.totalSupply = pair.totalSupply(); // Update total supply after trading activity

            // Sort reserves to match the quote function's expectations
            (data.reserveA, data.reserveB) = ConstProdUtils._sortReserves(
                data.tokenB, // knownToken (Token B for extraction)
                pair.token0(), // token0
                data.reserveA, // reserve0
                data.reserveB // reserve1
            );
        } else {
            // Sort reserves for fee-disabled case
            (data.reserveA, data.reserveB) = ConstProdUtils._sortReserves(
                data.tokenB, // knownToken (Token B for extraction)
                pair.token0(), // token0
                data.reserveA, // reserve0
                data.reserveB // reserve1
            );
        }

        // Set owner fee share
        data.ownerFeeShare = feesEnabled ? UNISWAP_OWNER_FEE_SHARE : 0;

        // Get quote for Token B extraction
        data.quote = ConstProdUtils._quoteWithdrawSwapWithFee(
            data.lpAmount,
            data.totalSupply,
            data.reserveA,
            data.reserveB,
            3,
            1000,
            data.kLast,
            data.ownerFeeShare,
            feesEnabled
        );

        // Perform actual withdrawal and swap for validation (Token B extraction)
        data.actualAmount = _performActualWithdrawSwapTokenB(address(pair), data.lpAmount, UNISWAP_FEE_PERCENT);

        // Validate quote matches actual execution
        assertEq(data.quote, data.actualAmount, "Quote should match actual execution");
    }

    // ============================================================================
    // UNISWAP V2 TESTS - BALANCED POOL (6 tests: 3 percentages × 2 fee states)
    // ============================================================================

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_lowPercentage_feesDisabled_extractTokenA() public {
        _testWithdrawSwapWithFee(uniswapBalancedPair, LOW_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_mediumPercentage_feesDisabled_extractTokenA() public {
        _testWithdrawSwapWithFee(uniswapBalancedPair, MEDIUM_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_highPercentage_feesDisabled_extractTokenA() public {
        _testWithdrawSwapWithFee(uniswapBalancedPair, HIGH_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_lowPercentage_feesEnabled_extractTokenA() public {
        // vm.skip(true);
        _testWithdrawSwapWithFee(uniswapBalancedPair, LOW_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_mediumPercentage_feesEnabled_extractTokenA() public {
        // vm.skip(true);
        _testWithdrawSwapWithFee(uniswapBalancedPair, MEDIUM_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_highPercentage_feesEnabled_extractTokenA() public {
        // vm.skip(true);
        _testWithdrawSwapWithFee(uniswapBalancedPair, HIGH_PERCENTAGE, true);
    }

    // ============================================================================
    // UNISWAP V2 TESTS - UNBALANCED POOL (6 tests: 3 percentages × 2 fee states)
    // ============================================================================

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_lowPercentage_feesDisabled_extractTokenA() public {
        _testWithdrawSwapWithFee(uniswapUnbalancedPair, LOW_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_mediumPercentage_feesDisabled_extractTokenA() public {
        _testWithdrawSwapWithFee(uniswapUnbalancedPair, MEDIUM_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_highPercentage_feesDisabled_extractTokenA() public {
        _testWithdrawSwapWithFee(uniswapUnbalancedPair, HIGH_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_lowPercentage_feesEnabled_extractTokenA() public {
        // vm.skip(true);
        _testWithdrawSwapWithFee(uniswapUnbalancedPair, LOW_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_mediumPercentage_feesEnabled_extractTokenA() public {
        // vm.skip(true);
        _testWithdrawSwapWithFee(uniswapUnbalancedPair, MEDIUM_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_highPercentage_feesEnabled_extractTokenA() public {
        // vm.skip(true);
        _testWithdrawSwapWithFee(uniswapUnbalancedPair, HIGH_PERCENTAGE, true);
    }

    // ============================================================================
    // UNISWAP V2 TESTS - EXTREME UNBALANCED POOL (6 tests: 3 percentages × 2 fee states)
    // ============================================================================

    function test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_lowPercentage_feesDisabled_extractTokenA()
        public
    {
        _testWithdrawSwapWithFee(uniswapExtremeUnbalancedPair, LOW_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_mediumPercentage_feesDisabled_extractTokenA()
        public
    {
        _testWithdrawSwapWithFee(uniswapExtremeUnbalancedPair, MEDIUM_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_highPercentage_feesDisabled_extractTokenA()
        public
    {
        _testWithdrawSwapWithFee(uniswapExtremeUnbalancedPair, HIGH_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_lowPercentage_feesEnabled_extractTokenA()
        public
    {
        // vm.skip(true);
        _testWithdrawSwapWithFee(uniswapExtremeUnbalancedPair, LOW_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_mediumPercentage_feesEnabled_extractTokenA()
        public
    {
        // vm.skip(true);
        _testWithdrawSwapWithFee(uniswapExtremeUnbalancedPair, MEDIUM_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_highPercentage_feesEnabled_extractTokenA()
        public
    {
        // vm.skip(true);
        _testWithdrawSwapWithFee(uniswapExtremeUnbalancedPair, HIGH_PERCENTAGE, true);
    }

    // ============================================================================
    // UNISWAP V2 TESTS - TOKEN B EXTRACTION (18 tests: 3 pools × 3 percentages × 2 fee states)
    // ============================================================================

    // ============================================================================
    // UNISWAP V2 TESTS - BALANCED POOL - TOKEN B EXTRACTION (6 tests: 3 percentages × 2 fee states)
    // ============================================================================

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_lowPercentage_feesDisabled_extractTokenB() public {
        _testWithdrawSwapWithFeeTokenB(uniswapBalancedPair, LOW_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_mediumPercentage_feesDisabled_extractTokenB() public {
        _testWithdrawSwapWithFeeTokenB(uniswapBalancedPair, MEDIUM_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_highPercentage_feesDisabled_extractTokenB() public {
        _testWithdrawSwapWithFeeTokenB(uniswapBalancedPair, HIGH_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_lowPercentage_feesEnabled_extractTokenB() public {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapBalancedPair, LOW_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_mediumPercentage_feesEnabled_extractTokenB() public {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapBalancedPair, MEDIUM_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_highPercentage_feesEnabled_extractTokenB() public {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapBalancedPair, HIGH_PERCENTAGE, true);
    }

    // ============================================================================
    // UNISWAP V2 TESTS - UNBALANCED POOL - TOKEN B EXTRACTION (6 tests: 3 percentages × 2 fee states)
    // ============================================================================

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_lowPercentage_feesDisabled_extractTokenB() public {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapUnbalancedPair, LOW_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_mediumPercentage_feesDisabled_extractTokenB() public {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapUnbalancedPair, MEDIUM_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_highPercentage_feesDisabled_extractTokenB() public {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapUnbalancedPair, HIGH_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_lowPercentage_feesEnabled_extractTokenB() public {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapUnbalancedPair, LOW_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_mediumPercentage_feesEnabled_extractTokenB() public {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapUnbalancedPair, MEDIUM_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalancedPool_highPercentage_feesEnabled_extractTokenB() public {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapUnbalancedPair, HIGH_PERCENTAGE, true);
    }

    // ============================================================================
    // UNISWAP V2 TESTS - EXTREME UNBALANCED POOL - TOKEN B EXTRACTION (6 tests: 3 percentages × 2 fee states)
    // ============================================================================

    function test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_lowPercentage_feesDisabled_extractTokenB()
        public
    {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapExtremeUnbalancedPair, LOW_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_mediumPercentage_feesDisabled_extractTokenB()
        public
    {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapExtremeUnbalancedPair, MEDIUM_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_highPercentage_feesDisabled_extractTokenB()
        public
    {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapExtremeUnbalancedPair, HIGH_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_lowPercentage_feesEnabled_extractTokenB()
        public
    {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapExtremeUnbalancedPair, LOW_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_mediumPercentage_feesEnabled_extractTokenB()
        public
    {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapExtremeUnbalancedPair, MEDIUM_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extremeUnbalancedPool_highPercentage_feesEnabled_extractTokenB()
        public
    {
        // vm.skip(true);
        _testWithdrawSwapWithFeeTokenB(uniswapExtremeUnbalancedPair, HIGH_PERCENTAGE, true);
    }
}
