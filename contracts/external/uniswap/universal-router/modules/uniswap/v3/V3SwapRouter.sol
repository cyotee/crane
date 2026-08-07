// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {V3Path} from './V3Path.sol';
import {BytesLib} from './BytesLib.sol';
import {SafeCast} from '@crane/contracts/external/uniswap/v3-core/contracts/libraries/SafeCast.sol';
import {IUniswapV3Pool} from '@crane/contracts/external/uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import {IUniswapV3SwapCallback} from '@crane/contracts/external/uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';
import {ActionConstants} from '@crane/contracts/protocols/dexes/uniswap/v4/libraries/ActionConstants.sol';
import {Constants} from '../../../libraries/Constants.sol';
import {CalldataDecoder} from '@crane/contracts/protocols/dexes/uniswap/v4/libraries/CalldataDecoder.sol';
import {Permit2Payments} from '../../Permit2Payments.sol';
import {UniswapImmutables} from '../UniswapImmutables.sol';
import {MaxInputAmount} from '../../../libraries/MaxInputAmount.sol';
import {ERC20} from '@crane/contracts/external/solmate/tokens/ERC20.sol';

/// @title Router for Uniswap v3 Trades
abstract contract V3SwapRouter is UniswapImmutables, Permit2Payments, IUniswapV3SwapCallback {
    using V3Path for bytes;
    using BytesLib for bytes;
    using CalldataDecoder for bytes;
    using SafeCast for uint256;

    error V3InvalidSwap();
    error V3TooLittleReceived();
    error V3TooMuchRequested();
    error V3InvalidAmountOut();
    error V3InvalidCaller();
    error V3TooLittleReceivedPerHop(uint256 hopIndex, uint256 minPrice, uint256 price);
    error V3TooMuchRequestedPerHop(uint256 hopIndex, uint256 minPrice, uint256 price);
    error V3HopPriceAndPathLengthMismatch();

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @dev Bundle callback decode locals to keep `uniswapV3SwapCallback` under the stack limit (via_ir=false).
    struct V3CallbackState {
        address payer;
        uint256[] minHopPriceX36;
        uint256 hopIndex;
        address tokenIn;
        address tokenOut;
        uint256 amountToPay;
        bool isExactInput;
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        if (amount0Delta <= 0 && amount1Delta <= 0) revert V3InvalidSwap(); // swaps entirely within 0-liquidity regions are not supported

        V3CallbackState memory s;
        (, s.payer, s.minHopPriceX36, s.hopIndex) = abi.decode(data, (bytes, address, uint256[], uint256));
        bytes calldata path = data.toBytes(0);

        // because exact output swaps are executed in reverse order, in this case tokenOut is actually tokenIn
        uint24 fee;
        (s.tokenIn, fee, s.tokenOut) = path.decodeFirstPool();

        if (computePoolAddress(s.tokenIn, s.tokenOut, fee) != msg.sender) revert V3InvalidCaller();

        (s.isExactInput, s.amountToPay) = amount0Delta > 0
            ? (s.tokenIn < s.tokenOut, uint256(amount0Delta))
            : (s.tokenOut < s.tokenIn, uint256(amount1Delta));

        if (s.isExactInput) {
            // Pay the pool (msg.sender)
            payOrPermit2Transfer(s.tokenIn, s.payer, msg.sender, s.amountToPay);
            return;
        }

        // exact output: either continue multi-hop or settle final pay
        _handleExactOutputCallback(amount0Delta, amount1Delta, path, s);
    }

    /// @dev Split exact-output callback path to free stack slots for the recursive `_swap` call.
    function _handleExactOutputCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata path,
        V3CallbackState memory s
    ) private {
        if (path.hasMultiplePools()) {
            _checkExactOutHopPrice(amount0Delta, amount1Delta, s.amountToPay, s.minHopPriceX36, s.hopIndex);
            // this is an intermediate step so the payer is actually this contract
            path = path.skipToken();
            uint256 nextHopIndex = s.hopIndex > 0 ? s.hopIndex - 1 : 0;
            _swap(-s.amountToPay.toInt256(), msg.sender, path, s.payer, false, s.minHopPriceX36, nextHopIndex);
            return;
        }

        if (s.amountToPay > MaxInputAmount.get()) revert V3TooMuchRequested();
        // Per-hop price check for the first trading hop (last executed in exact-output)
        _checkExactOutHopPrice(amount0Delta, amount1Delta, s.amountToPay, s.minHopPriceX36, s.hopIndex);
        // note that because exact output swaps are executed in reverse order, tokenOut is actually tokenIn
        payOrPermit2Transfer(s.tokenOut, s.payer, msg.sender, s.amountToPay);
    }

    function _checkExactOutHopPrice(
        int256 amount0Delta,
        int256 amount1Delta,
        uint256 amountToPay,
        uint256[] memory minHopPriceX36,
        uint256 hopIndex
    ) private pure {
        if (minHopPriceX36.length == 0) return;
        uint256 amountOut = uint256(-(amount0Delta > 0 ? amount1Delta : amount0Delta));
        uint256 price = amountOut * Constants.PRICE_PRECISION / amountToPay;
        uint256 minPrice = minHopPriceX36[hopIndex];
        if (price < minPrice) revert V3TooMuchRequestedPerHop(hopIndex, minPrice, price);
    }

    /// @notice Performs a Uniswap v3 exact input swap
    /// @param recipient The recipient of the output tokens
    /// @param amountIn The amount of input tokens for the trade
    /// @param amountOutMinimum The minimum desired amount of output tokens
    /// @param path The path of the trade as a bytes string
    /// @param payer The address that will be paying the input
    /// @param minHopPriceX36 Per-hop minimum price array in 1e36 precision (empty to disable)
    function v3SwapExactInput(
        address recipient,
        uint256 amountIn,
        uint256 amountOutMinimum,
        bytes calldata path,
        address payer,
        uint256[] calldata minHopPriceX36
    ) internal {
        // Validate hop price array length
        // V3 path: token(20) + [fee(3) + token(20)] * numHops => path.length = (minHopPriceX36.length * 23) + 20
        if (
            minHopPriceX36.length != 0
                && path.length != (minHopPriceX36.length * Constants.NEXT_V3_POOL_OFFSET) + Constants.ADDR_SIZE
        ) revert V3HopPriceAndPathLengthMismatch();

        // use amountIn == ActionConstants.CONTRACT_BALANCE as a flag to swap the entire balance of the contract
        if (amountIn == ActionConstants.CONTRACT_BALANCE) {
            address tokenIn = path.decodeFirstToken();
            amountIn = ERC20(tokenIn).balanceOf(address(this));
        }

        uint256 amountOut = _v3ExactInputLoop(recipient, amountIn, path, payer, minHopPriceX36);
        if (amountOut < amountOutMinimum) revert V3TooLittleReceived();
    }

    /// @dev Exact-input multi-hop loop extracted for stack headroom under via_ir=false.
    function _v3ExactInputLoop(
        address recipient,
        uint256 amountIn,
        bytes calldata path,
        address payer,
        uint256[] calldata minHopPriceX36
    ) private returns (uint256 amountOut) {
        ExactInLoop memory loop;
        loop.amountIn = amountIn;
        loop.previousAmountIn = amountIn;
        loop.payer = payer;
        loop.emptyHopPrice = new uint256[](0);

        while (true) {
            bool hasMultiplePools = path.hasMultiplePools();
            address hopRecipient = hasMultiplePools ? address(this) : recipient;

            (int256 amount0Delta, int256 amount1Delta, bool zeroForOne) = _swap(
                loop.amountIn.toInt256(),
                hopRecipient,
                path.getFirstPool(),
                loop.payer,
                true,
                loop.emptyHopPrice,
                0
            );

            loop.amountIn = uint256(-(zeroForOne ? amount1Delta : amount0Delta));
            _checkExactInHopPrice(loop.amountIn, loop.previousAmountIn, minHopPriceX36, loop.hopIndex);

            if (hasMultiplePools) {
                loop.payer = address(this);
                path = path.skipToken();
                loop.previousAmountIn = loop.amountIn;
                unchecked {
                    ++loop.hopIndex;
                }
            } else {
                amountOut = loop.amountIn;
                break;
            }
        }
    }

    struct ExactInLoop {
        uint256 amountIn;
        uint256 previousAmountIn;
        uint256 hopIndex;
        address payer;
        uint256[] emptyHopPrice;
    }

    function _checkExactInHopPrice(
        uint256 amountIn,
        uint256 previousAmountIn,
        uint256[] calldata minHopPriceX36,
        uint256 hopIndex
    ) private pure {
        if (minHopPriceX36.length == 0) return;
        uint256 price = amountIn * Constants.PRICE_PRECISION / previousAmountIn;
        uint256 minPrice = minHopPriceX36[hopIndex];
        if (price < minPrice) revert V3TooLittleReceivedPerHop(hopIndex, minPrice, price);
    }

    /// @notice Performs a Uniswap v3 exact output swap
    /// @param recipient The recipient of the output tokens
    /// @param amountOut The amount of output tokens to receive for the trade
    /// @param amountInMaximum The maximum desired amount of input tokens
    /// @param path The path of the trade as a bytes string
    /// @param payer The address that will be paying the input
    /// @param minHopPriceX36 Per-hop minimum price array in 1e36 precision (empty to disable)
    function v3SwapExactOutput(
        address recipient,
        uint256 amountOut,
        uint256 amountInMaximum,
        bytes calldata path,
        address payer,
        uint256[] calldata minHopPriceX36
    ) internal {
        // Validate hop price array length
        // V3 path: token(20) + [fee(3) + token(20)] * numHops => path.length = (minHopPriceX36.length * 23) + 20
        if (
            minHopPriceX36.length != 0
                && path.length != (minHopPriceX36.length * Constants.NEXT_V3_POOL_OFFSET) + Constants.ADDR_SIZE
        ) revert V3HopPriceAndPathLengthMismatch();

        // Convert calldata to memory for abi.encode in _swap
        uint256[] memory minHopPriceX36Memory = minHopPriceX36;

        MaxInputAmount.set(amountInMaximum);

        // For exact-output, the first _swap handles the LAST trading hop.
        // Trading direction: hop 0 (A->B), hop 1 (B->C), ...
        // Execution: last hop first, then callbacks handle earlier hops.
        // So start hopIndex at minHopPriceX36Memory.length - 1 and decrement in callbacks.
        uint256 startHopIndex = minHopPriceX36Memory.length > 0 ? minHopPriceX36Memory.length - 1 : 0;

        (int256 amount0Delta, int256 amount1Delta, bool zeroForOne) =
            _swap(-amountOut.toInt256(), recipient, path, payer, false, minHopPriceX36Memory, startHopIndex);

        uint256 amountOutReceived = zeroForOne ? uint256(-amount1Delta) : uint256(-amount0Delta);

        if (amountOutReceived != amountOut) revert V3InvalidAmountOut();

        MaxInputAmount.set(0);
    }

    /// @dev Packed pool.swap args so `_swap` stays under the stack limit without via_ir.
    struct V3PoolSwapArgs {
        address pool;
        address recipient;
        bool zeroForOne;
        int256 amountSpecified;
        uint160 sqrtPriceLimitX96;
        bytes data;
    }

    /// @dev Performs a single swap for both exactIn and exactOut
    /// For exactIn, `amount` is `amountIn`. For exactOut, `amount` is `-amountOut`
    function _swap(
        int256 amount,
        address recipient,
        bytes calldata path,
        address payer,
        bool isExactIn,
        uint256[] memory minHopPriceX36,
        uint256 hopIndex
    ) private returns (int256 amount0Delta, int256 amount1Delta, bool zeroForOne) {
        V3PoolSwapArgs memory a = _buildV3PoolSwapArgs(amount, recipient, path, payer, isExactIn, minHopPriceX36, hopIndex);
        zeroForOne = a.zeroForOne;
        (amount0Delta, amount1Delta) = _callV3PoolSwap(a);
    }

    function _buildV3PoolSwapArgs(
        int256 amount,
        address recipient,
        bytes calldata path,
        address payer,
        bool isExactIn,
        uint256[] memory minHopPriceX36,
        uint256 hopIndex
    ) private view returns (V3PoolSwapArgs memory a) {
        (address tokenIn, uint24 fee, address tokenOut) = path.decodeFirstPool();
        a.zeroForOne = isExactIn ? tokenIn < tokenOut : tokenOut < tokenIn;
        a.pool = computePoolAddress(tokenIn, tokenOut, fee);
        a.recipient = recipient;
        a.amountSpecified = amount;
        a.sqrtPriceLimitX96 = a.zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1;
        a.data = abi.encode(path, payer, minHopPriceX36, hopIndex);
    }

    function _callV3PoolSwap(V3PoolSwapArgs memory a)
        private
        returns (int256 amount0Delta, int256 amount1Delta)
    {
        return IUniswapV3Pool(a.pool).swap(
            a.recipient, a.zeroForOne, a.amountSpecified, a.sqrtPriceLimitX96, a.data
        );
    }

    function computePoolAddress(address tokenA, address tokenB, uint24 fee) private view returns (address pool) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            UNISWAP_V3_FACTORY,
                            keccak256(abi.encode(tokenA, tokenB, fee)),
                            UNISWAP_V3_POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}
