// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {UniswapV2Service} from "contracts/protocols/dexes/uniswap/v2/UniswapV2Service.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Uniswap.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_saleQuoteMin_Uniswap is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
    }

    function test_saleQuoteMin_Uniswap_BalancedPool() public {
        _initializeUniswapBalancedPools();
        _testSaleQuoteMin_Uniswap(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB);
    }

    function test_saleQuoteMin_Uniswap_UnbalancedPool() public {
        _initializeUniswapUnbalancedPools();
        _testSaleQuoteMin_Uniswap(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB);
    }

    function test_saleQuoteMin_Uniswap_ExtremeUnbalancedPool() public {
        _initializeUniswapExtremeUnbalancedPools();
        _testSaleQuoteMin_Uniswap(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB);
    }

    function _testSaleQuoteMin_Uniswap(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB
    ) internal {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        (uint256 reserveIn, uint256 reserveOut) = ConstProdUtils._sortReserves(address(tokenA), pair.token0(), r0, r1);

        uint256 feePercent = 300; // 0.3% Uniswap fee

        // Minimum input to receive at least 1 unit of output
        uint256 expectedMinInput = ConstProdUtils._purchaseQuote(1, reserveIn, reserveOut, feePercent);

        tokenA.mint(address(this), expectedMinInput);

        uint256 actualOutput = UniswapV2Service._swap(
            uniswapV2Router,
            pair,
            expectedMinInput,
            tokenA,
            tokenB
        );

        assertGe(actualOutput, 1, "Should get at least 1 unit of output");

        console.log("Expected min input:", expectedMinInput);
        console.log("Actual output:", actualOutput);
    }
}
