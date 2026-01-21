// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IPool} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPool.sol";
import {IRouter} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol";
import {IPoolFactory} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPoolFactory.sol";

/**
 * @title AerodromServiceStable
 * @notice Library for interacting with Aerodrome stable pools (x³y + xy³ = k curve)
 * @dev For volatile pools (xy = k curve), use AerodromServiceVolatile instead.
 *
 * This library provides functions for:
 * - Swapping tokens in stable pools
 * - Swap-deposit (zap in) to stable pools
 * - Withdraw-swap (zap out) from stable pools
 * - Quoting optimal swap amounts for balanced deposits
 *
 * All functions explicitly use `stable: true` for pool/router interactions.
 *
 * @custom:math Stable Pool Curve
 * The stable pool uses the curve: x³y + xy³ = k
 * This provides lower slippage for similarly-priced assets (stablecoins, wrapped tokens).
 * The math is more complex than volatile pools and uses Newton-Raphson iteration
 * for output calculations.
 */
library AerodromServiceStable {

    /* -------------------------------------------------------------------------- */
    /*                                  Constants                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Aerodrome fee denominator is 10000 (not 100000 like Uniswap V2)
    uint256 constant AERO_FEE_DENOM = 10000;

    /* -------------------------------------------------------------------------- */
    /*                                   Structs                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Parameters for swapping tokens in a stable pool
     * @param router The Aerodrome router contract
     * @param factory The Aerodrome pool factory contract
     * @param pool The stable pool to swap in
     * @param tokenIn The token being sold
     * @param tokenOut The token being purchased
     * @param amountIn The amount of tokenIn to swap
     * @param recipient The address to receive tokenOut
     * @param deadline The transaction deadline timestamp
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

    /**
     * @notice Parameters for swap-deposit (zap in) to a stable pool
     * @param router The Aerodrome router contract
     * @param factory The Aerodrome pool factory contract
     * @param pool The stable pool to deposit into
     * @param token0 The token0 of the pool (for reserve sorting)
     * @param tokenIn The single token being deposited
     * @param opposingToken The other token in the pool
     * @param amountIn The amount of tokenIn to deposit
     * @param recipient The address to receive LP tokens
     * @param deadline The transaction deadline timestamp
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

    /**
     * @notice Parameters for withdraw-swap (zap out) from a stable pool
     * @param aerodromeRouter The Aerodrome router contract
     * @param pool The stable pool to withdraw from
     * @param factory The Aerodrome pool factory contract
     * @param tokenOut The desired output token
     * @param opposingToken The other token in the pool (will be swapped)
     * @param lpBurnAmt The amount of LP tokens to burn
     * @param recipient The address to receive tokenOut
     * @param deadline The transaction deadline timestamp
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

    /* -------------------------------------------------------------------------- */
    /*                              Swap Functions                                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Swaps tokens in a stable pool
     * @dev Uses `stable: true` for the swap route
     * @param params The swap parameters
     * @return amountOut The amount of tokenOut received
     */
    function _swapStable(
        SwapStableParams memory params
    ) internal returns (uint256 amountOut) {
        IRouter.Route memory route = IRouter.Route({
            from: address(params.tokenIn),
            to: address(params.tokenOut),
            stable: true, // Stable pool
            factory: address(params.factory)
        });
        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = route;

        params.tokenIn.approve(address(params.router), params.amountIn);

        uint256[] memory amountsOut = params.router.swapExactTokensForTokens(
            params.amountIn,
            0, // amountOutMin - caller should implement slippage protection
            routes,
            params.recipient,
            params.deadline
        );

        return amountsOut[amountsOut.length - 1];
    }

    /* -------------------------------------------------------------------------- */
    /*                           Swap-Deposit Functions                            */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Performs a swap-deposit (zap in) to a stable pool
     * @dev Swaps a portion of tokenIn for opposingToken, then deposits both
     *
     * ## Gas and Complexity Analysis
     *
     * This function invokes `_binarySearchOptimalSwapStable`, which performs:
     * - Up to 20 binary search iterations
     * - Each iteration calls `_getAmountOutStable`, which uses Newton-Raphson (up to 255 iterations)
     *
     * **Worst-case**: 20 × 255 = 5,100 inner iterations
     * **Typical case**: 20 × 4-6 ≈ 80-120 inner iterations (Newton-Raphson converges quickly)
     *
     * Gas estimates (mainnet, ~25 gwei):
     * - Quoting only (`_quoteSwapDepositSaleAmtStable`): ~50,000-80,000 gas
     * - Full swap-deposit: ~250,000-400,000 gas (includes swap + addLiquidity)
     *
     * **Design Note**: This mirrors Aerodrome's pool math. The Newton-Raphson iteration
     * converges rapidly for typical stable pool reserves because the curve is smooth
     * and the initial guess (current reserve) is close to the solution.
     *
     * For latency-sensitive on-chain usage, consider:
     * 1. Off-chain quoting with on-chain execution using slippage bounds
     * 2. Caching optimal ratios for pools with predictable reserve compositions
     *
     * @param params The swap-deposit parameters
     * @return lpOut The amount of LP tokens minted
     */
    function _swapDepositStable(
        SwapDepositStableParams memory params
    ) internal returns (uint256 lpOut) {
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

        (
            , // amountA
            , // amountB
            lpOut
        ) = params.router.addLiquidity(
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

    /**
     * @notice Calculates the optimal swap amount for a swap-deposit to a stable pool
     * @dev For stable pools, we use binary search since the curve math is non-linear.
     *      The stable pool curve x³y + xy³ = k doesn't have a closed-form solution
     *      for optimal swap amount like volatile pools do.
     * @param params The swap-deposit parameters
     * @return saleAmt The optimal amount to swap
     */
    function _quoteSwapDepositSaleAmtStable(
        SwapDepositStableParams memory params
    ) internal view returns (uint256 saleAmt) {
        // Get pool metadata
        (
            uint256 decimals0,
            uint256 decimals1,
            uint256 reserve0,
            uint256 reserve1,
            ,  // stable (we know it's true)
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
        saleAmt = _binarySearchOptimalSwapStable(
            params.amountIn,
            reserveIn,
            reserveOut,
            decimalsIn,
            decimalsOut,
            fee
        );
    }

    /**
     * @notice Binary search to find optimal swap amount for stable pool deposit
     * @dev Iteratively searches for the swap amount that results in the most balanced deposit
     *
     * ## Convergence Characteristics
     *
     * The binary search runs for a **fixed 20 iterations**, halving the search space each time.
     * This provides precision of `amountIn / 2^20` ≈ `amountIn / 1,048,576`, sufficient for
     * any practical token amount.
     *
     * **Early exit**: The search exits early if `mid == low`, indicating the bounds have
     * converged to adjacent values.
     *
     * **Per-iteration cost**: Each iteration calls `_getAmountOutStable`, which internally
     * uses Newton-Raphson to solve the stable curve equation. Newton-Raphson typically
     * converges in 4-6 iterations for well-behaved inputs (balanced reserves, reasonable
     * amounts).
     *
     * **Why binary search?**: Unlike volatile pools (xy = k), stable pools (x³y + xy³ = k)
     * don't have a closed-form solution for optimal swap amount. The cubic terms make
     * the ratio relationship non-linear, requiring numerical methods.
     *
     * @param amountIn Total amount being deposited
     * @param reserveIn Reserve of the input token
     * @param reserveOut Reserve of the output token
     * @param decimalsIn Decimals multiplier for input token (10^decimals)
     * @param decimalsOut Decimals multiplier for output token (10^decimals)
     * @param fee Fee in basis points (out of 10000)
     * @return optimalSwap The optimal amount to swap
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
            uint256 swapOut = _getAmountOutStable(
                mid,
                reserveIn,
                reserveOut,
                decimalsIn,
                decimalsOut,
                fee
            );

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

    /**
     * @notice Calculates the output amount for a stable pool swap
     * @dev Implements the stable pool curve math: x³y + xy³ = k
     *      Uses Newton-Raphson iteration to find the output amount
     *
     * **Gas**: ~3,000-5,000 gas typical (dominated by `_getY` Newton-Raphson iteration)
     *
     * @param amountIn Amount of input token
     * @param reserveIn Reserve of input token
     * @param reserveOut Reserve of output token
     * @param decimalsIn Decimals multiplier for input token (10^decimals)
     * @param decimalsOut Decimals multiplier for output token (10^decimals)
     * @param fee Fee in basis points (out of 10000)
     * @return amountOut The calculated output amount
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

    /**
     * @notice Calculates the k invariant for stable pools
     * @dev k = x³y + xy³ where x and y are normalized reserves
     * @param x Reserve of token x
     * @param y Reserve of token y
     * @param decimalsX Decimals multiplier for token x
     * @param decimalsY Decimals multiplier for token y
     * @return k The invariant value
     */
    function _k(
        uint256 x,
        uint256 y,
        uint256 decimalsX,
        uint256 decimalsY
    ) internal pure returns (uint256) {
        uint256 _x = (x * 1e18) / decimalsX;
        uint256 _y = (y * 1e18) / decimalsY;
        uint256 _a = (_x * _y) / 1e18;
        uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
        return (_a * _b) / 1e18; // x³y + xy³ >= k
    }

    /**
     * @notice Helper function for stable pool curve calculation
     * @dev f(x0, y) = x0 * y * (x0² + y²) - this is the curve equation
     */
    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        uint256 _a = (x0 * y) / 1e18;
        uint256 _b = ((x0 * x0) / 1e18 + (y * y) / 1e18);
        return (_a * _b) / 1e18;
    }

    /**
     * @notice Derivative of f with respect to y
     * @dev d(f)/dy = 3 * x0 * y² + x0³ (used in Newton-Raphson)
     */
    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return (3 * x0 * ((y * y) / 1e18)) / 1e18 + ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    /**
     * @notice Newton-Raphson iteration to solve for y given x and k
     * @dev Finds y such that f(x0, y) = xy (the k invariant)
     *
     * ## Convergence Characteristics
     *
     * **Max iterations**: 255 (worst case, protects against infinite loops)
     * **Typical iterations**: 4-6 for balanced stable pools
     *
     * Newton-Raphson converges quadratically near the solution, meaning the number
     * of correct digits roughly doubles each iteration. The stable curve is smooth
     * and well-behaved, so convergence is reliable.
     *
     * **Early exit conditions**:
     * 1. `dy == 0` with `k == xy`: Exact solution found
     * 2. `dy == 0` with `f(x0, y+1) > xy` or `f(x0, y-1) < xy`: Closest integer found
     * 3. Any `dy == 0` where further adjustment overshoots: Terminates with step of 1
     *
     * **Gas note**: Each iteration costs ~200-300 gas (mostly the `_f` and `_d` calls).
     * Typical total: 800-1,800 gas per `_getY` call.
     *
     * **Revert condition**: If 255 iterations complete without convergence, the function
     * reverts. This should only happen with malformed inputs (e.g., k=0, extreme imbalance).
     *
     * @param x0 New x reserve after swap
     * @param xy The k invariant
     * @param y Initial y value (current reserve)
     * @return The new y value
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
        revert("AerodromServiceStable: y calculation failed");
    }

    /**
     * @notice Helper to calculate k using _f for comparison in Newton-Raphson
     */
    function _k_from_f(uint256 x0, uint256 y) internal pure returns (uint256) {
        return _f(x0, y);
    }

    /* -------------------------------------------------------------------------- */
    /*                          Withdraw-Swap Functions                            */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Performs a withdraw-swap (zap out) from a stable pool
     * @dev Removes liquidity and swaps opposingToken to tokenOut
     * @param params The withdraw-swap parameters
     * @return amountOut The total amount of tokenOut received
     */
    function _withdrawSwapStable(
        WithdrawSwapStableParams memory params
    ) internal returns (uint256 amountOut) {
        // Remove liquidity from stable pool
        (uint256 amountA, uint256 amountB) = params.aerodromeRouter.removeLiquidity(
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
}
