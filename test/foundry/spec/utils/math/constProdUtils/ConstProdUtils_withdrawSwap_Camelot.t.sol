// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {FEE_DENOMINATOR} from "contracts/constants/Constants.sol";
import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Camelot.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/CamelotV2Service.sol";
import {CamelotV2Utils} from "contracts/utils/math/CamelotV2Utils.sol";

contract ConstProdUtils_withdrawSwap_Camelot_Test is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        TestBase_ConstProdUtils_Camelot.setUp();
    }

    function test_withdrawSwapQuote_camelot() public {
        _initializeCamelotBalancedPools();

        uint256 depositAmountA = 3000e18;
        uint256 depositAmountB = 3000e18;

        camelotBalancedTokenA.mint(address(this), depositAmountA);
        camelotBalancedTokenB.mint(address(this), depositAmountB);

        uint256 liquidityGained = CamelotV2Service._deposit(camelotV2Router, camelotBalancedTokenA, camelotBalancedTokenB, depositAmountA, depositAmountB);

        uint256 liquidityToWithdraw = liquidityGained / 2;

        (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, ) = ConstProdUtils._sortReserves(address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee));
        uint256 totalSupply = camelotBalancedPair.totalSupply();

        uint256 expectedAmountOut = CamelotV2Utils._quoteWithdrawSwapWithFee(
            liquidityToWithdraw,
            totalSupply,
            reserveA,
            reserveB,
            feePercent,
            FEE_DENOMINATOR,
            0,
            0,
            false
        );

        uint256 initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));

        uint256 actualAmountOut = CamelotV2Service._withdrawSwapDirect(camelotBalancedPair, camelotV2Router, liquidityToWithdraw, camelotBalancedTokenA, camelotBalancedTokenB, address(0));

        uint256 finalBalanceA = camelotBalancedTokenA.balanceOf(address(this));
        uint256 receivedAmount = finalBalanceA - initialBalanceA;

        assertEq(actualAmountOut, expectedAmountOut);
        assertEq(receivedAmount, actualAmountOut);
    }
}
