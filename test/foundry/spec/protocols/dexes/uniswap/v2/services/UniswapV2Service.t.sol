// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {UniswapV2Service} from "@crane/contracts/protocols/dexes/uniswap/v2/services/UniswapV2Service.sol";
import {TestBase_UniswapV2} from "@crane/contracts/protocols/dexes/uniswap/v2/test/bases/TestBase_UniswapV2.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

/**
 * @title UniswapV2Service_Test
 * @notice Tests for the UniswapV2Service library functions
 */
contract UniswapV2Service_Test is TestBase_UniswapV2 {
    using UniswapV2Service for IUniswapV2Pair;
    using ConstProdUtils for uint256;

    // Test tokens
    ERC20PermitMintableStub tokenA;
    ERC20PermitMintableStub tokenB;
    ERC20PermitMintableStub tokenC;
    ERC20PermitMintableStub tokenD;

    // Test pairs
    IUniswapV2Pair balancedPair;
    IUniswapV2Pair unbalancedPair;

    // Standard test amounts
    uint256 constant INITIAL_LIQUIDITY = 10000e18;
    uint256 constant TEST_AMOUNT = 100e18;
    uint256 constant UNBALANCED_RATIO_A = 10000e18;
    uint256 constant UNBALANCED_RATIO_B = 1000e18;
    uint256 constant UNISWAP_FEE = 300; // 0.3%

    /* ---------------------------------------------------------------------- */
    /*                                 Setup                                   */
    /* ---------------------------------------------------------------------- */

    function setUp() public override {
        TestBase_UniswapV2.setUp();
        _createTokens();
        _createPairs();
    }

    function _createTokens() internal {
        tokenA = new ERC20PermitMintableStub("TokenA", "TKA", 18, address(this), 0);
        vm.label(address(tokenA), "TokenA");

        tokenB = new ERC20PermitMintableStub("TokenB", "TKB", 18, address(this), 0);
        vm.label(address(tokenB), "TokenB");

        tokenC = new ERC20PermitMintableStub("TokenC", "TKC", 18, address(this), 0);
        vm.label(address(tokenC), "TokenC");

        tokenD = new ERC20PermitMintableStub("TokenD", "TKD", 18, address(this), 0);
        vm.label(address(tokenD), "TokenD");
    }

    function _createPairs() internal {
        balancedPair = IUniswapV2Pair(uniswapV2Factory.createPair(address(tokenA), address(tokenB)));
        vm.label(address(balancedPair), "BalancedPair");

        unbalancedPair = IUniswapV2Pair(uniswapV2Factory.createPair(address(tokenC), address(tokenD)));
        vm.label(address(unbalancedPair), "UnbalancedPair");
    }

    function _initializeBalancedPool() internal {
        tokenA.mint(address(this), INITIAL_LIQUIDITY);
        tokenA.approve(address(uniswapV2Router), INITIAL_LIQUIDITY);
        tokenB.mint(address(this), INITIAL_LIQUIDITY);
        tokenB.approve(address(uniswapV2Router), INITIAL_LIQUIDITY);

        UniswapV2Service._deposit(uniswapV2Router, tokenA, tokenB, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);
    }

    function _initializeUnbalancedPool() internal {
        tokenC.mint(address(this), UNBALANCED_RATIO_A);
        tokenC.approve(address(uniswapV2Router), UNBALANCED_RATIO_A);
        tokenD.mint(address(this), UNBALANCED_RATIO_B);
        tokenD.approve(address(uniswapV2Router), UNBALANCED_RATIO_B);

        UniswapV2Service._deposit(uniswapV2Router, tokenC, tokenD, UNBALANCED_RATIO_A, UNBALANCED_RATIO_B);
    }

    /* ---------------------------------------------------------------------- */
    /*                            _swap() Tests                                */
    /* ---------------------------------------------------------------------- */

    function test_swap_normalSwap_returnsExpectedOutput() public {
        _initializeBalancedPool();

        uint256 swapAmount = TEST_AMOUNT;
        tokenA.mint(address(this), swapAmount);
        tokenA.approve(address(uniswapV2Router), swapAmount);

        // Get reserves using the service's _sortReserves
        UniswapV2Service.ReserveInfo memory reserves = UniswapV2Service._sortReserves(balancedPair, tokenA);

        // Calculate expected output using ConstProdUtils
        uint256 expectedOut = ConstProdUtils._saleQuote(swapAmount, reserves.knownReserve, reserves.opposingReserve, reserves.feePercent);

        uint256 balanceBefore = tokenB.balanceOf(address(this));

        // Execute swap using the library with explicit reserves
        uint256 amountOut = UniswapV2Service._swap(
            uniswapV2Router,
            swapAmount,
            tokenA,
            reserves.knownReserve,
            reserves.feePercent,
            tokenB,
            reserves.opposingReserve
        );

        uint256 balanceAfter = tokenB.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(amountOut, expectedOut, "Returned amount should match expected");
        assertEq(actualReceived, expectedOut, "Actual received should match expected");
        assertGt(amountOut, 0, "Output amount should be positive");
    }

    function test_swap_withPoolOverload_returnsExpectedOutput() public {
        _initializeBalancedPool();

        uint256 swapAmount = TEST_AMOUNT;
        tokenA.mint(address(this), swapAmount);
        tokenA.approve(address(uniswapV2Router), swapAmount);

        uint256 balanceBefore = tokenB.balanceOf(address(this));

        // Execute swap using the pool overload
        uint256 amountOut = UniswapV2Service._swap(
            uniswapV2Router,
            balancedPair,
            swapAmount,
            tokenA,
            tokenB
        );

        uint256 balanceAfter = tokenB.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(actualReceived, amountOut, "Actual received should match returned amount");
        assertGt(amountOut, 0, "Output amount should be positive");
    }

    function test_swap_unbalancedPool_accountsForPriceImpact() public {
        _initializeUnbalancedPool();

        uint256 swapAmount = TEST_AMOUNT;
        tokenC.mint(address(this), swapAmount);
        tokenC.approve(address(uniswapV2Router), swapAmount);

        // Use _sortReserves to get reserves in the correct order for tokenC
        UniswapV2Service.ReserveInfo memory reserves = UniswapV2Service._sortReserves(unbalancedPair, tokenC);

        uint256 expectedOut = ConstProdUtils._saleQuote(swapAmount, reserves.knownReserve, reserves.opposingReserve, reserves.feePercent);

        uint256 amountOut = UniswapV2Service._swap(
            uniswapV2Router,
            unbalancedPair,
            swapAmount,
            tokenC,
            tokenD
        );

        assertEq(amountOut, expectedOut, "Output should match calculated quote");
        assertGt(amountOut, 0, "Swap should produce output");
    }

    function test_swap_reverseDirection_works() public {
        _initializeBalancedPool();

        uint256 swapAmount = TEST_AMOUNT;
        tokenB.mint(address(this), swapAmount);
        tokenB.approve(address(uniswapV2Router), swapAmount);

        uint256 balanceBefore = tokenA.balanceOf(address(this));

        uint256 amountOut = UniswapV2Service._swap(
            uniswapV2Router,
            balancedPair,
            swapAmount,
            tokenB,
            tokenA
        );

        uint256 balanceAfter = tokenA.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(actualReceived, amountOut, "Actual received should match returned amount");
        assertGt(amountOut, 0, "Reverse swap should produce output");
    }

    /* ---------------------------------------------------------------------- */
    /*                   _swapExactTokensForTokens() Tests                     */
    /* ---------------------------------------------------------------------- */

    function test_swapExactTokensForTokens_normalSwap_works() public {
        _initializeBalancedPool();

        uint256 swapAmount = TEST_AMOUNT;
        tokenA.mint(address(this), swapAmount);
        tokenA.approve(address(uniswapV2Router), swapAmount);

        uint256 balanceBefore = tokenB.balanceOf(address(this));

        uint256 amountOut = UniswapV2Service._swapExactTokensForTokens(
            uniswapV2Router,
            tokenA,
            swapAmount,
            tokenB,
            1, // minAmountOut
            address(this)
        );

        uint256 balanceAfter = tokenB.balanceOf(address(this));

        assertGt(amountOut, 0, "Should receive output tokens");
        assertEq(balanceAfter - balanceBefore, amountOut, "Balance should increase by amountOut");
    }

    function test_swapExactTokensForTokens_toRecipient_sendsToRecipient() public {
        _initializeBalancedPool();

        address recipient = makeAddr("recipient");

        uint256 swapAmount = TEST_AMOUNT;
        tokenA.mint(address(this), swapAmount);
        tokenA.approve(address(uniswapV2Router), swapAmount);

        uint256 amountOut = UniswapV2Service._swapExactTokensForTokens(
            uniswapV2Router,
            tokenA,
            swapAmount,
            tokenB,
            1,
            recipient
        );

        assertEq(tokenB.balanceOf(recipient), amountOut, "Recipient should receive tokens");
    }

    /* ---------------------------------------------------------------------- */
    /*                   _swapTokensForExactTokens() Tests                     */
    /* ---------------------------------------------------------------------- */

    function test_swapTokensForExactTokens_fixedOutput_works() public {
        _initializeBalancedPool();

        uint256 exactOut = 50e18;
        uint256 maxIn = 100e18;
        tokenA.mint(address(this), maxIn);
        tokenA.approve(address(uniswapV2Router), maxIn);

        uint256 balanceABefore = tokenA.balanceOf(address(this));
        uint256 balanceBBefore = tokenB.balanceOf(address(this));

        uint256 amountIn = UniswapV2Service._swapTokensForExactTokens(
            uniswapV2Router,
            tokenA,
            maxIn,
            tokenB,
            exactOut,
            address(this)
        );

        uint256 balanceAAfter = tokenA.balanceOf(address(this));
        uint256 balanceBAfter = tokenB.balanceOf(address(this));

        assertGt(amountIn, 0, "Should use input tokens");
        assertLe(amountIn, maxIn, "Should not exceed max input");
        assertEq(balanceABefore - balanceAAfter, amountIn, "Input balance should decrease by amountIn");
        assertEq(balanceBAfter - balanceBBefore, exactOut, "Output balance should increase by exactOut");
    }

    /* ---------------------------------------------------------------------- */
    /*                         _swapDeposit() Tests                           */
    /* ---------------------------------------------------------------------- */

    function test_swapDeposit_balancedPool_mintsLP() public {
        _initializeBalancedPool();

        uint256 depositAmount = 1000e18;
        tokenA.mint(address(this), depositAmount);
        tokenA.approve(address(uniswapV2Router), depositAmount);

        uint256 lpBefore = balancedPair.balanceOf(address(this));

        uint256 lpAmount = UniswapV2Service._swapDeposit(
            uniswapV2Router,
            balancedPair,
            tokenA,
            depositAmount,
            tokenB
        );

        uint256 lpAfter = balancedPair.balanceOf(address(this));

        assertGt(lpAmount, 0, "Should mint LP tokens");
        assertEq(lpAfter - lpBefore, lpAmount, "LP balance should increase by minted amount");
    }

    function test_swapDeposit_unbalancedPool_mintsLP() public {
        _initializeUnbalancedPool();

        uint256 depositAmount = 500e18;
        tokenC.mint(address(this), depositAmount);
        tokenC.approve(address(uniswapV2Router), depositAmount);

        uint256 lpBefore = unbalancedPair.balanceOf(address(this));

        uint256 lpAmount = UniswapV2Service._swapDeposit(
            uniswapV2Router,
            unbalancedPair,
            tokenC,
            depositAmount,
            tokenD
        );

        uint256 lpAfter = unbalancedPair.balanceOf(address(this));

        assertGt(lpAmount, 0, "Should mint LP tokens in unbalanced pool");
        assertEq(lpAfter - lpBefore, lpAmount, "LP balance should increase");
    }

    function test_swapDeposit_fromTokenB_mintsLP() public {
        _initializeBalancedPool();

        uint256 depositAmount = 1000e18;
        tokenB.mint(address(this), depositAmount);
        tokenB.approve(address(uniswapV2Router), depositAmount);

        uint256 lpBefore = balancedPair.balanceOf(address(this));

        uint256 lpAmount = UniswapV2Service._swapDeposit(
            uniswapV2Router,
            balancedPair,
            tokenB,
            depositAmount,
            tokenA
        );

        uint256 lpAfter = balancedPair.balanceOf(address(this));

        assertGt(lpAmount, 0, "Should mint LP tokens when depositing token B");
        assertEq(lpAfter - lpBefore, lpAmount, "LP balance should increase");
    }

    /* ---------------------------------------------------------------------- */
    /*                          _deposit() Tests                              */
    /* ---------------------------------------------------------------------- */

    function test_deposit_balancedAmounts_mintsLP() public {
        _initializeBalancedPool();

        uint256 amountA = 100e18;
        uint256 amountB = 100e18;

        tokenA.mint(address(this), amountA);
        tokenB.mint(address(this), amountB);
        tokenA.approve(address(uniswapV2Router), amountA);
        tokenB.approve(address(uniswapV2Router), amountB);

        uint256 lpBefore = balancedPair.balanceOf(address(this));

        uint256 liquidity = UniswapV2Service._deposit(
            uniswapV2Router,
            tokenA,
            tokenB,
            amountA,
            amountB
        );

        uint256 lpAfter = balancedPair.balanceOf(address(this));

        assertGt(liquidity, 0, "Should mint LP tokens");
        assertEq(lpAfter - lpBefore, liquidity, "LP balance should match returned liquidity");
    }

    function test_deposit_toEmptyPool_mintsInitialLP() public {
        // Create fresh tokens and pair
        ERC20PermitMintableStub freshTokenA = new ERC20PermitMintableStub("FreshA", "FA", 18, address(this), 0);
        ERC20PermitMintableStub freshTokenB = new ERC20PermitMintableStub("FreshB", "FB", 18, address(this), 0);

        IUniswapV2Pair freshPair = IUniswapV2Pair(uniswapV2Factory.createPair(address(freshTokenA), address(freshTokenB)));

        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;

        freshTokenA.mint(address(this), amountA);
        freshTokenB.mint(address(this), amountB);
        freshTokenA.approve(address(uniswapV2Router), amountA);
        freshTokenB.approve(address(uniswapV2Router), amountB);

        uint256 liquidity = UniswapV2Service._deposit(
            uniswapV2Router,
            IERC20(address(freshTokenA)),
            IERC20(address(freshTokenB)),
            amountA,
            amountB
        );

        assertGt(liquidity, 0, "Should mint initial LP tokens");
        assertEq(freshPair.balanceOf(address(this)), liquidity, "Should receive LP tokens");
    }

    /* ---------------------------------------------------------------------- */
    /*                       _withdrawDirect() Tests                          */
    /* ---------------------------------------------------------------------- */

    function test_withdrawDirect_fullWithdrawal_returnsTokens() public {
        _initializeBalancedPool();

        uint256 lpBalance = balancedPair.balanceOf(address(this));
        assertGt(lpBalance, 0, "Should have LP tokens to withdraw");

        uint256 balanceABefore = tokenA.balanceOf(address(this));
        uint256 balanceBBefore = tokenB.balanceOf(address(this));

        // Withdraw all LP tokens
        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(balancedPair, lpBalance);

        uint256 balanceAAfter = tokenA.balanceOf(address(this));
        uint256 balanceBAfter = tokenB.balanceOf(address(this));

        assertGt(amount0, 0, "Should receive token0");
        assertGt(amount1, 0, "Should receive token1");
        assertGt(balanceAAfter - balanceABefore, 0, "TokenA balance should increase");
        assertGt(balanceBAfter - balanceBBefore, 0, "TokenB balance should increase");
        assertEq(balancedPair.balanceOf(address(this)), 0, "LP balance should be zero after full withdrawal");
    }

    function test_withdrawDirect_partialWithdrawal_returnsProportionalTokens() public {
        _initializeBalancedPool();

        uint256 lpBalance = balancedPair.balanceOf(address(this));
        uint256 withdrawAmount = lpBalance / 4; // Withdraw 25%

        (uint256 amount0Full, uint256 amount1Full) = _calculateWithdrawAmounts(balancedPair, lpBalance);
        (uint256 amount0Partial, uint256 amount1Partial) = UniswapV2Service._withdrawDirect(balancedPair, withdrawAmount);

        // Partial withdrawal should be approximately 25% of full withdrawal
        assertApproxEqRel(amount0Partial * 4, amount0Full, 0.01e18, "Token0 should be ~25% of full");
        assertApproxEqRel(amount1Partial * 4, amount1Full, 0.01e18, "Token1 should be ~25% of full");
    }

    /* ---------------------------------------------------------------------- */
    /*                     _withdrawSwapDirect() Tests                        */
    /* ---------------------------------------------------------------------- */

    function test_withdrawSwapDirect_fullWithdrawal_returnsAllAsTokenOut() public {
        _initializeBalancedPool();

        uint256 lpBalance = balancedPair.balanceOf(address(this));
        uint256 balanceBBefore = tokenB.balanceOf(address(this));

        uint256 amountOut = UniswapV2Service._withdrawSwapDirect(
            balancedPair,
            uniswapV2Router,
            lpBalance,
            tokenB,
            tokenA
        );

        uint256 balanceBAfter = tokenB.balanceOf(address(this));

        assertGt(amountOut, 0, "Should receive output tokens");
        assertEq(balanceBAfter - balanceBBefore, amountOut, "Balance increase should match returned amount");
        assertEq(balancedPair.balanceOf(address(this)), 0, "LP should be fully burned");
    }

    function test_withdrawSwapDirect_partialWithdrawal_returnsTokens() public {
        _initializeBalancedPool();

        uint256 lpBalance = balancedPair.balanceOf(address(this));
        uint256 withdrawAmount = lpBalance / 2;

        uint256 balanceABefore = tokenA.balanceOf(address(this));

        uint256 amountOut = UniswapV2Service._withdrawSwapDirect(
            balancedPair,
            uniswapV2Router,
            withdrawAmount,
            tokenA,
            tokenB
        );

        uint256 balanceAAfter = tokenA.balanceOf(address(this));

        assertGt(amountOut, 0, "Should receive output tokens");
        assertEq(balanceAAfter - balanceABefore, amountOut, "Balance increase should match");
        assertEq(balancedPair.balanceOf(address(this)), lpBalance - withdrawAmount, "Should have remaining LP");
    }

    /* ---------------------------------------------------------------------- */
    /*                       _sortReserves() Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_sortReserves_token0AsKnown_returnsCorrectOrder() public {
        _initializeBalancedPool();

        address token0 = balancedPair.token0();
        IERC20 knownToken = IERC20(token0);

        UniswapV2Service.ReserveInfo memory reserves = UniswapV2Service._sortReserves(balancedPair, knownToken);

        (uint112 reserve0, uint112 reserve1,) = balancedPair.getReserves();

        assertEq(reserves.knownReserve, reserve0, "Known reserve should be reserve0");
        assertEq(reserves.opposingReserve, reserve1, "Opposing reserve should be reserve1");
        assertEq(reserves.feePercent, UNISWAP_FEE, "Fee should be 300 (0.3%)");
    }

    function test_sortReserves_token1AsKnown_returnsCorrectOrder() public {
        _initializeBalancedPool();

        address token1 = balancedPair.token1();
        IERC20 knownToken = IERC20(token1);

        UniswapV2Service.ReserveInfo memory reserves = UniswapV2Service._sortReserves(balancedPair, knownToken);

        (uint112 reserve0, uint112 reserve1,) = balancedPair.getReserves();

        assertEq(reserves.knownReserve, reserve1, "Known reserve should be reserve1");
        assertEq(reserves.opposingReserve, reserve0, "Opposing reserve should be reserve0");
        assertEq(reserves.feePercent, UNISWAP_FEE, "Fee should be 300 (0.3%)");
    }

    /* ---------------------------------------------------------------------- */
    /*                            Fuzz Tests                                   */
    /* ---------------------------------------------------------------------- */

    function testFuzz_swap_anyAmount_producesOutput(uint256 swapAmount) public {
        _initializeBalancedPool();

        // Bound swap amount to reasonable range
        swapAmount = bound(swapAmount, 1e15, 1000e18);

        tokenA.mint(address(this), swapAmount);
        tokenA.approve(address(uniswapV2Router), swapAmount);

        uint256 amountOut = UniswapV2Service._swap(
            uniswapV2Router,
            balancedPair,
            swapAmount,
            tokenA,
            tokenB
        );

        assertGt(amountOut, 0, "Any reasonable swap should produce output");
    }

    function testFuzz_swapDeposit_anyAmount_producesLP(uint256 depositAmount) public {
        _initializeBalancedPool();

        // Bound deposit amount to reasonable range
        depositAmount = bound(depositAmount, 1e16, 5000e18);

        tokenA.mint(address(this), depositAmount);
        tokenA.approve(address(uniswapV2Router), depositAmount);

        uint256 lpAmount = UniswapV2Service._swapDeposit(
            uniswapV2Router,
            balancedPair,
            tokenA,
            depositAmount,
            tokenB
        );

        assertGt(lpAmount, 0, "Any reasonable deposit should produce LP tokens");
    }

    /* ---------------------------------------------------------------------- */
    /*                           Helper Functions                              */
    /* ---------------------------------------------------------------------- */

    function _calculateWithdrawAmounts(IUniswapV2Pair pair, uint256 lpAmount) internal view returns (uint256, uint256) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        uint256 amount0 = (lpAmount * reserve0) / totalSupply;
        uint256 amount1 = (lpAmount * reserve1) / totalSupply;
        return (amount0, amount1);
    }
}
