// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {ICamelotV2Router} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Camelot.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";

contract ConstProdUtils_purchaseQuote_Camelot is TestBase_ConstProdUtils_Camelot {
    using ConstProdUtils for uint256;

    function setUp() public override {
        TestBase_ConstProdUtils_Camelot.setUp();
    }

    function _getPath(address tokenIn, address tokenOut) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
    }

    // 4-param A->B
    function test_purchaseQuote_Camelot_balancedPool_purchasesTokenB() public {
        _initializeCamelotBalancedPools();
        _testPurchaseQuote_Camelot_AtoB(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB, /*reduce=*/1, /*use5param=*/false);
    }

    function test_purchaseQuote_Camelot_unbalancedPool_purchasesTokenB() public {
        _initializeCamelotUnbalancedPools();
        _testPurchaseQuote_Camelot_AtoB(camelotUnbalancedPair, camelotUnbalancedTokenA, camelotUnbalancedTokenB, /*reduce=*/1, /*use5param=*/false);
    }

    function test_purchaseQuote_Camelot_extremeUnbalancedPool_purchasesTokenB() public {
        _initializeCamelotExtremeUnbalancedPools();
        _testPurchaseQuote_Camelot_AtoB(camelotExtremeUnbalancedPair, camelotExtremeTokenA, camelotExtremeTokenB, /*reduce=*/1, /*use5param=*/false);
    }

    // 5-param A->B
    function test_purchaseQuote_Camelot_balancedPool_5param_purchasesTokenB() public {
        _initializeCamelotBalancedPools();
        _testPurchaseQuote_Camelot_AtoB(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB, /*reduce=*/1, /*use5param=*/true);
    }

    function test_purchaseQuote_Camelot_unbalancedPool_5param_purchasesTokenB() public {
        _initializeCamelotUnbalancedPools();
        _testPurchaseQuote_Camelot_AtoB(camelotUnbalancedPair, camelotUnbalancedTokenA, camelotUnbalancedTokenB, /*reduce=*/1, /*use5param=*/true);
    }

    function test_purchaseQuote_Camelot_extremeUnbalancedPool_5param_purchasesTokenB() public {
        _initializeCamelotExtremeUnbalancedPools();
        _testPurchaseQuote_Camelot_AtoB(camelotExtremeUnbalancedPair, camelotExtremeTokenA, camelotExtremeTokenB, /*reduce=*/1, /*use5param=*/true);
    }

    // B->A variants (4- and 5-param)
    function test_purchaseQuote_Camelot_balancedPool_purchasesTokenA() public {
        _initializeCamelotBalancedPools();
        _testPurchaseQuote_Camelot_BtoA(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB, /*reduce=*/1, /*use5param=*/false);
    }

    function test_purchaseQuote_Camelot_unbalancedPool_purchasesTokenA() public {
        _initializeCamelotUnbalancedPools();
        _testPurchaseQuote_Camelot_BtoA(camelotUnbalancedPair, camelotUnbalancedTokenA, camelotUnbalancedTokenB, /*reduce=*/1, /*use5param=*/false);
    }

    function test_purchaseQuote_Camelot_extremeUnbalancedPool_purchasesTokenA() public {
        _initializeCamelotExtremeUnbalancedPools();
        _testPurchaseQuote_Camelot_BtoA(camelotExtremeUnbalancedPair, camelotExtremeTokenA, camelotExtremeTokenB, /*reduce=*/1, /*use5param=*/false);
    }

    function test_purchaseQuote_Camelot_balancedPool_5param_purchasesTokenA() public {
        _initializeCamelotBalancedPools();
        _testPurchaseQuote_Camelot_BtoA(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB, /*reduce=*/1, /*use5param=*/true);
    }

    function test_purchaseQuote_Camelot_unbalancedPool_5param_purchasesTokenA() public {
        _initializeCamelotUnbalancedPools();
        _testPurchaseQuote_Camelot_BtoA(camelotUnbalancedPair, camelotUnbalancedTokenA, camelotUnbalancedTokenB, /*reduce=*/1, /*use5param=*/true);
    }

    function test_purchaseQuote_Camelot_extremeUnbalancedPool_5param_purchasesTokenA() public {
        _initializeCamelotExtremeUnbalancedPools();
        _testPurchaseQuote_Camelot_BtoA(camelotExtremeUnbalancedPair, camelotExtremeTokenA, camelotExtremeTokenB, /*reduce=*/1, /*use5param=*/true);
    }

    function _testPurchaseQuote_Camelot_AtoB(
        ICamelotPair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB,
        uint256 reduce,
        bool use5param
    ) internal {
        (uint112 r0, uint112 r1, uint16 token0Fee, uint16 token1Fee) = pair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, ) = ConstProdUtils._sortReserves(
            address(tokenA), pair.token0(), r0, uint256(token0Fee), r1, uint256(token1Fee)
        );

        uint256 desiredOutput = ((reserveB / (reduce == 1 ? 10 : (reduce == 0 ? 20 : 100))) - reduce);
        if (use5param) {
            uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent, 100000);
            tokenA.mint(address(this), expectedInput);
            tokenA.approve(address(camelotV2Router), expectedInput);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                desiredOutput,
                _getPath(address(tokenA), address(tokenB)),
                address(this),
                address(0),
                block.timestamp + 300
            );
            uint256 actualOutput = tokenB.balanceOf(address(this));
            assertGe(actualOutput, desiredOutput, "Should receive at least desired output");
        } else {
            uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, feePercent);
            tokenA.mint(address(this), expectedInput);
            tokenA.approve(address(camelotV2Router), expectedInput);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                desiredOutput,
                _getPath(address(tokenA), address(tokenB)),
                address(this),
                address(0),
                block.timestamp + 300
            );
            uint256 actualOutput = tokenB.balanceOf(address(this));
            assertGe(actualOutput, desiredOutput, "Should receive at least desired output");
        }
    }

    function _testPurchaseQuote_Camelot_BtoA(
        ICamelotPair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB,
        uint256 reduce,
        bool use5param
    ) internal {
        (uint112 r0, uint112 r1, uint16 token0Fee, uint16 token1Fee) = pair.getReserves();
        (uint256 reserveA, uint256 feePercent, uint256 reserveB, ) = ConstProdUtils._sortReserves(
            address(tokenA), pair.token0(), r0, uint256(token0Fee), r1, uint256(token1Fee)
        );

        uint256 desiredOutput = ((reserveA / (reduce == 1 ? 10 : (reduce == 0 ? 20 : 100))) - reduce);
        if (use5param) {
            uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent, 100000);
            tokenB.mint(address(this), expectedInput);
            tokenB.approve(address(camelotV2Router), expectedInput);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                desiredOutput,
                _getPath(address(tokenB), address(tokenA)),
                address(this),
                address(0),
                block.timestamp + 300
            );
            uint256 actualOutput = tokenA.balanceOf(address(this));
            assertGe(actualOutput, desiredOutput, "Should receive at least desired output");
        } else {
            uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, feePercent);
            tokenB.mint(address(this), expectedInput);
            tokenB.approve(address(camelotV2Router), expectedInput);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                expectedInput,
                desiredOutput,
                _getPath(address(tokenB), address(tokenA)),
                address(this),
                address(0),
                block.timestamp + 300
            );
            uint256 actualOutput = tokenA.balanceOf(address(this));
            assertGe(actualOutput, desiredOutput, "Should receive at least desired output");
        }
    }
}
