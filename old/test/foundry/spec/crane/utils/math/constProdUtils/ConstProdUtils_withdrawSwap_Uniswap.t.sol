// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Uniswap.sol";
import {UniswapV2Service} from "@crane/contracts/protocols/dexes/uniswap/v2/UniswapV2Service.sol";
import {UniswapV2Utils} from "contracts/utils/math/UniswapV2Utils.sol";

contract ConstProdUtils_withdrawSwap_Uniswap_Test is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
    }

    function test_withdrawSwapQuote_uniswap() public {
        _initializeUniswapBalancedPools();

        uint256 depositAmountA = 3000e18;
        uint256 depositAmountB = 3000e18;

        uniswapBalancedTokenA.mint(address(this), depositAmountA);
        uniswapBalancedTokenB.mint(address(this), depositAmountB);

        uint256 liquidityGained = UniswapV2Service._deposit(uniswapV2Router, uniswapBalancedTokenA, uniswapBalancedTokenB, depositAmountA, depositAmountB);

        uint256 liquidityToWithdraw = liquidityGained / 2;

        (uint112 reserveA, uint112 reserveB,) = uniswapBalancedPair.getReserves();
        uint256 totalSupply = uniswapBalancedPair.totalSupply();
        uint256 feePercent = 300;

        uint256 expectedAmountOut = UniswapV2Utils._quoteWithdrawSwapFee(
            liquidityToWithdraw,
            totalSupply,
            uint256(reserveA),
            uint256(reserveB),
            feePercent,
            0,
            0,
            false
        );

        uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));

        uint256 actualAmountOut = UniswapV2Service._withdrawSwapDirect(uniswapBalancedPair, uniswapV2Router, liquidityToWithdraw, uniswapBalancedTokenA, uniswapBalancedTokenB);

        uint256 finalBalanceA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 receivedAmount = finalBalanceA - initialBalanceA;

        assertEq(actualAmountOut, expectedAmountOut);
        assertEq(receivedAmount, actualAmountOut);
    }
}
