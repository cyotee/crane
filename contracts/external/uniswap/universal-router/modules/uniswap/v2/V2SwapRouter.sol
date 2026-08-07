// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IUniswapV2Pair} from '@crane/contracts/external/uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import {UniswapV2Library} from './UniswapV2Library.sol';
import {UniswapImmutables} from '../UniswapImmutables.sol';
import {Permit2Payments} from '../../Permit2Payments.sol';
import {Constants} from '../../../libraries/Constants.sol';
import {ERC20} from '@crane/contracts/external/solmate/tokens/ERC20.sol';

/// @title Router for Uniswap v2 Trades
abstract contract V2SwapRouter is UniswapImmutables, Permit2Payments {
    error V2TooLittleReceived();
    error V2TooMuchRequested();
    error V2InvalidPath();
    error V2TooLittleReceivedPerHop(uint256 hopIndex, uint256 minPrice, uint256 price);
    error V2InvalidHopPriceLength();

    /// @dev Hop loop state packed so `_v2Swap` compiles without via_ir.
    struct V2HopState {
        address pair;
        address token0;
        address input;
        address output;
        address nextPair;
        uint256 amountInput;
        uint256 amountOutput;
        uint256 amount0Out;
        uint256 amount1Out;
        uint256 finalPairIndex;
        uint256 penultimatePairIndex;
        bool minHopPriceEnabled;
    }

    function _v2Swap(address[] calldata path, address recipient, address pair, uint256[] calldata minHopPriceX36)
        private
    {
        unchecked {
            V2HopState memory s;
            s.pair = pair;
            (s.token0,) = UniswapV2Library.sortTokens(path[0], path[1]);
            s.finalPairIndex = path.length - 1;
            s.penultimatePairIndex = s.finalPairIndex - 1;
            s.minHopPriceEnabled = minHopPriceX36.length != 0;

            for (uint256 i; i < s.finalPairIndex; i++) {
                _v2SwapHop(path, recipient, minHopPriceX36, i, s);
            }
        }
    }

    function _v2SwapHop(
        address[] calldata path,
        address recipient,
        uint256[] calldata minHopPriceX36,
        uint256 i,
        V2HopState memory s
    ) private {
        unchecked {
            (s.input, s.output) = (path[i], path[i + 1]);
            {
                (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(s.pair).getReserves();
                (uint256 reserveInput, uint256 reserveOutput) =
                    s.input == s.token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                s.amountInput = ERC20(s.input).balanceOf(s.pair) - reserveInput;
                s.amountOutput = UniswapV2Library.getAmountOut(s.amountInput, reserveInput, reserveOutput);
            }
            (s.amount0Out, s.amount1Out) =
                s.input == s.token0 ? (uint256(0), s.amountOutput) : (s.amountOutput, uint256(0));

            if (i < s.penultimatePairIndex) {
                (s.nextPair, s.token0) = UniswapV2Library.pairAndToken0For(
                    UNISWAP_V2_FACTORY, UNISWAP_V2_PAIR_INIT_CODE_HASH, s.output, path[i + 2]
                );
            } else {
                (s.nextPair, s.token0) = (recipient, address(0));
            }

            // if minHopPrice is being used, we need to check output balance change
            if (s.minHopPriceEnabled && minHopPriceX36[i] != 0) {
                uint256 recipientBalance = ERC20(s.output).balanceOf(s.nextPair);
                IUniswapV2Pair(s.pair).swap(s.amount0Out, s.amount1Out, s.nextPair, new bytes(0));
                s.amountOutput = ERC20(s.output).balanceOf(s.nextPair) - recipientBalance;
                uint256 price = s.amountOutput * Constants.PRICE_PRECISION / s.amountInput;
                uint256 minPrice = minHopPriceX36[i];
                if (price < minPrice) revert V2TooLittleReceivedPerHop(i, minPrice, price);
            } else {
                IUniswapV2Pair(s.pair).swap(s.amount0Out, s.amount1Out, s.nextPair, new bytes(0));
            }
            s.pair = s.nextPair;
        }
    }

    /// @notice Performs a Uniswap v2 exact input swap
    /// @param recipient The recipient of the output tokens
    /// @param amountIn The amount of input tokens for the trade
    /// @param amountOutMinimum The minimum desired amount of output tokens
    /// @param path The path of the trade as an array of token addresses
    /// @param payer The address that will be paying the input
    /// @param minHopPriceX36 Per-hop minimum price array in 1e36 precision (empty to disable)
    function v2SwapExactInput(
        address recipient,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address[] calldata path,
        address payer,
        uint256[] calldata minHopPriceX36
    ) internal {
        if (path.length < 2) revert V2InvalidPath();
        if (minHopPriceX36.length != 0 && minHopPriceX36.length != path.length - 1) {
            revert V2InvalidHopPriceLength();
        }

        address firstPair =
            UniswapV2Library.pairFor(UNISWAP_V2_FACTORY, UNISWAP_V2_PAIR_INIT_CODE_HASH, path[0], path[1]);
        if (
            amountIn != Constants.ALREADY_PAID // amountIn of 0 to signal that the pair already has the tokens
        ) {
            payOrPermit2Transfer(path[0], payer, firstPair, amountIn);
        }

        ERC20 tokenOut = ERC20(path[path.length - 1]);
        uint256 balanceBefore = tokenOut.balanceOf(recipient);

        _v2Swap(path, recipient, firstPair, minHopPriceX36);

        uint256 amountOut = tokenOut.balanceOf(recipient) - balanceBefore;
        if (amountOut < amountOutMinimum) revert V2TooLittleReceived();
    }

    /// @notice Performs a Uniswap v2 exact output swap
    /// @param recipient The recipient of the output tokens
    /// @param amountOut The amount of output tokens to receive for the trade
    /// @param amountInMaximum The maximum desired amount of input tokens
    /// @param path The path of the trade as an array of token addresses
    /// @param payer The address that will be paying the input
    /// @param minHopPriceX36 Per-hop minimum price array in 1e36 precision (empty to disable)
    function v2SwapExactOutput(
        address recipient,
        uint256 amountOut,
        uint256 amountInMaximum,
        address[] calldata path,
        address payer,
        uint256[] calldata minHopPriceX36
    ) internal {
        if (path.length < 2) revert V2InvalidPath();
        if (minHopPriceX36.length != 0 && minHopPriceX36.length != path.length - 1) {
            revert V2InvalidHopPriceLength();
        }

        (uint256 amountIn, address firstPair) =
            UniswapV2Library.getAmountInMultihop(UNISWAP_V2_FACTORY, UNISWAP_V2_PAIR_INIT_CODE_HASH, amountOut, path);
        if (amountIn > amountInMaximum) revert V2TooMuchRequested();

        payOrPermit2Transfer(path[0], payer, firstPair, amountIn);
        _v2Swap(path, recipient, firstPair, minHopPriceX36);
    }
}
