// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {IUniswapV2Router} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Uniswap.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_purchaseQuote_Uniswap is TestBase_ConstProdUtils_Uniswap {
    using ConstProdUtils for uint256;

    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
    }

    function _getPath(address tokenIn, address tokenOut) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
    }

    // 4-param tests (A->B)
    function test_purchaseQuote_Uniswap_balancedPool_purchasesTokenB() public {
        _initializeUniswapBalancedPools();
        _testPurchaseQuote_Uniswap_AtoB(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, /*reduce=*/1, /*use5param=*/false);
    }

    function test_purchaseQuote_Uniswap_unbalancedPool_purchasesTokenB() public {
        _initializeUniswapUnbalancedPools();
        _testPurchaseQuote_Uniswap_AtoB(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB, /*reduce=*/0, /*use5param=*/false);
    }

    function test_purchaseQuote_Uniswap_extremeUnbalancedPool_purchasesTokenB() public {
        _initializeUniswapExtremeUnbalancedPools();
        _testPurchaseQuote_Uniswap_AtoB(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB, /*reduce=*/0, /*use5param=*/false);
    }

    // 5-param tests (A->B)
    function test_purchaseQuote_Uniswap_balancedPool_5param_purchasesTokenB() public {
        _initializeUniswapBalancedPools();
        _testPurchaseQuote_Uniswap_AtoB(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, /*reduce=*/1, /*use5param=*/true);
    }

    function test_purchaseQuote_Uniswap_unbalancedPool_5param_purchasesTokenB() public {
        _initializeUniswapUnbalancedPools();
        _testPurchaseQuote_Uniswap_AtoB(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB, /*reduce=*/0, /*use5param=*/true);
    }

    function test_purchaseQuote_Uniswap_extremeUnbalancedPool_5param_purchasesTokenB() public {
        _initializeUniswapExtremeUnbalancedPools();
        _testPurchaseQuote_Uniswap_AtoB(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB, /*reduce=*/0, /*use5param=*/true);
    }

    // B->A direction tests
    function test_purchaseQuote_Uniswap_balancedPool_purchasesTokenA() public {
        _initializeUniswapBalancedPools();
        _testPurchaseQuote_Uniswap_BtoA(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, /*reduce=*/1, /*use5param=*/false);
    }

    function test_purchaseQuote_Uniswap_unbalancedPool_purchasesTokenA() public {
        _initializeUniswapUnbalancedPools();
        _testPurchaseQuote_Uniswap_BtoA(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB, /*reduce=*/1, /*use5param=*/false);
    }

    function test_purchaseQuote_Uniswap_extremeUnbalancedPool_purchasesTokenA() public {
        _initializeUniswapExtremeUnbalancedPools();
        _testPurchaseQuote_Uniswap_BtoA(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB, /*reduce=*/1, /*use5param=*/false);
    }

    // 5-param B->A
    function test_purchaseQuote_Uniswap_balancedPool_5param_purchasesTokenA() public {
        _initializeUniswapBalancedPools();
        _testPurchaseQuote_Uniswap_BtoA(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB, /*reduce=*/1, /*use5param=*/true);
    }

    function test_purchaseQuote_Uniswap_unbalancedPool_5param_purchasesTokenA() public {
        _initializeUniswapUnbalancedPools();
        _testPurchaseQuote_Uniswap_BtoA(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB, /*reduce=*/1, /*use5param=*/true);
    }

    function test_purchaseQuote_Uniswap_extremeUnbalancedPool_5param_purchasesTokenA() public {
        _initializeUniswapExtremeUnbalancedPools();
        _testPurchaseQuote_Uniswap_BtoA(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB, /*reduce=*/1, /*use5param=*/true);
    }

    function _testPurchaseQuote_Uniswap_AtoB(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB,
        uint256 reduce,
        bool use5param
    ) internal {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, ) = ConstProdUtils._sortReserves(address(tokenA), pair.token0(), r0, 300, r1, 300);

        uint256 desiredOutput = ((reserveB / (reduce == 1 ? 10 : (reduce == 0 ? 20 : 100))) - reduce);
        if (use5param) {
            uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent, 100000);
            tokenA.mint(address(this), expectedInput);
            tokenA.approve(address(uniswapV2Router), expectedInput);
            uint256[] memory amounts = uniswapV2Router.swapTokensForExactTokens(
                desiredOutput,
                expectedInput,
                _getPath(address(tokenA), address(tokenB)),
                address(this),
                block.timestamp + 300
            );
            // amounts[0] is the actual input used; must equal expectedInput
            assertEq(amounts[0], expectedInput, "Input used must equal quoted input");
        } else {
            uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent);
            tokenA.mint(address(this), expectedInput);
            tokenA.approve(address(uniswapV2Router), expectedInput);
            uint256[] memory amounts = uniswapV2Router.swapTokensForExactTokens(
                desiredOutput,
                expectedInput,
                _getPath(address(tokenA), address(tokenB)),
                address(this),
                block.timestamp + 300
            );
            assertEq(amounts[0], expectedInput, "Input used must equal quoted input");
        }
    }

    function _testPurchaseQuote_Uniswap_BtoA(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB,
        uint256 reduce,
        bool use5param
    ) internal {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, ) = ConstProdUtils._sortReserves(address(tokenA), pair.token0(), r0, 300, r1, 300);

        uint256 desiredOutput = ((reserveA / (reduce == 1 ? 10 : (reduce == 0 ? 20 : 100))) - reduce);
        if (use5param) {
            uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent, 100000);
            tokenB.mint(address(this), expectedInput);
            tokenB.approve(address(uniswapV2Router), expectedInput);
            uniswapV2Router.swapExactTokensForTokens(
                expectedInput,
                0,
                _getPath(address(tokenB), address(tokenA)),
                address(this),
                block.timestamp + 300
            );
            uint256 actualOutput = tokenA.balanceOf(address(this));
            uint256 minExpected = (desiredOutput * 999) / 1000;
            assertGe(actualOutput, minExpected, "Should get at least 99.9% of desired output");
        } else {
            uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent);
            tokenB.mint(address(this), expectedInput);
            tokenB.approve(address(uniswapV2Router), expectedInput);
            uniswapV2Router.swapExactTokensForTokens(
                expectedInput,
                0,
                _getPath(address(tokenB), address(tokenA)),
                address(this),
                block.timestamp + 300
            );
            uint256 actualOutput = tokenA.balanceOf(address(this));
            uint256 minExpected = (desiredOutput * 999) / 1000;
            assertGe(actualOutput, minExpected, "Should get at least 99.9% of desired output");
        }
    }
}
