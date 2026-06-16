// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `Fraxswap/fraxswap-uniV2-test.js` and `Fraxswap-UniswapV2-test.js` (equivalent V2 pair scenarios).
/// @dev Uses FraxswapFactory/FraxswapPair (V2-style mint/swap; fee 30 = 0.30%).

import {Test} from "forge-std/Test.sol";
import {FraxswapFactory} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapFactory.sol";
import {FraxswapPair} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol";
import {DummyToken} from "@crane/contracts/protocols/tokens/stable/frax/Fraxferry/DummyToken.sol";

contract Fraxswap_UniswapV2_Test is Test {
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;
    uint256 internal constant POOL_FEE = 30; // 0.30% on 10000 scale

    address internal owner;
    address internal user1;

    DummyToken internal token0;
    DummyToken internal token1;
    FraxswapFactory internal factory;
    FraxswapPair internal pair;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");

        DummyToken tA = new DummyToken();
        DummyToken tB = new DummyToken();
        if (address(tB) < address(tA)) {
            token0 = tB;
            token1 = tA;
        } else {
            token0 = tA;
            token1 = tB;
        }

        token0.mint(owner, 1000e18);
        token0.mint(user1, 1000e18);
        token1.mint(owner, 1000e18);
        token1.mint(user1, 1000e18);

        factory = new FraxswapFactory(owner);
        address pairAddr = factory.createPair(address(token0), address(token1));
        pair = FraxswapPair(pairAddr);
    }

    function test_setupContracts() public view {
        assertTrue(address(token0) != address(0));
        assertTrue(address(pair) != address(0));
        assertEq(factory.getPair(address(token0), address(token1)), address(pair));
    }

    function test_mint() public {
        uint256 amount = 100e18;

        token0.transfer(address(pair), amount);
        token1.transfer(address(pair), amount);
        pair.mint(owner);

        assertEq(token0.balanceOf(address(pair)), amount);
        assertEq(token1.balanceOf(address(pair)), amount);
        assertEq(pair.balanceOf(owner), amount - MINIMUM_LIQUIDITY);
    }

    function test_swap() public {
        uint256 reserveIn = 100e18;
        uint256 reserveOut = 100e18;
        uint256 tradeAmount = 1e18;

        token0.transfer(address(pair), reserveIn);
        token1.transfer(address(pair), reserveOut);
        pair.mint(owner);

        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 feeMultiplier = 10_000 - POOL_FEE;
        uint256 expectedOutput =
            (tradeAmount * feeMultiplier * r1) / (uint256(r0) * 10_000 + tradeAmount * feeMultiplier);

        uint256 balanceBefore = token1.balanceOf(user1);

        vm.startPrank(user1);
        token0.transfer(address(pair), tradeAmount);
        pair.swap(0, expectedOutput, user1, "");
        vm.stopPrank();

        assertEq(token1.balanceOf(user1) - balanceBefore, expectedOutput);
    }

    function test_swap_token0() public {
        uint256 token0Amount = 5e18;
        uint256 token1Amount = 10e18;
        _addLiquidity(token0Amount, token1Amount);

        uint256 swapAmount = 1e18;
        uint256 expectedOut = _getAmountOut(swapAmount, token0Amount, token1Amount);

        uint256 token1Before = token1.balanceOf(user1);

        vm.startPrank(user1);
        token0.transfer(address(pair), swapAmount);
        pair.swap(0, expectedOut, user1, "");
        vm.stopPrank();

        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertEq(r0, uint112(token0Amount + swapAmount));
        assertEq(r1, uint112(token1Amount - expectedOut));
        assertEq(token1.balanceOf(user1) - token1Before, expectedOut);
    }

    function test_swap_token1() public {
        uint256 token0Amount = 5e18;
        uint256 token1Amount = 10e18;
        _addLiquidity(token0Amount, token1Amount);

        uint256 swapAmount = 1e18;
        uint256 expectedOut = _getAmountOut(swapAmount, token1Amount, token0Amount);

        uint256 token0Before = token0.balanceOf(user1);

        vm.startPrank(user1);
        token1.transfer(address(pair), swapAmount);
        pair.swap(expectedOut, 0, user1, "");
        vm.stopPrank();

        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertEq(r1, uint112(token1Amount + swapAmount));
        assertEq(r0, uint112(token0Amount - expectedOut));
        assertEq(token0.balanceOf(user1) - token0Before, expectedOut);
    }

    function test_mint_sqrtLiquidity() public {
        uint256 token0Amount = 1e18;
        uint256 token1Amount = 4e18;

        vm.startPrank(user1);
        token0.transfer(address(pair), token0Amount);
        token1.transfer(address(pair), token1Amount);
        pair.mint(user1);
        vm.stopPrank();

        uint256 expectedLiquidity = 2e18; // sqrt(1e18 * 4e18)
        assertEq(pair.totalSupply(), expectedLiquidity);
        assertEq(pair.balanceOf(user1), expectedLiquidity - MINIMUM_LIQUIDITY);
    }

    function _addLiquidity(uint256 token0Amount, uint256 token1Amount) internal {
        token0.transfer(address(pair), token0Amount);
        token1.transfer(address(pair), token1Amount);
        pair.mint(owner);
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * (10_000 - POOL_FEE);
        return (amountInWithFee * reserveOut) / (reserveIn * 10_000 + amountInWithFee);
    }
}
