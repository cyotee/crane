// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IPool} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPool.sol";
import {IRouter} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol";
import {IPoolFactory} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPoolFactory.sol";

// tag::AerodromeServiceStable[]
/**
 * @title AerodromeServiceStable - Stateless library for Aerodrome V1 stable pool operations (x³y + xy³ = k): swaps, zap deposit/withdraw, and balanced liquidity quoting.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Internal-only API (prefixed _). Consumed via `using AerodromeServiceStable for ...` in targets/services or tests.
 * @dev Explicitly passes `stable: true` to router/pool calls. Dedicated stable math (binary search + Newton-Raphson in _getY).
 * @dev For volatile pools (xy = k), use AerodromeServiceVolatile instead. See legacy AerodromeService for migration notes.
 * @dev See AGENTS.md for *Service pattern (structs for params, internal helpers) and PRD LR-1 for NatSpec + include-tag requirements.
 * @dev Ties to LR-2 (protocol utility docs + usage in Aerodrome port tests).
 */
library AerodromeServiceStable {
    /* -------------------------------------------------------------------------- */
    /*                                  Constants                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Aerodrome fee denominator is 10000 (not 100000 like Uniswap V2)
    uint256 constant AERO_FEE_DENOM = 10000;

    /* -------------------------------------------------------------------------- */
    /*                                   Structs                                   */
    /* -------------------------------------------------------------------------- */

    // tag::SwapStableParams[]
    /**
     * @dev Internal param struct for _swapStable on stable pools.
     * Bundles router, factory, pool, tokens, amounts and execution params.
     */
    struct SwapStableParams {
        IRouter router;
        IPoolFactory factory;
        IPool pool;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amountIn;
        address recipient;
        uint256 deadline;
    }

    // end::SwapStableParams[]

    // tag::SwapDepositStableParams[]
    /**
     * @dev Internal param struct for _swapDepositStable and _quoteSwapDepositSaleAmtStable.
     * Includes token0 for reserve side determination and opposingToken for the zap leg.
     */
    struct SwapDepositStableParams {
        IRouter router;
        IPoolFactory factory;
        IPool pool;
        IERC20 token0;
        IERC20 tokenIn;
        IERC20 opposingToken;
        uint256 amountIn;
        address recipient;
        uint256 deadline;
    }

    // end::SwapDepositStableParams[]

    // tag::WithdrawSwapStableParams[]
    /**
     * @dev Internal param struct for _withdrawSwapStable (zap out).
     * Note: field order mirrors router.removeLiquidity + follow-on swap (aerodromeRouter first).
     */
    struct WithdrawSwapStableParams {
        IRouter aerodromeRouter;
        IPool pool;
        IPoolFactory factory;
        IERC20 tokenOut;
        IERC20 opposingToken;
        uint256 lpBurnAmt;
        address recipient;
        uint256 deadline;
    }

    // end::WithdrawSwapStableParams[]

    /* -------------------------------------------------------------------------- */
    /*                              Swap Functions                                 */
    /* -------------------------------------------------------------------------- */

    // tag::_swapStable(SwapStableParams)[]
    /**
     * @notice Swaps tokens in a stable pool.
     * Builds single-hop Route with stable=true, approves input, calls router.swapExactTokensForTokens (amountOutMin=0).
     * @dev Caller responsible for slippage protection via amountOutMin in wrappers.
     * @param params The swap parameters (includes router, factory, pool, tokenIn/Out, amountIn, recipient, deadline).
     * @return amountOut The amount of tokenOut received.
     * @custom:emits Transfer (approvals and token movements via router).
     */
    function _swapStable(SwapStableParams memory params) internal returns (uint256 amountOut) {
        IRouter.Route memory route = IRouter.Route({
            from: address(params.tokenIn),
            to: address(params.tokenOut),
            stable: true, // Stable pool
            factory: address(params.factory)
        });
        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = route;

        params.tokenIn.approve(address(params.router), params.amountIn);

        uint256[] memory amountsOut = params.router
            .swapExactTokensForTokens(
                params.amountIn,
                0, // amountOutMin - caller should implement slippage protection
                routes,
                params.recipient,
                params.deadline
            );

        return amountsOut[amountsOut.length - 1];
    }

    // end::_swapStable(SwapStableParams)[]

    /* -------------------------------------------------------------------------- */
    /*                           Swap-Deposit Functions                            */
    /* -------------------------------------------------------------------------- */

    // tag::_swapDepositStable(SwapDepositStableParams)[]
    /**
     * @notice Performs a swap-deposit (zap in) to a stable pool.
     * Swaps a portion of tokenIn for opposingToken (using stable math), then adds balanced liquidity via router.addLiquidity (stable=true).
     * @dev Invokes _quoteSwapDepositSaleAmtStable (binary search + Newton-Raphson). Recipient receives LP. Caller should apply slippage on final LP.
     * @param params The swap-deposit parameters (router/factory/pool/token0/tokenIn/opposing/amountIn/recipient/deadline).
     * @return lpOut The amount of LP tokens minted.
     * @custom:emits Transfer (approvals + underlying token transfers); Liquidity events via pool.
     */
    function _swapDepositStable(SwapDepositStableParams memory params) internal returns (uint256 lpOut) {
        // Calculate optimal swap amount using stable pool math
        uint256 swapAmount = _quoteSwapDepositSaleAmtStable(params);

        // Swap portion of tokenIn for opposingToken
        SwapStableParams memory swapParams = SwapStableParams({
            router: params.router,
            factory: params.factory,
            pool: params.pool,
            tokenIn: params.tokenIn,
            tokenOut: params.opposingToken,
            amountIn: swapAmount,
            recipient: address(this),
            deadline: params.deadline
        });
        uint256 swapAmountOut = _swapStable(swapParams);

        // Deposit remaining tokenIn and swapped opposingToken
        uint256 depositAmountIn = params.amountIn - swapAmount;
        params.tokenIn.approve(address(params.router), depositAmountIn);
        params.opposingToken.approve(address(params.router), swapAmountOut);

        (,, lpOut) = params.router
            .addLiquidity(
                address(params.tokenIn),
                address(params.opposingToken),
                true, // Stable pool
                depositAmountIn,
                swapAmountOut,
                0, // amountAMin - caller should implement slippage protection
                0, // amountBMin
                params.recipient,
                params.deadline
            );
    }

    // end::_swapDepositStable(SwapDepositStableParams)[]

    // tag::_quoteSwapDepositSaleAmtStable(SwapDepositStableParams)[]
    /**
     * @notice Calculates the optimal swap amount for a swap-deposit to a stable pool.
     * For stable pools, uses binary search (no closed form) because x³y + xy³ = k is non-linear.
     * @dev Reads pool.metadata() + factory.getFee(..., true); then delegates to _binarySearchOptimalSwapStable.
     * @param params The swap-deposit parameters.
     * @return saleAmt The optimal amount of tokenIn to swap for opposingToken.
     */
    function _quoteSwapDepositSaleAmtStable(SwapDepositStableParams memory params)
        internal
        view
        returns (uint256 saleAmt)
    {
        // Get pool metadata
        (
            uint256 decimals0,
            uint256 decimals1,
            uint256 reserve0,
            uint256 reserve1,, // stable (we know it's true)
            address token0,
            // address token1
        ) = params.pool.metadata();

        // Determine which reserves to use based on tokenIn
        bool tokenInIsToken0 = address(params.tokenIn) == token0;
        uint256 reserveIn = tokenInIsToken0 ? reserve0 : reserve1;
        uint256 reserveOut = tokenInIsToken0 ? reserve1 : reserve0;
        uint256 decimalsIn = tokenInIsToken0 ? decimals0 : decimals1;
        uint256 decimalsOut = tokenInIsToken0 ? decimals1 : decimals0;

        // Get fee for stable pool
        uint256 fee = params.factory.getFee(address(params.pool), true);

        // For stable pools, binary search for optimal swap amount
        // The goal is to find saleAmt such that after swapping:
        // (amountIn - saleAmt) / swapOutput ≈ reserveIn' / reserveOut'
        // This ensures a balanced deposit with minimal leftover
        saleAmt = _binarySearchOptimalSwapStable(params.amountIn, reserveIn, reserveOut, decimalsIn, decimalsOut, fee);
    }

    // end::_quoteSwapDepositSaleAmtStable(SwapDepositStableParams)[]

    // tag::_binarySearchOptimalSwapStable(uint256-uint256-uint256-uint256-uint256-uint256)[]
    /**
     * @notice Binary search to find optimal swap amount for stable pool deposit.
     * Iteratively searches (fixed 20 iters) for the swap amount that results in most balanced post-swap reserves ratio.
     * @dev Calls _getAmountOutStable per iteration (Newton-Raphson inside). Early exit if mid==low. Cubic curve requires numeric search.
     * @param amountIn Total amount being deposited.
     * @param reserveIn Reserve of the input token.
     * @param reserveOut Reserve of the output token.
     * @param decimalsIn Decimals multiplier for input token (10^decimals).
     * @param decimalsOut Decimals multiplier for output token (10^decimals).
     * @param fee Fee in basis points (out of 10000).
     * @return optimalSwap The optimal amount to swap.
     */
    function _binarySearchOptimalSwapStable(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 decimalsIn,
        uint256 decimalsOut,
        uint256 fee
    ) internal pure returns (uint256 optimalSwap) {
        // Search bounds: swap between 0 and amountIn/2
        // We shouldn't swap more than half since we need both tokens for deposit
        uint256 low = 0;
        uint256 high = amountIn / 2;

        // Binary search for ~20 iterations (sufficient precision)
        for (uint256 i = 0; i < 20; i++) {
            uint256 mid = (low + high) / 2;
            if (mid == low) break;

            // Calculate output for this swap amount
            uint256 swapOut = _getAmountOutStable(mid, reserveIn, reserveOut, decimalsIn, decimalsOut, fee);

            // After swap, new reserves
            uint256 newReserveIn = reserveIn + mid;
            uint256 newReserveOut = reserveOut - swapOut;

            // Remaining tokenIn to deposit
            uint256 remainingIn = amountIn - mid;

            // Check ratio: we want remainingIn/swapOut ≈ newReserveIn/newReserveOut
            // Cross multiply: remainingIn * newReserveOut vs swapOut * newReserveIn
            uint256 leftSide = remainingIn * newReserveOut;
            uint256 rightSide = swapOut * newReserveIn;

            if (leftSide > rightSide) {
                // Need to swap more to reduce remainingIn relative to swapOut
                low = mid;
            } else {
                // Need to swap less
                high = mid;
            }
        }

        return (low + high) / 2;
    }

    // end::_binarySearchOptimalSwapStable(uint256-uint256-uint256-uint256-uint256-uint256)[]

    // tag::_getAmountOutStable(uint256-uint256-uint256-uint256-uint256-uint256)[]
    /**
     * @notice Calculates the output amount for a stable pool swap.
     * Implements x³y + xy³ = k using Newton-Raphson via _getY after fee and k calc. Normalizes to 1e18 internally.
     * @dev Gas ~3k-5k typical. Called from swap quote paths and binary search.
     * @param amountIn Amount of input token.
     * @param reserveIn Reserve of input token.
     * @param reserveOut Reserve of output token.
     * @param decimalsIn Decimals multiplier for input token (10^decimals).
     * @param decimalsOut Decimals multiplier for output token (10^decimals).
     * @param fee Fee in basis points (out of 10000).
     * @return amountOut The calculated output amount.
     */
    function _getAmountOutStable(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 decimalsIn,
        uint256 decimalsOut,
        uint256 fee
    ) internal pure returns (uint256 amountOut) {
        // Apply fee to input
        amountIn = amountIn - (amountIn * fee) / AERO_FEE_DENOM;

        // Calculate current k
        uint256 xy = _k(reserveIn, reserveOut, decimalsIn, decimalsOut);

        // Normalize reserves to 1e18 for calculation
        uint256 _reserveIn = (reserveIn * 1e18) / decimalsIn;
        uint256 _reserveOut = (reserveOut * 1e18) / decimalsOut;

        // Normalize amountIn
        uint256 _amountIn = (amountIn * 1e18) / decimalsIn;

        // Calculate new y using Newton-Raphson
        uint256 y = _reserveOut - _getY(_amountIn + _reserveIn, xy, _reserveOut);

        // De-normalize the output
        return (y * decimalsOut) / 1e18;
    }

    // end::_getAmountOutStable(uint256-uint256-uint256-uint256-uint256-uint256)[]

    // tag::_k(uint256-uint256-uint256-uint256)[]
    /**
     * @notice Calculates the k invariant for stable pools.
     * k = x³y + xy³ where x,y normalized to 18 decimals.
     * @param x Reserve of token x.
     * @param y Reserve of token y.
     * @param decimalsX Decimals multiplier for token x.
     * @param decimalsY Decimals multiplier for token y.
     * @return k The invariant value.
     */
    function _k(uint256 x, uint256 y, uint256 decimalsX, uint256 decimalsY) internal pure returns (uint256) {
        uint256 _x = (x * 1e18) / decimalsX;
        uint256 _y = (y * 1e18) / decimalsY;
        uint256 _a = (_x * _y) / 1e18;
        uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
        return (_a * _b) / 1e18; // x³y + xy³ >= k
    }

    // end::_k(uint256-uint256-uint256-uint256)[]

    // tag::_f(uint256-uint256)[]
    /**
     * @notice Helper function for stable pool curve calculation.
     * @dev f(x0, y) = x0 * y * (x0² + y²) - this is the curve equation used in _getY.
     */
    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        uint256 _a = (x0 * y) / 1e18;
        uint256 _b = ((x0 * x0) / 1e18 + (y * y) / 1e18);
        return (_a * _b) / 1e18;
    }

    // end::_f(uint256-uint256)[]

    // tag::_d(uint256-uint256)[]
    /**
     * @notice Derivative of f with respect to y.
     * @dev d(f)/dy = 3 * x0 * y² + x0³ (used in Newton-Raphson inside _getY).
     */
    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return (3 * x0 * ((y * y) / 1e18)) / 1e18 + ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    // end::_d(uint256-uint256)[]

    // tag::_getY(uint256-uint256-uint256)[]
    /**
     * @notice Newton-Raphson iteration to solve for y given x and k.
     * Finds y such that f(x0, y) = xy (the k invariant).
     * @dev Max 255 iters. Typical 4-6. Reverts on no convergence. Quadratic convergence near solution.
     * @param x0 New x reserve after swap.
     * @param xy The k invariant.
     * @param y Initial y value (current reserve).
     * @return The new y value.
     */
    function _getY(uint256 x0, uint256 xy, uint256 y) internal pure returns (uint256) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 k = _f(x0, y);
            if (k < xy) {
                // Case 1: k < xy, need to increase y
                uint256 dy = ((xy - k) * 1e18) / _d(x0, y);
                if (dy == 0) {
                    if (k == xy) {
                        return y;
                    }
                    if (_k_from_f(x0, y + 1) > xy) {
                        return y + 1;
                    }
                    dy = 1;
                }
                y = y + dy;
            } else {
                // Case 2: k >= xy, need to decrease y
                uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
                if (dy == 0) {
                    if (k == xy || _f(x0, y - 1) < xy) {
                        return y;
                    }
                    dy = 1;
                }
                y = y - dy;
            }
        }
        revert("AerodromeServiceStable: y calculation failed");
    }

    // end::_getY(uint256-uint256-uint256)[]

    // tag::_k_from_f(uint256-uint256)[]
    /**
     * @notice Helper to calculate k using _f for comparison in Newton-Raphson.
     */
    function _k_from_f(uint256 x0, uint256 y) internal pure returns (uint256) {
        return _f(x0, y);
    }

    // end::_k_from_f(uint256-uint256)[]

    /* -------------------------------------------------------------------------- */
    /*                          Withdraw-Swap Functions                            */
    /* -------------------------------------------------------------------------- */

    // tag::_withdrawSwapStable(WithdrawSwapStableParams)[]
    /**
     * @notice Performs a withdraw-swap (zap out) from a stable pool.
     * Removes liquidity (stable=true) to self, swaps the opposingToken portion to tokenOut, transfers direct tokenOut portion + swap proceeds.
     * @dev Uses _swapStable internally for the swap leg.
     * @param params The withdraw-swap parameters.
     * @return amountOut The total amount of tokenOut received.
     * @custom:emits Transfer (LP burn effects + swap transfers).
     */
    function _withdrawSwapStable(WithdrawSwapStableParams memory params) internal returns (uint256 amountOut) {
        // Remove liquidity from stable pool
        (uint256 amountA, uint256 amountB) = params.aerodromeRouter
            .removeLiquidity(
                address(params.tokenOut),
                address(params.opposingToken),
                true, // Stable pool
                params.lpBurnAmt,
                0, // amountAMin
                0, // amountBMin
                address(this),
                params.deadline
            );

        // Swap opposingToken (amountB) to tokenOut
        SwapStableParams memory swapParams = SwapStableParams({
            router: params.aerodromeRouter,
            factory: params.factory,
            pool: params.pool,
            tokenIn: params.opposingToken,
            tokenOut: params.tokenOut,
            amountIn: amountB,
            recipient: params.recipient,
            deadline: params.deadline
        });
        uint256 swapAmountOut = _swapStable(swapParams);

        // Transfer the tokenOut portion from removeLiquidity to recipient
        params.tokenOut.transfer(params.recipient, amountA);

        return amountA + swapAmountOut;
    }
    // end::_withdrawSwapStable(WithdrawSwapStableParams)[]

    // end::AerodromeServiceStable[]
}
