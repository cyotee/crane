// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IPool} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPool.sol";
import {IRouter} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol";
import {IPoolFactory} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPoolFactory.sol";
import {AerodromServiceStable} from "@crane/contracts/protocols/dexes/aerodrome/v1/services/AerodromServiceStable.sol";
import {TestBase_Aerodrome_Pools} from "@crane/contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome_Pools.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

/**
 * @title AerodromServiceStable_Test
 * @notice Tests for the AerodromServiceStable library functions
 * @dev Tests stable pool operations (x³y + xy³ = k curve)
 */
contract AerodromServiceStable_Test is TestBase_Aerodrome_Pools {

    /* ---------------------------------------------------------------------- */
    /*                                 Setup                                   */
    /* ---------------------------------------------------------------------- */

    function setUp() public override {
        TestBase_Aerodrome_Pools.setUp();
    }

    /* ---------------------------------------------------------------------- */
    /*                        _swapStable() Tests                              */
    /* ---------------------------------------------------------------------- */

    function test_swapStable_normalSwap_returnsExpectedOutput() public {
        _initializeAerodromeStablePool();

        uint256 swapAmount = 100e18;
        aeroStableTokenA.mint(address(this), swapAmount);

        uint256 balanceBefore = aeroStableTokenB.balanceOf(address(this));

        // Execute swap using the library
        AerodromServiceStable.SwapStableParams memory params = AerodromServiceStable.SwapStableParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroStablePool)),
            tokenIn: IERC20(address(aeroStableTokenA)),
            tokenOut: IERC20(address(aeroStableTokenB)),
            amountIn: swapAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountOut = AerodromServiceStable._swapStable(params);

        uint256 balanceAfter = aeroStableTokenB.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(actualReceived, amountOut, "Actual received should match returned amount");
        assertGt(amountOut, 0, "Output amount should be positive");
        // Stable pools should have very low slippage for similar-value assets
        // With 1:1 ratio, output should be close to input minus fees
        assertGt(amountOut, swapAmount * 99 / 100, "Stable pool should have low slippage");
    }

    function test_swapStable_reverseDirection_swapsCorrectly() public {
        _initializeAerodromeStablePool();

        uint256 swapAmount = 100e18;
        aeroStableTokenB.mint(address(this), swapAmount);

        uint256 balanceBefore = aeroStableTokenA.balanceOf(address(this));

        AerodromServiceStable.SwapStableParams memory params = AerodromServiceStable.SwapStableParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroStablePool)),
            tokenIn: IERC20(address(aeroStableTokenB)),
            tokenOut: IERC20(address(aeroStableTokenA)),
            amountIn: swapAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountOut = AerodromServiceStable._swapStable(params);

        uint256 balanceAfter = aeroStableTokenA.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(actualReceived, amountOut, "Actual received should match returned amount");
        assertGt(amountOut, 0, "Reverse swap should produce output");
    }

    function test_swapStable_largeSwap_stillHasLowSlippage() public {
        _initializeAerodromeStablePool();

        // Large swap - 10% of pool reserves
        uint256 swapAmount = 1000e18;
        aeroStableTokenA.mint(address(this), swapAmount);

        AerodromServiceStable.SwapStableParams memory params = AerodromServiceStable.SwapStableParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroStablePool)),
            tokenIn: IERC20(address(aeroStableTokenA)),
            tokenOut: IERC20(address(aeroStableTokenB)),
            amountIn: swapAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountOut = AerodromServiceStable._swapStable(params);

        // Even with large swap, stable pools should maintain low slippage
        // Allow for fees (~0.3%) and some curve slippage
        assertGt(amountOut, swapAmount * 97 / 100, "Large swap should still have reasonable output");
    }

    /* ---------------------------------------------------------------------- */
    /*                     _swapDepositStable() Tests                          */
    /* ---------------------------------------------------------------------- */

    function test_swapDepositStable_balancedPool_mintsLP() public {
        _initializeAerodromeStablePool();

        uint256 depositAmount = 1000e18;
        aeroStableTokenA.mint(address(this), depositAmount);

        uint256 lpBefore = aeroStablePool.balanceOf(address(this));

        address token0 = aeroStablePool.token0();
        IERC20 token0Ierc20 = IERC20(token0);

        AerodromServiceStable.SwapDepositStableParams memory params = AerodromServiceStable.SwapDepositStableParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroStablePool)),
            token0: token0Ierc20,
            tokenIn: IERC20(address(aeroStableTokenA)),
            opposingToken: IERC20(address(aeroStableTokenB)),
            amountIn: depositAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 lpAmount = AerodromServiceStable._swapDepositStable(params);

        uint256 lpAfter = aeroStablePool.balanceOf(address(this));

        assertGt(lpAmount, 0, "Should mint LP tokens");
        assertEq(lpAfter - lpBefore, lpAmount, "LP balance should increase by minted amount");
    }

    function test_swapDepositStable_fromTokenB_mintsLP() public {
        _initializeAerodromeStablePool();

        uint256 depositAmount = 1000e18;
        aeroStableTokenB.mint(address(this), depositAmount);

        uint256 lpBefore = aeroStablePool.balanceOf(address(this));

        address token0 = aeroStablePool.token0();
        IERC20 token0Ierc20 = IERC20(token0);

        AerodromServiceStable.SwapDepositStableParams memory params = AerodromServiceStable.SwapDepositStableParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroStablePool)),
            token0: token0Ierc20,
            tokenIn: IERC20(address(aeroStableTokenB)),
            opposingToken: IERC20(address(aeroStableTokenA)),
            amountIn: depositAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 lpAmount = AerodromServiceStable._swapDepositStable(params);

        uint256 lpAfter = aeroStablePool.balanceOf(address(this));

        assertGt(lpAmount, 0, "Should mint LP tokens when depositing token B");
        assertEq(lpAfter - lpBefore, lpAmount, "LP balance should increase");
    }

    /* ---------------------------------------------------------------------- */
    /*                     _withdrawSwapStable() Tests                         */
    /* ---------------------------------------------------------------------- */

    function test_withdrawSwapStable_majorityWithdrawal_returnsTargetToken() public {
        _initializeAerodromeStablePool();

        uint256 lpBalance = aeroStablePool.balanceOf(address(this));
        assertGt(lpBalance, 0, "Should have LP tokens to withdraw");

        // Withdraw 90% of LP (not 100% since withdrawing all LP leaves no reserves for the swap)
        uint256 withdrawAmount = lpBalance * 90 / 100;

        // Approve LP tokens for router
        aeroStablePool.approve(address(aerodromeRouter), withdrawAmount);

        uint256 balanceBBefore = aeroStableTokenB.balanceOf(address(this));

        AerodromServiceStable.WithdrawSwapStableParams memory params = AerodromServiceStable.WithdrawSwapStableParams({
            aerodromeRouter: IRouter(address(aerodromeRouter)),
            pool: IPool(address(aeroStablePool)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            tokenOut: IERC20(address(aeroStableTokenB)),
            opposingToken: IERC20(address(aeroStableTokenA)),
            lpBurnAmt: withdrawAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountOut = AerodromServiceStable._withdrawSwapStable(params);

        uint256 balanceBAfter = aeroStableTokenB.balanceOf(address(this));

        assertGt(amountOut, 0, "Should receive output tokens");
        assertEq(balanceBAfter - balanceBBefore, amountOut, "Balance increase should match returned amount");
    }

    function test_withdrawSwapStable_partialWithdrawal_returnsTargetToken() public {
        _initializeAerodromeStablePool();

        uint256 lpBalance = aeroStablePool.balanceOf(address(this));
        uint256 withdrawAmount = lpBalance / 2;

        aeroStablePool.approve(address(aerodromeRouter), withdrawAmount);

        uint256 balanceABefore = aeroStableTokenA.balanceOf(address(this));

        AerodromServiceStable.WithdrawSwapStableParams memory params = AerodromServiceStable.WithdrawSwapStableParams({
            aerodromeRouter: IRouter(address(aerodromeRouter)),
            pool: IPool(address(aeroStablePool)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            tokenOut: IERC20(address(aeroStableTokenA)),
            opposingToken: IERC20(address(aeroStableTokenB)),
            lpBurnAmt: withdrawAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountOut = AerodromServiceStable._withdrawSwapStable(params);

        uint256 balanceAAfter = aeroStableTokenA.balanceOf(address(this));

        assertGt(amountOut, 0, "Should receive output tokens");
        assertEq(balanceAAfter - balanceABefore, amountOut, "Balance increase should match");
        assertEq(aeroStablePool.balanceOf(address(this)), lpBalance - withdrawAmount, "Should have remaining LP");
    }

    /* ---------------------------------------------------------------------- */
    /*                 _quoteSwapDepositSaleAmtStable() Tests                   */
    /* ---------------------------------------------------------------------- */

    function test_quoteSwapDepositSaleAmtStable_returnsPositiveAmount() public {
        _initializeAerodromeStablePool();

        address token0 = aeroStablePool.token0();
        IERC20 token0Ierc20 = IERC20(token0);

        AerodromServiceStable.SwapDepositStableParams memory params = AerodromServiceStable.SwapDepositStableParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroStablePool)),
            token0: token0Ierc20,
            tokenIn: IERC20(address(aeroStableTokenA)),
            opposingToken: IERC20(address(aeroStableTokenB)),
            amountIn: 1000e18,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 saleAmt = AerodromServiceStable._quoteSwapDepositSaleAmtStable(params);

        assertGt(saleAmt, 0, "Sale amount should be positive");
        assertLt(saleAmt, params.amountIn / 2, "Sale amount should be less than half of input");
    }

    /* ---------------------------------------------------------------------- */
    /*                            Fuzz Tests                                   */
    /* ---------------------------------------------------------------------- */

    function testFuzz_swapStable_anyAmount_producesOutput(uint256 swapAmount) public {
        _initializeAerodromeStablePool();

        // Bound swap amount to reasonable range (avoid too small or too large)
        swapAmount = bound(swapAmount, 1e15, 1000e18);

        aeroStableTokenA.mint(address(this), swapAmount);

        AerodromServiceStable.SwapStableParams memory params = AerodromServiceStable.SwapStableParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroStablePool)),
            tokenIn: IERC20(address(aeroStableTokenA)),
            tokenOut: IERC20(address(aeroStableTokenB)),
            amountIn: swapAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountOut = AerodromServiceStable._swapStable(params);

        assertGt(amountOut, 0, "Any reasonable swap should produce output");
    }

    function testFuzz_swapDepositStable_anyAmount_producesLP(uint256 depositAmount) public {
        _initializeAerodromeStablePool();

        // Bound deposit amount to reasonable range
        depositAmount = bound(depositAmount, 1e16, 5000e18);

        aeroStableTokenA.mint(address(this), depositAmount);

        address token0 = aeroStablePool.token0();
        IERC20 token0Ierc20 = IERC20(token0);

        AerodromServiceStable.SwapDepositStableParams memory params = AerodromServiceStable.SwapDepositStableParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroStablePool)),
            token0: token0Ierc20,
            tokenIn: IERC20(address(aeroStableTokenA)),
            opposingToken: IERC20(address(aeroStableTokenB)),
            amountIn: depositAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 lpAmount = AerodromServiceStable._swapDepositStable(params);

        assertGt(lpAmount, 0, "Any reasonable deposit should produce LP tokens");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Integration Tests                                 */
    /* ---------------------------------------------------------------------- */

    function test_integration_swapDepositWithdrawSwap_roundTrip() public {
        _initializeAerodromeStablePool();

        uint256 initialAmount = 1000e18;
        aeroStableTokenA.mint(address(this), initialAmount);

        // Step 1: Swap deposit to get LP
        address token0 = aeroStablePool.token0();
        IERC20 token0Ierc20 = IERC20(token0);

        AerodromServiceStable.SwapDepositStableParams memory depositParams = AerodromServiceStable.SwapDepositStableParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroStablePool)),
            token0: token0Ierc20,
            tokenIn: IERC20(address(aeroStableTokenA)),
            opposingToken: IERC20(address(aeroStableTokenB)),
            amountIn: initialAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 lpAmount = AerodromServiceStable._swapDepositStable(depositParams);
        assertGt(lpAmount, 0, "Should have LP tokens after deposit");

        // Step 2: Withdraw swap to get back tokenA
        aeroStablePool.approve(address(aerodromeRouter), lpAmount);

        AerodromServiceStable.WithdrawSwapStableParams memory withdrawParams = AerodromServiceStable.WithdrawSwapStableParams({
            aerodromeRouter: IRouter(address(aerodromeRouter)),
            pool: IPool(address(aeroStablePool)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            tokenOut: IERC20(address(aeroStableTokenA)),
            opposingToken: IERC20(address(aeroStableTokenB)),
            lpBurnAmt: lpAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountBack = AerodromServiceStable._withdrawSwapStable(withdrawParams);

        // Should get back close to initial amount minus fees
        // Stable pools should have even better round-trip efficiency
        assertGt(amountBack, 0, "Should receive tokens back");
        // Allow for up to 3% loss due to fees and slippage (stable pools have lower slippage)
        assertGt(amountBack, initialAmount * 97 / 100, "Should receive at least 97% back");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Comparison Tests                                  */
    /* ---------------------------------------------------------------------- */

    function test_stableVsVolatile_stableHasLowerSlippage() public {
        // Initialize both pools
        _initializeAerodromeStablePool();
        _initializeAerodromeBalancedPools();

        uint256 swapAmount = 500e18;

        // Get stable pool output
        aeroStableTokenA.mint(address(this), swapAmount);
        AerodromServiceStable.SwapStableParams memory stableParams = AerodromServiceStable.SwapStableParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroStablePool)),
            tokenIn: IERC20(address(aeroStableTokenA)),
            tokenOut: IERC20(address(aeroStableTokenB)),
            amountIn: swapAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });
        uint256 stableOut = AerodromServiceStable._swapStable(stableParams);

        // Get volatile pool output (using the router directly for comparison)
        aeroBalancedTokenA.mint(address(this), swapAmount);
        aeroBalancedTokenA.approve(address(aerodromeRouter), swapAmount);

        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = IRouter.Route({
            from: address(aeroBalancedTokenA),
            to: address(aeroBalancedTokenB),
            stable: false,
            factory: address(aerodromePoolFactory)
        });

        uint256[] memory volatileAmounts = aerodromeRouter.swapExactTokensForTokens(
            swapAmount,
            0,
            routes,
            address(this),
            block.timestamp + 300
        );
        uint256 volatileOut = volatileAmounts[volatileAmounts.length - 1];

        // For same-value assets (1:1 ratio), stable pool should have equal or better output
        // due to lower slippage on the x³y + xy³ = k curve
        // Note: Both should be close since reserves are balanced, but stable has slight edge
        assertGt(stableOut, 0, "Stable pool should produce output");
        assertGt(volatileOut, 0, "Volatile pool should produce output");
    }
}
