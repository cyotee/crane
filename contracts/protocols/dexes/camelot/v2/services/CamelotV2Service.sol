// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

// import "hardhat/console.sol";
// import "forge-std/console.sol";
// import "forge-std/console2.sol";

// import {BetterIERC20 as IERC20} from "@crane/contracts/interfaces/BetterIERC20.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

import {BetterSafeERC20 as SafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";

import {ICamelotPair} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotFactory} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotV2Router} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

library CamelotV2Service {
    using ConstProdUtils for uint256;
    // using CamelotV2Utils for uint256;
    using CamelotV2Service for ICamelotPair;
    using CamelotV2Service for ICamelotV2Router;
    using SafeERC20 for IERC20;

    // Struct to help avoid stack too deep errors
    struct ReserveInfo {
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 feePercent;
        uint256 unknownFee;
    }

    struct SwapParams {
        ICamelotV2Router router;
        uint256 amountIn;
        IERC20 tokenIn;
        uint256 reserveIn;
        uint256 feePercent;
        IERC20 tokenOut;
        uint256 reserveOut;
        address referrer;
    }

    struct BalanceParams {
        ICamelotV2Router router;
        uint256 saleAmt;
        IERC20 tokenIn;
        uint256 saleReserve;
        uint256 saleTokenFeePerc;
        IERC20 tokenOut;
        uint256 reserveOut;
        address referrer;
    }

    /* ---------------------------------------------------------------------- */
    /*                                 Deposit                                */
    /* ---------------------------------------------------------------------- */

    function _deposit(
        ICamelotV2Router router,
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amountADesired,
        uint256 amountBDesired
    ) internal returns (uint256 liquidity) {
        tokenA.approve(address(router), amountADesired);
        tokenB.approve(address(router), amountBDesired);
        (,, liquidity) = router.addLiquidity(
            address(tokenA), address(tokenB), amountADesired, amountBDesired, 1, 1, address(this), block.timestamp
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                                Withdraw                                */
    /* ---------------------------------------------------------------------- */

    function _withdrawDirect(ICamelotPair pool, uint256 amt) internal returns (uint256 amount0, uint256 amount1) {
        pool.transfer(address(pool), amt);
        (amount0, amount1) = pool.burn(address(this));
    }

    /* ---------------------------------------------------------------------- */
    /*                                  Swap                                  */
    /* ---------------------------------------------------------------------- */

    // Helper function to create path and approve token
    function _prepareSwap(SwapParams memory params) private returns (address[] memory path) {
        path = new address[](2);
        path[0] = address(params.tokenIn);
        path[1] = address(params.tokenOut);
        params.tokenIn.approve(address(params.router), params.amountIn);
        return path;
    }

    // Helper function to perform router swap
    function _executeSwap(SwapParams memory params, address[] memory path) private {
        params.router
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                params.amountIn,
                1, // uint amountOutMin
                path,
                address(this), // address to
                params.referrer,
                block.timestamp // uint deadline
            );
    }

    function _swap(
        ICamelotV2Router router,
        uint256 amountIn,
        IERC20 tokenIn,
        uint256 reserveIn,
        uint256 feePercent,
        IERC20 tokenOut,
        uint256 reserveOut,
        address referrer
    ) internal returns (uint256 amountOut) {
        // Create parameter struct to avoid stack too deep error
        SwapParams memory params = SwapParams({
            router: router,
            amountIn: amountIn,
            tokenIn: tokenIn,
            reserveIn: reserveIn,
            feePercent: feePercent,
            tokenOut: tokenOut,
            reserveOut: reserveOut,
            referrer: referrer
        });

        // Calculate expected output
        amountOut = ConstProdUtils._saleQuote(params.amountIn, params.reserveIn, params.reserveOut, params.feePercent);

        // Prepare swap
        address[] memory path = _prepareSwap(params);

        // Execute swap
        _executeSwap(params, path);
    }

    function _swap(
        ICamelotV2Router router,
        ICamelotPair pool,
        uint256 amountIn,
        IERC20 tokenIn,
        IERC20 tokenOut,
        address referrer
    ) internal returns (uint256 amountOut) {
        // Get reserves and fees
        ReserveInfo memory reserves = _sortReservesStruct(pool, tokenIn);

        // Forward to the main swap function
        return _swap(
            router, amountIn, tokenIn, reserves.reserveIn, reserves.feePercent, tokenOut, reserves.reserveOut, referrer
        );
    }

    function _sortReserves(ICamelotPair pool, IERC20 knownToken) internal view returns (uint256 knownReserve, uint256 opposingReserve, uint256 knownFeePercent, uint256 opposingFeePercent) {
        ReserveInfo memory reserves = _sortReservesStruct(pool, knownToken);
        return (reserves.reserveIn, reserves.reserveOut, reserves.feePercent, reserves.unknownFee);
    }

    function _sortReservesStruct(ICamelotPair pool, IERC20 knownToken) internal view returns (ReserveInfo memory reserves) {
        (uint112 reserve0, uint112 reserve1, uint16 token0feePercent, uint16 token1FeePercent) = pool.getReserves();
        address token0 = pool.token0();
        if (address(knownToken) == address(0)) {
            knownToken = IERC20(token0);
        }

        if (address(knownToken) == token0) {
            reserves.reserveIn = reserve0;
            reserves.reserveOut = reserve1;
            reserves.feePercent = token0feePercent;
            reserves.unknownFee = token1FeePercent;
        } else {
            reserves.reserveIn = reserve1;
            reserves.reserveOut = reserve0;
            reserves.feePercent = token1FeePercent;
            reserves.unknownFee = token0feePercent;
        }

        return reserves;
    }

    function _swapDeposit(
        ICamelotV2Router router,
        ICamelotPair pool,
        IERC20 tokenIn,
        uint256 saleAmt,
        IERC20 opToken,
        address referrer
    ) internal returns (uint256) {
        // Get reserves
        ReserveInfo memory reserves = _sortReservesStruct(pool, tokenIn);

        // Create parameter struct to avoid stack too deep error
        BalanceParams memory params = BalanceParams({
            router: router,
            saleAmt: saleAmt,
            tokenIn: tokenIn,
            saleReserve: reserves.reserveIn,
            saleTokenFeePerc: reserves.feePercent,
            tokenOut: opToken,
            reserveOut: reserves.reserveOut,
            referrer: referrer
        });

        // Balance assets using the reserves
        uint256[] memory balancedAmounts = _balanceAssetsInternal(params);

        // Deposit balanced amounts
        uint256 poolTokenAmount = _deposit(router, tokenIn, opToken, balancedAmounts[0], balancedAmounts[1]);

        return poolTokenAmount;
    }

    function _balanceAssets(
        ICamelotV2Router router,
        ICamelotPair pool,
        uint256 saleAmt,
        IERC20 tokenIn,
        IERC20 tokenOut,
        address referrer
    ) internal returns (uint256[] memory amounts) {
        // Get reserves
        ReserveInfo memory reserves = _sortReservesStruct(pool, tokenIn);

        // Create parameter struct to avoid stack too deep error
        BalanceParams memory params = BalanceParams({
            router: router,
            saleAmt: saleAmt,
            tokenIn: tokenIn,
            saleReserve: reserves.reserveIn,
            saleTokenFeePerc: reserves.feePercent,
            tokenOut: tokenOut,
            reserveOut: reserves.reserveOut,
            referrer: referrer
        });

        // Use the helper with direct reserves
        return _balanceAssetsInternal(params);
    }

    function _balanceAssets(
        ICamelotV2Router router,
        uint256 saleAmt,
        IERC20 tokenIn,
        uint256 saleReserve,
        uint256 saleTokenFeePerc,
        IERC20 tokenOut,
        uint256 reserveOut,
        address referrer
    ) internal returns (uint256[] memory amounts) {
        // Package parameters to avoid stack too deep
        BalanceParams memory params = BalanceParams({
            router: router,
            saleAmt: saleAmt,
            tokenIn: tokenIn,
            saleReserve: saleReserve,
            saleTokenFeePerc: saleTokenFeePerc,
            tokenOut: tokenOut,
            reserveOut: reserveOut,
            referrer: referrer
        });

        return _balanceAssetsInternal(params);
    }

    // Helper function to implement _balanceAssets logic to avoid stack too deep
    function _balanceAssetsInternal(BalanceParams memory params) private returns (uint256[] memory amounts) {
        // Get amount of input token to be swapped
        uint256 swapAmountIn = _calculateSwapAmount(params.saleAmt, params.saleReserve, params.saleTokenFeePerc);

        amounts = new uint256[](2);
        amounts[0] = params.saleAmt - swapAmountIn;

        // Perform swap to get the second token
        amounts[1] = _swap(
            params.router,
            swapAmountIn,
            params.tokenIn,
            params.saleReserve,
            params.saleTokenFeePerc,
            params.tokenOut,
            params.reserveOut,
            params.referrer
        );

        return amounts;
    }

    // Helper function to calculate swap amount for balanced deposit
    function _calculateSwapAmount(uint256 saleAmt, uint256 saleReserve, uint256 saleTokenFeePerc)
        internal
        pure
        returns (uint256)
    {
        return ConstProdUtils._swapDepositSaleAmt(saleAmt, saleReserve, saleTokenFeePerc);
    }

    /* ---------------------------------------------------------------------- */
    /*                              Withdraw/Swap                             */
    /* ---------------------------------------------------------------------- */

    struct WithdrawSwapParams {
        ICamelotPair pool;
        ICamelotV2Router router;
        uint256 amt;
        IERC20 tokenOut;
        IERC20 opToken;
        address referrer;
    }

    function _withdrawSwapDirect(
        ICamelotPair pool,
        ICamelotV2Router router,
        uint256 amt,
        IERC20 tokenOut,
        IERC20 opToken,
        address referrer
    ) internal returns (uint256 amountOut) {
        // Create struct to avoid stack too deep
        WithdrawSwapParams memory params = WithdrawSwapParams({
            pool: pool, router: router, amt: amt, tokenOut: tokenOut, opToken: opToken, referrer: referrer
        });

        // Withdraw tokens from pool
        (uint256 amount0, uint256 amount1) = _withdrawDirect(params.pool, params.amt);

        // Determine which token is which
        (uint256 tokenOutWDAmt, uint256 saleTokenWDAmt) = _determineTokenAmounts(params, amount0, amount1);

        // Swap the other token to the target token and add to result
        uint256 proceedsAmount = _swapWithdrawnTokens(params, saleTokenWDAmt);
        amountOut = tokenOutWDAmt + proceedsAmount;
    }

    // Helper function to determine token amounts after withdrawal
    function _determineTokenAmounts(WithdrawSwapParams memory params, uint256 amount0, uint256 amount1)
        internal
        view
        returns (uint256 tokenOutAmount, uint256 saleTokenAmount)
    {
        address token0 = params.pool.token0();

        if (address(params.tokenOut) == token0) {
            tokenOutAmount = amount0;
            saleTokenAmount = amount1;
        } else {
            tokenOutAmount = amount1;
            saleTokenAmount = amount0;
        }
    }

    // Helper function to swap withdrawn tokens
    function _swapWithdrawnTokens(WithdrawSwapParams memory params, uint256 saleTokenWDAmt) internal returns (uint256) {
        return params.router._swap(params.pool, saleTokenWDAmt, params.opToken, params.tokenOut, params.referrer);
    }
}
