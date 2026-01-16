// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IPool} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPool.sol";
import {IRouter} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IRouter.sol";
import {IPoolFactory} from "@crane/contracts/interfaces/protocols/dexes/aerodrome/IPoolFactory.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

/**
 * @title AerodromService
 * @notice Library for interacting with Aerodrome pools
 *
 * @custom:deprecated This library is deprecated. Use the specialized libraries instead:
 *   - AerodromServiceVolatile.sol - For volatile pools (xy = k curve)
 *   - AerodromServiceStable.sol - For stable pools (x³y + xy³ = k curve)
 *
 * This library only supports volatile pools (stable: false). The new libraries provide:
 *   - Explicit pool type in function names (no ambiguity)
 *   - Separate struct types for each pool type
 *   - Clearer API for developers who need only one pool type
 *
 * Migration guide:
 *   - AerodromService.SwapParams -> AerodromServiceVolatile.SwapVolatileParams
 *   - AerodromService._swap() -> AerodromServiceVolatile._swapVolatile()
 *   - AerodromService._swapDepositVolatile() -> AerodromServiceVolatile._swapDepositVolatile()
 *   - AerodromService._withdrawSwapVolatile() -> AerodromServiceVolatile._withdrawSwapVolatile()
 *   - AerodromService._quoteSwapDepositSaleAmt() -> AerodromServiceVolatile._quoteSwapDepositSaleAmtVolatile()
 */
library AerodromService {

    struct SwapParams {
        IRouter router;
        IPoolFactory factory;
        IPool pool;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amountIn;
        address recipient;
        uint256 deadline;
    }

    struct SwapDepositVolatileParams {
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

    function _swap(
        SwapParams memory params
    ) internal returns (uint256 amountOut) {
        IRouter.Route memory route = IRouter.Route({
            // address from;
            from: address(params.tokenIn),
            // address to;
            to: address(params.tokenOut),
            // bool stable;
            stable: false,
            // address factory;
            factory: address(params.factory)
        });
        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = route;
        params.tokenIn.approve(address(params.router), params.amountIn);
        uint256[] memory amountsOut = params.router.swapExactTokensForTokens(
            // uint256 amountIn,
            params.amountIn,
            // uint256 amountOutMin,
            0,
            // Route[] calldata routes,
            routes,
            // address to,
            params.recipient,
            // uint256 deadline
            params.deadline
        );
        return amountsOut[amountsOut.length - 1];
    }

    function _swapDepositVolatile(
        SwapDepositVolatileParams memory params
    ) internal returns (uint256 lpOut) {
        SwapParams memory swapParams = SwapParams({
            router: params.router,
            factory: params.factory,
            pool: params.pool,
            tokenIn: params.tokenIn,
            tokenOut: params.opposingToken,
            amountIn: _quoteSwapDepositSaleAmt(params),
            recipient: address(this),
            deadline: params.deadline
        });
        uint256 swapAmountOut = _swap(swapParams);
        uint256 depositAmountIn = params.amountIn - swapParams.amountIn;
        params.tokenIn.approve(address(params.router), depositAmountIn);
        params.opposingToken.approve(address(params.router), swapAmountOut);
        (
            // uint256 amountA,
            , 
            // uint256 amountB,
            ,
            lpOut
        ) = params.router.addLiquidity(
            // address tokenA,
            address(params.tokenIn),
            // address tokenB,
            address(params.opposingToken),
            // bool stable,
            false,
            // uint256 amountADesired,
            depositAmountIn,
            // uint256 amountBDesired,
            swapAmountOut,
            // uint256 amountAMin,
            0,
            // uint256 amountBMin,
            0,
            // address to,
            params.recipient,
            // uint256 deadline
            params.deadline
        );
    }

    // Aerodrome fee denominator is 10000 (not 100000 like Uniswap V2)
    uint256 constant AERO_FEE_DENOM = 10000;

    function _quoteSwapDepositSaleAmt(
        SwapDepositVolatileParams memory params
    ) internal view returns (uint256 saleAmt) {
        uint256 saleReserve = address(params.tokenIn) == address(params.token0)
            ? params.pool.reserve0()
            : params.pool.reserve1();
        saleAmt = ConstProdUtils._swapDepositSaleAmt(
            params.amountIn,
            saleReserve,
            params.factory.getFee(address(params.pool), false),
            AERO_FEE_DENOM
        );
    }

    struct WithdrawSwapVolatileParams {
        IRouter aerodromeRouter;
        IPool pool;
        IPoolFactory factory;
        IERC20 tokenOut;
        IERC20 opposingToken;
        uint256 lpBurnAmt;
        address recipient;
        uint256 deadline;
    }

    function _withdrawSwapVolatile(
        WithdrawSwapVolatileParams memory params
    ) internal returns (uint256 amountOut) {
        (uint256 amountA, uint256 amountB) = params.aerodromeRouter.removeLiquidity(
            // address tokenA,
            address(params.tokenOut),
            // address tokenB,
            address(params.opposingToken),
            // bool stable,
            false,
            // uint256 liquidity,
            params.lpBurnAmt,
            // uint256 amountAMin,
            0,
            // uint256 amountBMin,
            0,
            // address to,
            address(this),
            // uint256 deadline
            params.deadline
        );
        AerodromService.SwapParams memory swapParams = AerodromService.SwapParams({
            router: params.aerodromeRouter,
            factory: params.factory,
            pool: params.pool,
            tokenIn: params.opposingToken,
            tokenOut: params.tokenOut,
            amountIn: amountB,
            recipient: params.recipient,
            deadline: params.deadline
        });
        uint256 swapAmountOut = AerodromService._swap(swapParams);
        // Transfer the tokenOut portion from removeLiquidity to recipient
        params.tokenOut.transfer(params.recipient, amountA);
        return amountA + swapAmountOut;
    }

}