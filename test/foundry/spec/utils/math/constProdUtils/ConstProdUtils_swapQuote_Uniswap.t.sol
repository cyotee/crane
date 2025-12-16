// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {UniswapV2Service} from "contracts/protocols/dexes/uniswap/v2/UniswapV2Service.sol";
import {IUniswapV2Router} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Uniswap.sol";

contract ConstProdUtils_swapQuote_Uniswap_Test is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
    }

    function test_saleQuote_uniswap_swap() public {
        uint256 swapAmount = 1000e18;

        _initializeUniswapBalancedPools();

        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveIn, uint256 reserveOut) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );
        uint256 feePercent = 300; // 0.3% standard Uniswap fee

        uint256 expectedAmountOut = ConstProdUtils._saleQuote(swapAmount, reserveIn, reserveOut, feePercent);

        uniswapBalancedTokenA.mint(address(this), swapAmount);

        uint256 initialBalanceB = uniswapBalancedTokenB.balanceOf(address(this));

        uint256 actualAmountOut = UniswapV2Service._swap(
            uniswapV2Router,
            uniswapBalancedPair,
            swapAmount,
            uniswapBalancedTokenA,
            uniswapBalancedTokenB
        );

        uint256 finalBalanceB = uniswapBalancedTokenB.balanceOf(address(this));
        uint256 receivedAmount = finalBalanceB - initialBalanceB;

        assert(actualAmountOut == expectedAmountOut);
        assert(receivedAmount == actualAmountOut);

        console.log("Uniswap swap test passed:");
        console.log("  Amount in:       ", swapAmount);
        console.log("  Expected out:    ", expectedAmountOut);
        console.log("  Actual out:      ", actualAmountOut);
        console.log("  Received amount: ", receivedAmount);
        console.log("  Fee percent:     ", feePercent);
    }

    function test_saleQuote_staticCalculation() public pure {
        uint256 amountIn = 1000e18;
        uint256 reserveIn = 10000e18;
        uint256 reserveOut = 10000e18;
        uint256 feePercent = 300; // 0.3%

        uint256 amountOut = ConstProdUtils._saleQuote(amountIn, reserveIn, reserveOut, feePercent);

        assert(amountOut > 900e18 && amountOut < 910e18);

        // keep a lightweight console log in non-pure tests; this is pure for static verification
    }
}
