// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Shared Fraxswap pair + token setup for BAMM-related spec tests.

import {Test} from "forge-std/Test.sol";
import {FraxswapFactory} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapFactory.sol";
import {FraxswapPair} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol";
import {DummyToken} from "@crane/contracts/protocols/tokens/stable/frax/Fraxferry/DummyToken.sol";

abstract contract TestBase_FraxBAMM is Test {
    address internal fraxOwner;
    address internal fraxUser1;

    DummyToken internal token0;
    DummyToken internal token1;
    FraxswapPair internal pair;

    function _fraxBammSetUp() internal {
        fraxOwner = address(this);
        fraxUser1 = makeAddr("fraxUser1");
    }

    function _deploySortedTokens() internal {
        DummyToken tA = new DummyToken();
        DummyToken tB = new DummyToken();
        if (address(tB) < address(tA)) {
            token0 = tB;
            token1 = tA;
        } else {
            token0 = tA;
            token1 = tB;
        }
        token0.mint(fraxOwner, type(uint256).max / 2);
        token1.mint(fraxOwner, type(uint256).max / 2);
    }

    function _createPair(uint256 feeNumerator) internal returns (uint256 pairFeeTier) {
        _deploySortedTokens();
        FraxswapFactory factory = new FraxswapFactory(fraxOwner);
        pairFeeTier = 10_000 - feeNumerator;
        address pairAddr = factory.createPair(address(token0), address(token1), pairFeeTier);
        pair = FraxswapPair(pairAddr);
    }

    function _mintPairLiquidity(uint256 amount0, uint256 amount1) internal {
        token0.transfer(address(pair), amount0);
        token1.transfer(address(pair), amount1);
        pair.mint(fraxOwner);
    }

    function _fundFraxUser(address user, uint256 amount) internal {
        token0.transfer(user, amount);
        token1.transfer(user, amount);
    }

    function _pairSwap(int256 swapAmount, address recipient) internal {
        if (swapAmount > 0) {
            uint256 out = pair.getAmountOut(uint256(swapAmount), address(token0));
            if (out > 0) {
                token0.transfer(address(pair), uint256(swapAmount));
                pair.swap(0, out, recipient, "");
            }
        } else if (swapAmount < 0) {
            uint256 out = pair.getAmountOut(uint256(-swapAmount), address(token1));
            if (out > 0) {
                token1.transfer(address(pair), uint256(-swapAmount));
                pair.swap(out, 0, recipient, "");
            }
        }
    }

    function _getAmountOut(uint256 reserveIn, uint256 reserveOut, uint256 fee, uint256 amountIn)
        internal
        pure
        returns (uint256)
    {
        uint256 amountInWithFee = amountIn * fee;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 10_000 + amountInWithFee;
        return numerator / denominator;
    }

    function _min5(uint256 a, uint256 b, uint256 c, uint256 d, uint256 e) internal pure returns (uint256) {
        uint256 r = a;
        if (b < r) r = b;
        if (c < r) r = c;
        if (d < r) r = d;
        if (e < r) r = e;
        return r;
    }

    function _pow10(uint256 exp) internal pure returns (uint256) {
        uint256 r = 1;
        for (uint256 i = 0; i < exp; i++) {
            r *= 10;
        }
        return r;
    }
}