// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.35;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================= FraxswapRouterLibrary ======================
// ====================================================================
// Fraxswap Router Library Functions
// Inspired by https://www.paradigm.xyz/2021/07/twamm
// https://github.com/para-dave/twamm

// Frax Finance: https://github.com/FraxFinance

// Primary Author(s)
// Rich Gee: https://github.com/zer0blockchain
// Dennis: https://github.com/denett

// Logic / Algorithm Ideas
// FrankieIsLost: https://github.com/FrankieIsLost

// Reviewer(s) / Contributor(s)
// Travis Moore: https://github.com/FortisFortuna
// Sam Kazemian: https://github.com/samkazemian
// Drake Evans: https://github.com/DrakeEvans
// Jack Corddry: https://github.com/corddry
// Justin Moore: https://github.com/0xJM

import "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol";
import "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/interfaces/IFraxswapPair.sol";

library FraxswapRouterLibrary {
    // Must match CREATE2 deployments from FraxswapFactory; derived from current compiler output.
    bytes32 internal constant INIT_CODE_PAIR_HASH = keccak256(type(FraxswapPair).creationCode);

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "FraxswapRouterLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "FraxswapRouterLibrary: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff", factory, keccak256(abi.encodePacked(token0, token1)), INIT_CODE_PAIR_HASH
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);

        (uint256 reserve0, uint256 reserve1,) = IFraxswapPair(pairFor(factory, tokenA, tokenB)).getReserves();

        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    function getReservesWithTwamm(address factory, address tokenA, address tokenB)
        internal
        returns (uint256 reserveA, uint256 reserveB, uint256 twammReserveA, uint256 twammReserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);

        IFraxswapPair pair = IFraxswapPair(pairFor(factory, tokenA, tokenB));

        pair.executeVirtualOrders(block.timestamp);

        (uint256 reserve0, uint256 reserve1,, uint256 twammReserve0, uint256 twammReserve1,) = pair.getTwammReserves();

        (reserveA, reserveB, twammReserveA, twammReserveB) = tokenA == token0
            ? (reserve0, reserve1, twammReserve0, twammReserve1)
            : (reserve1, reserve0, twammReserve1, twammReserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "FraxswapRouterLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "FraxswapRouterLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = amountA * reserveB / reserveA;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint256 amountIn, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "FraxswapRouterLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            IFraxswapPair pair = IFraxswapPair(FraxswapRouterLibrary.pairFor(factory, path[i], path[i + 1]));
            require(pair.twammUpToDate(), "twamm out of date");
            amounts[i + 1] = getAmountOutU112Fixed(address(pair), amounts[i], path[i]);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint256 amountOut, address[] memory path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "FraxswapRouterLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            IFraxswapPair pair = IFraxswapPair(FraxswapRouterLibrary.pairFor(factory, path[i - 1], path[i]));
            require(pair.twammUpToDate(), "twamm out of date");
            amounts[i - 1] = getAmountInU112Fixed(address(pair), amounts[i], path[i - 1]);
        }
    }

    // performs chained getAmountOut calculations on any number of pairs with Twamm
    function getAmountsOutWithTwamm(address factory, uint256 amountIn, address[] memory path)
        internal
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "FraxswapRouterLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            IFraxswapPair pair = IFraxswapPair(FraxswapRouterLibrary.pairFor(factory, path[i], path[i + 1]));
            pair.executeVirtualOrders(block.timestamp);
            amounts[i + 1] = getAmountOutU112Fixed(address(pair), amounts[i], path[i]);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs with Twamm
    function getAmountsInWithTwamm(address factory, uint256 amountOut, address[] memory path)
        internal
        returns (uint256[] memory amounts)
    {
        require(path.length >= 2, "FraxswapRouterLibrary: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            IFraxswapPair pair = IFraxswapPair(FraxswapRouterLibrary.pairFor(factory, path[i - 1], path[i]));
            pair.executeVirtualOrders(block.timestamp);
            amounts[i - 1] = getAmountInU112Fixed(address(pair), amounts[i], path[i - 1]);
        }
    }

    // Fixes overflow issues with some tokens
    // =====================================================

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountInU112Fixed(address _pairAddress, uint256 _amountOut, address _tokenOut)
        internal
        view
        returns (uint256)
    {
        IFraxswapPair pair = IFraxswapPair(_pairAddress);
        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();
        (uint112 _reserveIn, uint112 _reserveOut) =
            _tokenOut == pair.token0() ? (_reserve1, _reserve0) : (_reserve0, _reserve1);
        require(_amountOut > 0 && _reserveIn > 0 && _reserveOut > 0); // INSUFFICIENT_OUTPUT_AMOUNT, INSUFFICIENT_LIQUIDITY
        uint256 numerator = uint256(_reserveIn) * _amountOut * 10000;
        uint256 denominator = (uint256(_reserveOut) - _amountOut) * pair.fee();
        return (numerator / denominator) + 1;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOutU112Fixed(address _pairAddress, uint256 _amountIn, address _tokenIn)
        internal
        view
        returns (uint256)
    {
        IFraxswapPair pair = IFraxswapPair(_pairAddress);
        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();
        (uint112 _reserveIn, uint112 _reserveOut) =
            _tokenIn == pair.token0() ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
        require(_amountIn > 0 && _reserveIn > 0 && _reserveOut > 0); // INSUFFICIENT_INPUT_AMOUNT, INSUFFICIENT_LIQUIDITY
        uint256 amountInWithFee = uint256(_amountIn) * pair.fee();
        uint256 numerator = amountInWithFee * uint256(_reserveOut);
        uint256 denominator = (uint256(_reserveIn) * 10000) + amountInWithFee;
        return numerator / denominator;
    }
}
