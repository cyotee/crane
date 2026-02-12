// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IPool} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPool.sol";
import {IRouter} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol";
import {IPoolFactory} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPoolFactory.sol";
import {AerodromeServiceVolatile} from "@crane/contracts/protocols/dexes/aerodrome/v1/services/AerodromeServiceVolatile.sol";
import {TestBase_Aerodrome_Pools} from "@crane/contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome_Pools.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

/**
 * @title AerodromeServiceVolatile_Test
 * @notice Tests for the AerodromeServiceVolatile library functions
 * @dev Tests volatile pool operations (xy = k curve)
 */
contract AerodromeServiceVolatile_Test is TestBase_Aerodrome_Pools {
    using ConstProdUtils for uint256;

    /* ---------------------------------------------------------------------- */
    /*                                 Setup                                   */
    /* ---------------------------------------------------------------------- */

    function setUp() public override {
        TestBase_Aerodrome_Pools.setUp();
    }

    /* ---------------------------------------------------------------------- */
    /*                       _swapVolatile() Tests                             */
    /* ---------------------------------------------------------------------- */

    function test_swapVolatile_normalSwap_returnsExpectedOutput() public {
        _initializeAerodromeBalancedPools();

        uint256 swapAmount = 100e18;
        aeroBalancedTokenA.mint(address(this), swapAmount);

        uint256 balanceBefore = aeroBalancedTokenB.balanceOf(address(this));

        // Execute swap using the new library
        AerodromeServiceVolatile.SwapVolatileParams memory params = AerodromeServiceVolatile.SwapVolatileParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroBalancedPool)),
            tokenIn: IERC20(address(aeroBalancedTokenA)),
            tokenOut: IERC20(address(aeroBalancedTokenB)),
            amountIn: swapAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountOut = AerodromeServiceVolatile._swapVolatile(params);

        uint256 balanceAfter = aeroBalancedTokenB.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(actualReceived, amountOut, "Actual received should match returned amount");
        assertGt(amountOut, 0, "Output amount should be positive");
        // Swap output should be close to input minus fees (within ~3% for 0.3% fee pool)
        assertGt(amountOut, swapAmount * 97 / 100, "Output should be close to input for balanced pool");
    }

    function test_swapVolatile_reverseDirection_swapsCorrectly() public {
        _initializeAerodromeBalancedPools();

        uint256 swapAmount = 100e18;
        aeroBalancedTokenB.mint(address(this), swapAmount);

        uint256 balanceBefore = aeroBalancedTokenA.balanceOf(address(this));

        AerodromeServiceVolatile.SwapVolatileParams memory params = AerodromeServiceVolatile.SwapVolatileParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroBalancedPool)),
            tokenIn: IERC20(address(aeroBalancedTokenB)),
            tokenOut: IERC20(address(aeroBalancedTokenA)),
            amountIn: swapAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountOut = AerodromeServiceVolatile._swapVolatile(params);

        uint256 balanceAfter = aeroBalancedTokenA.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(actualReceived, amountOut, "Actual received should match returned amount");
        assertGt(amountOut, 0, "Reverse swap should produce output");
    }

    function test_swapVolatile_unbalancedPool_accountsForPriceImpact() public {
        _initializeAerodromeUnbalancedPools();

        uint256 swapAmount = 100e18;
        aeroUnbalancedTokenA.mint(address(this), swapAmount);

        uint256 balanceBefore = aeroUnbalancedTokenB.balanceOf(address(this));

        AerodromeServiceVolatile.SwapVolatileParams memory params = AerodromeServiceVolatile.SwapVolatileParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroUnbalancedPool)),
            tokenIn: IERC20(address(aeroUnbalancedTokenA)),
            tokenOut: IERC20(address(aeroUnbalancedTokenB)),
            amountIn: swapAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountOut = AerodromeServiceVolatile._swapVolatile(params);

        uint256 balanceAfter = aeroUnbalancedTokenB.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(actualReceived, amountOut, "Actual received should match returned amount");
        assertGt(amountOut, 0, "Swap should produce output");
        // In unbalanced pool (10:1 ratio), swapping tokenA for tokenB produces less output
        // due to price impact on the smaller reserve
        assertLt(amountOut, swapAmount, "Output should be less than input in unbalanced pool");
    }

    /* ---------------------------------------------------------------------- */
    /*                  _swapDepositVolatile() Tests                           */
    /* ---------------------------------------------------------------------- */

    function test_swapDepositVolatile_balancedPool_mintsLP() public {
        _initializeAerodromeBalancedPools();

        uint256 depositAmount = 1000e18;
        aeroBalancedTokenA.mint(address(this), depositAmount);

        uint256 lpBefore = aeroBalancedPool.balanceOf(address(this));

        address token0 = aeroBalancedPool.token0();
        IERC20 token0Ierc20 = IERC20(token0);

        AerodromeServiceVolatile.SwapDepositVolatileParams memory params = AerodromeServiceVolatile.SwapDepositVolatileParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroBalancedPool)),
            token0: token0Ierc20,
            tokenIn: IERC20(address(aeroBalancedTokenA)),
            opposingToken: IERC20(address(aeroBalancedTokenB)),
            amountIn: depositAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 lpAmount = AerodromeServiceVolatile._swapDepositVolatile(params);

        uint256 lpAfter = aeroBalancedPool.balanceOf(address(this));

        assertGt(lpAmount, 0, "Should mint LP tokens");
        assertEq(lpAfter - lpBefore, lpAmount, "LP balance should increase by minted amount");
    }

    function test_swapDepositVolatile_unbalancedPool_mintsLP() public {
        _initializeAerodromeUnbalancedPools();

        uint256 depositAmount = 500e18;
        aeroUnbalancedTokenA.mint(address(this), depositAmount);

        uint256 lpBefore = aeroUnbalancedPool.balanceOf(address(this));

        address token0 = aeroUnbalancedPool.token0();
        IERC20 token0Ierc20 = IERC20(token0);

        AerodromeServiceVolatile.SwapDepositVolatileParams memory params = AerodromeServiceVolatile.SwapDepositVolatileParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroUnbalancedPool)),
            token0: token0Ierc20,
            tokenIn: IERC20(address(aeroUnbalancedTokenA)),
            opposingToken: IERC20(address(aeroUnbalancedTokenB)),
            amountIn: depositAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 lpAmount = AerodromeServiceVolatile._swapDepositVolatile(params);

        uint256 lpAfter = aeroUnbalancedPool.balanceOf(address(this));

        assertGt(lpAmount, 0, "Should mint LP tokens in unbalanced pool");
        assertEq(lpAfter - lpBefore, lpAmount, "LP balance should increase");
    }

    function test_swapDepositVolatile_fromTokenB_mintsLP() public {
        _initializeAerodromeBalancedPools();

        uint256 depositAmount = 1000e18;
        aeroBalancedTokenB.mint(address(this), depositAmount);

        uint256 lpBefore = aeroBalancedPool.balanceOf(address(this));

        address token0 = aeroBalancedPool.token0();
        IERC20 token0Ierc20 = IERC20(token0);

        AerodromeServiceVolatile.SwapDepositVolatileParams memory params = AerodromeServiceVolatile.SwapDepositVolatileParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroBalancedPool)),
            token0: token0Ierc20,
            tokenIn: IERC20(address(aeroBalancedTokenB)),
            opposingToken: IERC20(address(aeroBalancedTokenA)),
            amountIn: depositAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 lpAmount = AerodromeServiceVolatile._swapDepositVolatile(params);

        uint256 lpAfter = aeroBalancedPool.balanceOf(address(this));

        assertGt(lpAmount, 0, "Should mint LP tokens when depositing token B");
        assertEq(lpAfter - lpBefore, lpAmount, "LP balance should increase");
    }

    /* ---------------------------------------------------------------------- */
    /*                  _withdrawSwapVolatile() Tests                          */
    /* ---------------------------------------------------------------------- */

    function test_withdrawSwapVolatile_fullWithdrawal_returnsTargetToken() public {
        _initializeAerodromeBalancedPools();

        uint256 lpBalance = aeroBalancedPool.balanceOf(address(this));
        assertGt(lpBalance, 0, "Should have LP tokens to withdraw");

        // Approve LP tokens for router
        aeroBalancedPool.approve(address(aerodromeRouter), lpBalance);

        uint256 balanceBBefore = aeroBalancedTokenB.balanceOf(address(this));

        AerodromeServiceVolatile.WithdrawSwapVolatileParams memory params = AerodromeServiceVolatile.WithdrawSwapVolatileParams({
            aerodromeRouter: IRouter(address(aerodromeRouter)),
            pool: IPool(address(aeroBalancedPool)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            tokenOut: IERC20(address(aeroBalancedTokenB)),
            opposingToken: IERC20(address(aeroBalancedTokenA)),
            lpBurnAmt: lpBalance,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountOut = AerodromeServiceVolatile._withdrawSwapVolatile(params);

        uint256 balanceBAfter = aeroBalancedTokenB.balanceOf(address(this));

        assertGt(amountOut, 0, "Should receive output tokens");
        assertEq(balanceBAfter - balanceBBefore, amountOut, "Balance increase should match returned amount");
        assertEq(aeroBalancedPool.balanceOf(address(this)), 0, "LP should be fully burned");
    }

    function test_withdrawSwapVolatile_partialWithdrawal_returnsTargetToken() public {
        _initializeAerodromeBalancedPools();

        uint256 lpBalance = aeroBalancedPool.balanceOf(address(this));
        uint256 withdrawAmount = lpBalance / 2;

        aeroBalancedPool.approve(address(aerodromeRouter), withdrawAmount);

        uint256 balanceABefore = aeroBalancedTokenA.balanceOf(address(this));

        AerodromeServiceVolatile.WithdrawSwapVolatileParams memory params = AerodromeServiceVolatile.WithdrawSwapVolatileParams({
            aerodromeRouter: IRouter(address(aerodromeRouter)),
            pool: IPool(address(aeroBalancedPool)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            tokenOut: IERC20(address(aeroBalancedTokenA)),
            opposingToken: IERC20(address(aeroBalancedTokenB)),
            lpBurnAmt: withdrawAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountOut = AerodromeServiceVolatile._withdrawSwapVolatile(params);

        uint256 balanceAAfter = aeroBalancedTokenA.balanceOf(address(this));

        assertGt(amountOut, 0, "Should receive output tokens");
        assertEq(balanceAAfter - balanceABefore, amountOut, "Balance increase should match");
        assertEq(aeroBalancedPool.balanceOf(address(this)), lpBalance - withdrawAmount, "Should have remaining LP");
    }

    /* ---------------------------------------------------------------------- */
    /*              _quoteSwapDepositSaleAmtVolatile() Tests                    */
    /* ---------------------------------------------------------------------- */

    function test_quoteSwapDepositSaleAmtVolatile_returnsPositiveAmount() public {
        _initializeAerodromeBalancedPools();

        address token0 = aeroBalancedPool.token0();
        IERC20 token0Ierc20 = IERC20(token0);

        AerodromeServiceVolatile.SwapDepositVolatileParams memory params = AerodromeServiceVolatile.SwapDepositVolatileParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroBalancedPool)),
            token0: token0Ierc20,
            tokenIn: IERC20(address(aeroBalancedTokenA)),
            opposingToken: IERC20(address(aeroBalancedTokenB)),
            amountIn: 1000e18,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 saleAmt = AerodromeServiceVolatile._quoteSwapDepositSaleAmtVolatile(params);

        assertGt(saleAmt, 0, "Sale amount should be positive");
        assertLt(saleAmt, params.amountIn, "Sale amount should be less than input");
    }

    /* ---------------------------------------------------------------------- */
    /*                            Fuzz Tests                                   */
    /* ---------------------------------------------------------------------- */

    function testFuzz_swapVolatile_anyAmount_producesOutput(uint256 swapAmount) public {
        _initializeAerodromeBalancedPools();

        // Bound swap amount to reasonable range (avoid too small or too large)
        swapAmount = bound(swapAmount, 1e15, 1000e18);

        aeroBalancedTokenA.mint(address(this), swapAmount);

        AerodromeServiceVolatile.SwapVolatileParams memory params = AerodromeServiceVolatile.SwapVolatileParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroBalancedPool)),
            tokenIn: IERC20(address(aeroBalancedTokenA)),
            tokenOut: IERC20(address(aeroBalancedTokenB)),
            amountIn: swapAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountOut = AerodromeServiceVolatile._swapVolatile(params);

        assertGt(amountOut, 0, "Any reasonable swap should produce output");
    }

    function testFuzz_swapDepositVolatile_anyAmount_producesLP(uint256 depositAmount) public {
        _initializeAerodromeBalancedPools();

        // Bound deposit amount to reasonable range
        depositAmount = bound(depositAmount, 1e16, 5000e18);

        aeroBalancedTokenA.mint(address(this), depositAmount);

        address token0 = aeroBalancedPool.token0();
        IERC20 token0Ierc20 = IERC20(token0);

        AerodromeServiceVolatile.SwapDepositVolatileParams memory params = AerodromeServiceVolatile.SwapDepositVolatileParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroBalancedPool)),
            token0: token0Ierc20,
            tokenIn: IERC20(address(aeroBalancedTokenA)),
            opposingToken: IERC20(address(aeroBalancedTokenB)),
            amountIn: depositAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 lpAmount = AerodromeServiceVolatile._swapDepositVolatile(params);

        assertGt(lpAmount, 0, "Any reasonable deposit should produce LP tokens");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Integration Tests                                 */
    /* ---------------------------------------------------------------------- */

    function test_integration_swapDepositWithdrawSwap_roundTrip() public {
        _initializeAerodromeBalancedPools();

        uint256 initialAmount = 1000e18;
        aeroBalancedTokenA.mint(address(this), initialAmount);

        // Step 1: Swap deposit to get LP
        address token0 = aeroBalancedPool.token0();
        IERC20 token0Ierc20 = IERC20(token0);

        AerodromeServiceVolatile.SwapDepositVolatileParams memory depositParams = AerodromeServiceVolatile.SwapDepositVolatileParams({
            router: IRouter(address(aerodromeRouter)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            pool: IPool(address(aeroBalancedPool)),
            token0: token0Ierc20,
            tokenIn: IERC20(address(aeroBalancedTokenA)),
            opposingToken: IERC20(address(aeroBalancedTokenB)),
            amountIn: initialAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 lpAmount = AerodromeServiceVolatile._swapDepositVolatile(depositParams);
        assertGt(lpAmount, 0, "Should have LP tokens after deposit");

        // Step 2: Withdraw swap to get back tokenA
        aeroBalancedPool.approve(address(aerodromeRouter), lpAmount);

        AerodromeServiceVolatile.WithdrawSwapVolatileParams memory withdrawParams = AerodromeServiceVolatile.WithdrawSwapVolatileParams({
            aerodromeRouter: IRouter(address(aerodromeRouter)),
            pool: IPool(address(aeroBalancedPool)),
            factory: IPoolFactory(address(aerodromePoolFactory)),
            tokenOut: IERC20(address(aeroBalancedTokenA)),
            opposingToken: IERC20(address(aeroBalancedTokenB)),
            lpBurnAmt: lpAmount,
            recipient: address(this),
            deadline: block.timestamp + 300
        });

        uint256 amountBack = AerodromeServiceVolatile._withdrawSwapVolatile(withdrawParams);

        // Should get back close to initial amount minus fees
        assertGt(amountBack, 0, "Should receive tokens back");
        // Allow for up to 5% loss due to fees and slippage
        assertGt(amountBack, initialAmount * 95 / 100, "Should receive at least 95% back");
    }
}
