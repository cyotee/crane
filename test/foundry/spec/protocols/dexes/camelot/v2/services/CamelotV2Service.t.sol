// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ICamelotPair} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol";
import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Camelot.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

/**
 * @title CamelotV2Service_Test
 * @notice Tests for the CamelotV2Service library functions
 */
contract CamelotV2Service_Test is TestBase_ConstProdUtils_Camelot {
    using CamelotV2Service for ICamelotPair;
    using ConstProdUtils for uint256;

    /* ---------------------------------------------------------------------- */
    /*                                 Setup                                   */
    /* ---------------------------------------------------------------------- */

    function setUp() public override {
        TestBase_ConstProdUtils_Camelot.setUp();
    }

    /* ---------------------------------------------------------------------- */
    /*                            _swap() Tests                                */
    /* ---------------------------------------------------------------------- */

    function test_swap_normalSwap_returnsExpectedOutput() public {
        _initializeCamelotBalancedPools();

        uint256 swapAmount = 100e18;
        camelotBalancedTokenA.mint(address(this), swapAmount);
        camelotBalancedTokenA.approve(address(camelotV2Router), swapAmount);

        (uint112 reserveA, uint112 reserveB, uint16 feePercentA, ) = camelotBalancedPair.getReserves();

        // Calculate expected output using ConstProdUtils
        uint256 expectedOut = ConstProdUtils._saleQuote(swapAmount, reserveA, reserveB, feePercentA);

        uint256 balanceBefore = camelotBalancedTokenB.balanceOf(address(this));

        // Execute swap using the library with explicit reserves
        uint256 amountOut = CamelotV2Service._swap(
            camelotV2Router,
            swapAmount,
            camelotBalancedTokenA,
            reserveA,
            feePercentA,
            camelotBalancedTokenB,
            reserveB,
            address(0)
        );

        uint256 balanceAfter = camelotBalancedTokenB.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(amountOut, expectedOut, "Returned amount should match expected");
        assertEq(actualReceived, expectedOut, "Actual received should match expected");
        assertGt(amountOut, 0, "Output amount should be positive");
    }

    function test_swap_withPoolOverload_returnsExpectedOutput() public {
        _initializeCamelotBalancedPools();

        uint256 swapAmount = 100e18;
        camelotBalancedTokenA.mint(address(this), swapAmount);
        camelotBalancedTokenA.approve(address(camelotV2Router), swapAmount);

        uint256 balanceBefore = camelotBalancedTokenB.balanceOf(address(this));

        // Execute swap using the pool overload
        uint256 amountOut = CamelotV2Service._swap(
            camelotV2Router,
            camelotBalancedPair,
            swapAmount,
            camelotBalancedTokenA,
            camelotBalancedTokenB,
            address(0)
        );

        uint256 balanceAfter = camelotBalancedTokenB.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(actualReceived, amountOut, "Actual received should match returned amount");
        assertGt(amountOut, 0, "Output amount should be positive");
    }

    function test_swap_unbalancedPool_accountsForPriceImpact() public {
        _initializeCamelotUnbalancedPools();

        uint256 swapAmount = 100e18;
        camelotUnbalancedTokenA.mint(address(this), swapAmount);
        camelotUnbalancedTokenA.approve(address(camelotV2Router), swapAmount);

        // Use _sortReserves to get reserves in the correct order for tokenA
        (uint256 reserveIn, uint256 reserveOut, uint256 feePercent, ) =
            CamelotV2Service._sortReserves(camelotUnbalancedPair, camelotUnbalancedTokenA);

        uint256 expectedOut = ConstProdUtils._saleQuote(swapAmount, reserveIn, reserveOut, feePercent);

        uint256 amountOut = CamelotV2Service._swap(
            camelotV2Router,
            camelotUnbalancedPair,
            swapAmount,
            camelotUnbalancedTokenA,
            camelotUnbalancedTokenB,
            address(0)
        );

        assertEq(amountOut, expectedOut, "Output should match calculated quote");
        // Output should be positive
        assertGt(amountOut, 0, "Swap should produce output");
    }

    function test_swap_reverseDirection_works() public {
        _initializeCamelotBalancedPools();

        uint256 swapAmount = 100e18;
        camelotBalancedTokenB.mint(address(this), swapAmount);
        camelotBalancedTokenB.approve(address(camelotV2Router), swapAmount);

        uint256 balanceBefore = camelotBalancedTokenA.balanceOf(address(this));

        uint256 amountOut = CamelotV2Service._swap(
            camelotV2Router,
            camelotBalancedPair,
            swapAmount,
            camelotBalancedTokenB,
            camelotBalancedTokenA,
            address(0)
        );

        uint256 balanceAfter = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(actualReceived, amountOut, "Actual received should match returned amount");
        assertGt(amountOut, 0, "Reverse swap should produce output");
    }

    /* ---------------------------------------------------------------------- */
    /*                         _swapDeposit() Tests                           */
    /* ---------------------------------------------------------------------- */

    function test_swapDeposit_balancedPool_mintsLP() public {
        _initializeCamelotBalancedPools();

        uint256 depositAmount = 1000e18;
        camelotBalancedTokenA.mint(address(this), depositAmount);
        camelotBalancedTokenA.approve(address(camelotV2Router), depositAmount);

        uint256 lpBefore = camelotBalancedPair.balanceOf(address(this));

        uint256 lpAmount = CamelotV2Service._swapDeposit(
            camelotV2Router,
            camelotBalancedPair,
            camelotBalancedTokenA,
            depositAmount,
            camelotBalancedTokenB,
            address(0)
        );

        uint256 lpAfter = camelotBalancedPair.balanceOf(address(this));

        assertGt(lpAmount, 0, "Should mint LP tokens");
        assertEq(lpAfter - lpBefore, lpAmount, "LP balance should increase by minted amount");
    }

    function test_swapDeposit_unbalancedPool_mintsLP() public {
        _initializeCamelotUnbalancedPools();

        uint256 depositAmount = 500e18;
        camelotUnbalancedTokenA.mint(address(this), depositAmount);
        camelotUnbalancedTokenA.approve(address(camelotV2Router), depositAmount);

        uint256 lpBefore = camelotUnbalancedPair.balanceOf(address(this));

        uint256 lpAmount = CamelotV2Service._swapDeposit(
            camelotV2Router,
            camelotUnbalancedPair,
            camelotUnbalancedTokenA,
            depositAmount,
            camelotUnbalancedTokenB,
            address(0)
        );

        uint256 lpAfter = camelotUnbalancedPair.balanceOf(address(this));

        assertGt(lpAmount, 0, "Should mint LP tokens in unbalanced pool");
        assertEq(lpAfter - lpBefore, lpAmount, "LP balance should increase");
    }

    function test_swapDeposit_fromTokenB_mintsLP() public {
        _initializeCamelotBalancedPools();

        uint256 depositAmount = 1000e18;
        camelotBalancedTokenB.mint(address(this), depositAmount);
        camelotBalancedTokenB.approve(address(camelotV2Router), depositAmount);

        uint256 lpBefore = camelotBalancedPair.balanceOf(address(this));

        uint256 lpAmount = CamelotV2Service._swapDeposit(
            camelotV2Router,
            camelotBalancedPair,
            camelotBalancedTokenB,
            depositAmount,
            camelotBalancedTokenA,
            address(0)
        );

        uint256 lpAfter = camelotBalancedPair.balanceOf(address(this));

        assertGt(lpAmount, 0, "Should mint LP tokens when depositing token B");
        assertEq(lpAfter - lpBefore, lpAmount, "LP balance should increase");
    }

    /* ---------------------------------------------------------------------- */
    /*                          _deposit() Tests                              */
    /* ---------------------------------------------------------------------- */

    function test_deposit_balancedAmounts_mintsLP() public {
        _initializeCamelotBalancedPools();

        uint256 amountA = 100e18;
        uint256 amountB = 100e18;

        camelotBalancedTokenA.mint(address(this), amountA);
        camelotBalancedTokenB.mint(address(this), amountB);
        camelotBalancedTokenA.approve(address(camelotV2Router), amountA);
        camelotBalancedTokenB.approve(address(camelotV2Router), amountB);

        uint256 lpBefore = camelotBalancedPair.balanceOf(address(this));

        uint256 liquidity = CamelotV2Service._deposit(
            camelotV2Router,
            camelotBalancedTokenA,
            camelotBalancedTokenB,
            amountA,
            amountB
        );

        uint256 lpAfter = camelotBalancedPair.balanceOf(address(this));

        assertGt(liquidity, 0, "Should mint LP tokens");
        assertEq(lpAfter - lpBefore, liquidity, "LP balance should match returned liquidity");
    }

    function test_deposit_toEmptyPool_mintsInitialLP() public {
        // Create fresh tokens and pair
        ERC20PermitMintableStub freshTokenA = new ERC20PermitMintableStub("FreshA", "FA", 18, address(this), 0);
        ERC20PermitMintableStub freshTokenB = new ERC20PermitMintableStub("FreshB", "FB", 18, address(this), 0);

        ICamelotPair freshPair = ICamelotPair(camelotV2Factory.createPair(address(freshTokenA), address(freshTokenB)));

        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;

        freshTokenA.mint(address(this), amountA);
        freshTokenB.mint(address(this), amountB);
        freshTokenA.approve(address(camelotV2Router), amountA);
        freshTokenB.approve(address(camelotV2Router), amountB);

        uint256 liquidity = CamelotV2Service._deposit(
            camelotV2Router,
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
        _initializeCamelotBalancedPools();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        assertGt(lpBalance, 0, "Should have LP tokens to withdraw");

        uint256 balanceABefore = camelotBalancedTokenA.balanceOf(address(this));
        uint256 balanceBBefore = camelotBalancedTokenB.balanceOf(address(this));

        // Withdraw all LP tokens
        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(camelotBalancedPair, lpBalance);

        uint256 balanceAAfter = camelotBalancedTokenA.balanceOf(address(this));
        uint256 balanceBAfter = camelotBalancedTokenB.balanceOf(address(this));

        assertGt(amount0, 0, "Should receive token0");
        assertGt(amount1, 0, "Should receive token1");
        assertGt(balanceAAfter - balanceABefore, 0, "TokenA balance should increase");
        assertGt(balanceBAfter - balanceBBefore, 0, "TokenB balance should increase");
        assertEq(camelotBalancedPair.balanceOf(address(this)), 0, "LP balance should be zero after full withdrawal");
    }

    function test_withdrawDirect_partialWithdrawal_returnsProportionalTokens() public {
        _initializeCamelotBalancedPools();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 withdrawAmount = lpBalance / 4; // Withdraw 25%

        (uint256 amount0Full, uint256 amount1Full) = _calculateWithdrawAmounts(camelotBalancedPair, lpBalance);
        (uint256 amount0Partial, uint256 amount1Partial) = CamelotV2Service._withdrawDirect(camelotBalancedPair, withdrawAmount);

        // Partial withdrawal should be approximately 25% of full withdrawal
        assertApproxEqRel(amount0Partial * 4, amount0Full, 0.01e18, "Token0 should be ~25% of full");
        assertApproxEqRel(amount1Partial * 4, amount1Full, 0.01e18, "Token1 should be ~25% of full");
    }

    /* ---------------------------------------------------------------------- */
    /*                     _withdrawSwapDirect() Tests                        */
    /* ---------------------------------------------------------------------- */

    function test_withdrawSwapDirect_fullWithdrawal_returnsAllAsTokenOut() public {
        _initializeCamelotBalancedPools();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 balanceBBefore = camelotBalancedTokenB.balanceOf(address(this));

        uint256 amountOut = CamelotV2Service._withdrawSwapDirect(
            camelotBalancedPair,
            camelotV2Router,
            lpBalance,
            camelotBalancedTokenB,
            camelotBalancedTokenA,
            address(0)
        );

        uint256 balanceBAfter = camelotBalancedTokenB.balanceOf(address(this));

        assertGt(amountOut, 0, "Should receive output tokens");
        assertEq(balanceBAfter - balanceBBefore, amountOut, "Balance increase should match returned amount");
        assertEq(camelotBalancedPair.balanceOf(address(this)), 0, "LP should be fully burned");
    }

    function test_withdrawSwapDirect_partialWithdrawal_returnsTokens() public {
        _initializeCamelotBalancedPools();

        uint256 lpBalance = camelotBalancedPair.balanceOf(address(this));
        uint256 withdrawAmount = lpBalance / 2;

        uint256 balanceABefore = camelotBalancedTokenA.balanceOf(address(this));

        uint256 amountOut = CamelotV2Service._withdrawSwapDirect(
            camelotBalancedPair,
            camelotV2Router,
            withdrawAmount,
            camelotBalancedTokenA,
            camelotBalancedTokenB,
            address(0)
        );

        uint256 balanceAAfter = camelotBalancedTokenA.balanceOf(address(this));

        assertGt(amountOut, 0, "Should receive output tokens");
        assertEq(balanceAAfter - balanceABefore, amountOut, "Balance increase should match");
        assertEq(camelotBalancedPair.balanceOf(address(this)), lpBalance - withdrawAmount, "Should have remaining LP");
    }

    /* ---------------------------------------------------------------------- */
    /*                       _balanceAssets() Tests                           */
    /* ---------------------------------------------------------------------- */

    function test_balanceAssets_balancedPool_returnsBalancedAmounts() public {
        _initializeCamelotBalancedPools();

        uint256 inputAmount = 1000e18;
        camelotBalancedTokenA.mint(address(this), inputAmount);
        camelotBalancedTokenA.approve(address(camelotV2Router), inputAmount);

        uint256[] memory amounts = CamelotV2Service._balanceAssets(
            camelotV2Router,
            camelotBalancedPair,
            inputAmount,
            camelotBalancedTokenA,
            camelotBalancedTokenB,
            address(0)
        );

        assertEq(amounts.length, 2, "Should return two amounts");
        assertGt(amounts[0], 0, "Token A amount should be positive");
        assertGt(amounts[1], 0, "Token B amount should be positive");
        // In a balanced pool, amounts should be roughly equal
        assertApproxEqRel(amounts[0], amounts[1], 0.1e18, "Amounts should be roughly balanced");
    }

    function test_balanceAssets_unbalancedPool_accountsForRatio() public {
        _initializeCamelotUnbalancedPools();

        uint256 inputAmount = 500e18;
        camelotUnbalancedTokenA.mint(address(this), inputAmount);
        camelotUnbalancedTokenA.approve(address(camelotV2Router), inputAmount);

        // Use _sortReserves to get reserves in the correct order for tokenA
        (uint256 reserveA, uint256 reserveB, , ) =
            CamelotV2Service._sortReserves(camelotUnbalancedPair, camelotUnbalancedTokenA);

        uint256[] memory amounts = CamelotV2Service._balanceAssets(
            camelotV2Router,
            camelotUnbalancedPair,
            inputAmount,
            camelotUnbalancedTokenA,
            camelotUnbalancedTokenB,
            address(0)
        );

        assertEq(amounts.length, 2, "Should return two amounts");
        assertGt(amounts[0], 0, "Token A amount should be positive");
        assertGt(amounts[1], 0, "Token B amount should be positive");

        // After balancing, the value ratio should match the pool ratio
        // amounts[0] is remaining tokenA, amounts[1] is swapped tokenB
        // The pool has reserveA of tokenA and reserveB of tokenB
        // So amounts[0]/amounts[1] should be approximately reserveA/reserveB
        uint256 poolRatio = (reserveA * 1e18) / reserveB;
        uint256 amountRatio = (amounts[0] * 1e18) / amounts[1];
        // Use a wider tolerance (50%) because swap fees affect the exact ratio
        assertApproxEqRel(amountRatio, poolRatio, 0.5e18, "Amounts should roughly match pool ratio");
    }

    /* ---------------------------------------------------------------------- */
    /*                       _sortReserves() Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_sortReserves_token0AsKnown_returnsCorrectOrder() public {
        _initializeCamelotBalancedPools();

        address token0 = camelotBalancedPair.token0();
        IERC20 knownToken = IERC20(token0);

        (uint256 knownReserve, uint256 opposingReserve, uint256 knownFee, uint256 opposingFee) =
            CamelotV2Service._sortReserves(camelotBalancedPair, knownToken);

        (uint112 reserve0, uint112 reserve1, uint16 fee0, uint16 fee1) = camelotBalancedPair.getReserves();

        assertEq(knownReserve, reserve0, "Known reserve should be reserve0");
        assertEq(opposingReserve, reserve1, "Opposing reserve should be reserve1");
        assertEq(knownFee, fee0, "Known fee should be fee0");
        assertEq(opposingFee, fee1, "Opposing fee should be fee1");
    }

    function test_sortReserves_token1AsKnown_returnsCorrectOrder() public {
        _initializeCamelotBalancedPools();

        address token1 = camelotBalancedPair.token1();
        IERC20 knownToken = IERC20(token1);

        (uint256 knownReserve, uint256 opposingReserve, uint256 knownFee, uint256 opposingFee) =
            CamelotV2Service._sortReserves(camelotBalancedPair, knownToken);

        (uint112 reserve0, uint112 reserve1, uint16 fee0, uint16 fee1) = camelotBalancedPair.getReserves();

        assertEq(knownReserve, reserve1, "Known reserve should be reserve1");
        assertEq(opposingReserve, reserve0, "Opposing reserve should be reserve0");
        assertEq(knownFee, fee1, "Known fee should be fee1");
        assertEq(opposingFee, fee0, "Opposing fee should be fee0");
    }

    function test_sortReserves_zeroAddress_defaultsToToken0() public {
        _initializeCamelotBalancedPools();

        (uint256 knownReserve, uint256 opposingReserve, , ) =
            CamelotV2Service._sortReserves(camelotBalancedPair, IERC20(address(0)));

        (uint112 reserve0, uint112 reserve1, , ) = camelotBalancedPair.getReserves();

        assertEq(knownReserve, reserve0, "Zero address should default to token0 reserve");
        assertEq(opposingReserve, reserve1, "Opposing should be token1 reserve");
    }

    /* ---------------------------------------------------------------------- */
    /*                            Fuzz Tests                                   */
    /* ---------------------------------------------------------------------- */

    function testFuzz_swap_anyAmount_producesOutput(uint256 swapAmount) public {
        _initializeCamelotBalancedPools();

        // Bound swap amount to reasonable range (avoid too small or too large)
        swapAmount = bound(swapAmount, 1e15, 1000e18);

        camelotBalancedTokenA.mint(address(this), swapAmount);
        camelotBalancedTokenA.approve(address(camelotV2Router), swapAmount);

        uint256 amountOut = CamelotV2Service._swap(
            camelotV2Router,
            camelotBalancedPair,
            swapAmount,
            camelotBalancedTokenA,
            camelotBalancedTokenB,
            address(0)
        );

        assertGt(amountOut, 0, "Any reasonable swap should produce output");
    }

    function testFuzz_swapDeposit_anyAmount_producesLP(uint256 depositAmount) public {
        _initializeCamelotBalancedPools();

        // Bound deposit amount to reasonable range
        depositAmount = bound(depositAmount, 1e16, 5000e18);

        camelotBalancedTokenA.mint(address(this), depositAmount);
        camelotBalancedTokenA.approve(address(camelotV2Router), depositAmount);

        uint256 lpAmount = CamelotV2Service._swapDeposit(
            camelotV2Router,
            camelotBalancedPair,
            camelotBalancedTokenA,
            depositAmount,
            camelotBalancedTokenB,
            address(0)
        );

        assertGt(lpAmount, 0, "Any reasonable deposit should produce LP tokens");
    }

    /* ---------------------------------------------------------------------- */
    /*                           Helper Functions                              */
    /* ---------------------------------------------------------------------- */

    function _calculateWithdrawAmounts(ICamelotPair pair, uint256 lpAmount) internal view returns (uint256, uint256) {
        (uint112 reserve0, uint112 reserve1, , ) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        uint256 amount0 = (lpAmount * reserve0) / totalSupply;
        uint256 amount1 = (lpAmount * reserve1) / totalSupply;
        return (amount0, amount1);
    }
}
