// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Uniswap.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_calculateZapOutLP_Uniswap_Test is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
    }

    function test_calculateZapOutLP_Uniswap_balancedPool() public {
        _initializeUniswapBalancedPools();

        (uint112 r0, uint112 r1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), r0, r1
        );
        uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

        uint256 desiredOut = reserveA / 10;

        uint256 expectedLpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(
            desiredOut,
            lpTotalSupply,
            reserveA,
            reserveB,
            300,
            100000,
            0,
            0,
            false
        );

        uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

        uniswapBalancedPair.transfer(address(uniswapBalancedPair), expectedLpNeeded);
        (uint256 amt0, uint256 amt1) = uniswapBalancedPair.burn(address(this));
        uint256 amountA;
        uint256 amountB;
        if (uniswapBalancedPair.token0() == address(uniswapBalancedTokenA)) {
            amountA = amt0;
            amountB = amt1;
        } else {
            amountA = amt1;
            amountB = amt0;
        }

        if (amountB > 0) {
            uniswapBalancedTokenB.approve(address(uniswapV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapBalancedTokenB);
            path[1] = address(uniswapBalancedTokenA);

            uniswapV2Router.swapExactTokensForTokens(amountB, 1, path, address(this), block.timestamp);
        }

        uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

        // Expect exact equivalence
        assertEq(actualTokenAReceived, desiredOut, "Should receive exact desired TokenA amount");
    }

    function test_calculateZapOutLP_Uniswap_unbalancedPool() public {
        _initializeUniswapUnbalancedPools();

        (uint112 r0u, uint112 r1u,) = uniswapUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), r0u, r1u
        );
        uint256 lpTotalSupply = uniswapUnbalancedPair.totalSupply();

        uint256 desiredOut = reserveA / 8;

        uint256 expectedLpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(
            desiredOut,
            lpTotalSupply,
            reserveA,
            reserveB,
            300,
            100000,
            0,
            0,
            false
        );

        uint256 initialTokenABalance = uniswapUnbalancedTokenA.balanceOf(address(this));

        uniswapUnbalancedPair.transfer(address(uniswapUnbalancedPair), expectedLpNeeded);
        (uint256 amt0u, uint256 amt1u) = uniswapUnbalancedPair.burn(address(this));
        uint256 amountAu;
        uint256 amountBu;
        if (uniswapUnbalancedPair.token0() == address(uniswapUnbalancedTokenA)) {
            amountAu = amt0u;
            amountBu = amt1u;
        } else {
            amountAu = amt1u;
            amountBu = amt0u;
        }

        if (amountBu > 0) {
            uniswapUnbalancedTokenB.approve(address(uniswapV2Router), amountBu);
            address[] memory path = new address[](2);
            path[0] = address(uniswapUnbalancedTokenB);
            path[1] = address(uniswapUnbalancedTokenA);

            uniswapV2Router.swapExactTokensForTokens(amountBu, 1, path, address(this), block.timestamp);
        }

        uint256 finalTokenABalance = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

        // Allow tiny rounding tolerance (few wei) from integer math
        assertTrue(
            actualTokenAReceived >= desiredOut && actualTokenAReceived <= desiredOut + 10,
            "Should receive desired TokenA amount within tolerance"
        );
    }

    function test_calculateZapOutLP_Uniswap_extremeUnbalancedPool() public {
        _initializeUniswapExtremeUnbalancedPools();

        (uint112 r0e, uint112 r1e,) = uniswapExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenA), uniswapExtremeUnbalancedPair.token0(), r0e, r1e
        );
        uint256 lpTotalSupply = uniswapExtremeUnbalancedPair.totalSupply();

        uint256 desiredOut = reserveA / 20;

        uint256 expectedLpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(
            desiredOut,
            lpTotalSupply,
            reserveA,
            reserveB,
            300,
            100000,
            0,
            0,
            false
        );

        uint256 initialTokenABalance = uniswapExtremeTokenA.balanceOf(address(this));

        uniswapExtremeUnbalancedPair.transfer(address(uniswapExtremeUnbalancedPair), expectedLpNeeded);
        (uint256 amt0e, uint256 amt1e) = uniswapExtremeUnbalancedPair.burn(address(this));
        uint256 amountAe;
        uint256 amountBe;
        if (uniswapExtremeUnbalancedPair.token0() == address(uniswapExtremeTokenA)) {
            amountAe = amt0e;
            amountBe = amt1e;
        } else {
            amountAe = amt1e;
            amountBe = amt0e;
        }

        if (amountBe > 0) {
            uniswapExtremeTokenB.approve(address(uniswapV2Router), amountBe);
            address[] memory path = new address[](2);
            path[0] = address(uniswapExtremeTokenB);
            path[1] = address(uniswapExtremeTokenA);

            uniswapV2Router.swapExactTokensForTokens(amountBe, 1, path, address(this), block.timestamp);
        }

        uint256 finalTokenABalance = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 actualTokenAReceived = finalTokenABalance - initialTokenABalance;

        // Allow tiny rounding tolerance (few wei) from integer math
        assertTrue(
            actualTokenAReceived >= desiredOut && actualTokenAReceived <= desiredOut + 10,
            "Should receive desired TokenA amount within tolerance"
        );
    }
}
