// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotV2Router} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {ICamelotFactory} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {IERC20MintBurn} from "contracts/interfaces/IERC20MintBurn.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_quoteSwapDepositWithFee_Camelot is TestBase_ConstProdUtils_Camelot {
    using ConstProdUtils for uint256;

    uint256 constant TEST_AMOUNT_IN = 1000000; // 1M wei input amount

    struct TestData {
        uint256 totalSupply;
        uint256 kLast;
        uint256 reserveA;
        uint256 reserveB;
        uint256 inputTokenFee;
        uint256 ownerFeeShare;
        uint256 quotedLpAmt;
        uint256 actualLpAmt;
    }

    struct ZapInData {
        uint256 lpBalanceBefore;
        uint256 inputTokenFee;
        uint256 swapAmount;
        uint256 opTokenAmtIn;
        uint256 remainingAmountA;
        uint256 lpBalanceAfter;
    }

    function setUp() public override {
        super.setUp();
    }

    function _executeCamelotZapInAndValidate(
        ICamelotPair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB,
        uint256 amountIn,
        uint256 reserveA,
        uint256 /*reserveB*/,
        uint256 /*ownerFeeShare*/
    ) internal returns (uint256 actualLpAmt) {
        ZapInData memory z;
        z.lpBalanceBefore = pair.balanceOf(address(this));

        tokenA.mint(address(this), amountIn);
        tokenA.approve(address(camelotV2Router), amountIn);

        {
            (uint112 r0, uint112 r1, uint16 token0Fee, uint16 token1Fee) = pair.getReserves();
            z.inputTokenFee = (address(tokenA) == pair.token0()) ? token0Fee : token1Fee;
        }

        z.swapAmount = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, z.inputTokenFee);

        if (z.swapAmount > 0) {
            address[] memory path = new address[](2);
            path[0] = address(tokenA);
            path[1] = address(tokenB);
            ICamelotV2Router(camelotV2Router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                z.swapAmount, 1, path, address(this), address(0), block.timestamp + 300
            );
        }

        z.opTokenAmtIn = tokenB.balanceOf(address(this));
        z.remainingAmountA = amountIn - z.swapAmount;

        tokenA.approve(address(camelotV2Router), z.remainingAmountA);
        tokenB.approve(address(camelotV2Router), z.opTokenAmtIn);

        (, , actualLpAmt) = ICamelotV2Router(camelotV2Router).addLiquidity(
            address(tokenA),
            address(tokenB),
            z.remainingAmountA,
            z.opTokenAmtIn,
            1,
            1,
            address(this),
            block.timestamp + 300
        );

        z.lpBalanceAfter = pair.balanceOf(address(this));
        actualLpAmt = z.lpBalanceAfter - z.lpBalanceBefore;
    }

    function _testSwapDepositWithFeeCamelot(
        ICamelotPair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB,
        bool feesEnabled
    ) internal {
        TestData memory data;
        {
            (uint112 r0, uint112 r1, uint16 token0Fee, uint16 token1Fee) = pair.getReserves();
            data.totalSupply = pair.totalSupply();
            data.kLast = pair.kLast();

            (data.reserveA,, data.reserveB,) = ConstProdUtils._sortReserves(
                address(tokenA),
                pair.token0(),
                uint256(r0),
                token0Fee,
                uint256(r1),
                token1Fee
            );

            data.inputTokenFee = (address(tokenA) == pair.token0()) ? token0Fee : token1Fee;
            data.ownerFeeShare = ICamelotFactory(camelotV2Factory).ownerFeeShare();
        }

        data.quotedLpAmt = ConstProdUtils._quoteSwapDepositWithFee(
            TEST_AMOUNT_IN,
            data.totalSupply,
            data.reserveA,
            data.reserveB,
            data.inputTokenFee,
            data.kLast,
            data.ownerFeeShare,
            feesEnabled
        );

        data.actualLpAmt = _executeCamelotZapInAndValidate(pair, tokenA, tokenB, TEST_AMOUNT_IN, data.reserveA, data.reserveB, data.ownerFeeShare);

        assertTrue(data.quotedLpAmt > 0, "quoted > 0");
        assertTrue(data.actualLpAmt > 0, "actual > 0");
        assertEq(data.quotedLpAmt, data.actualLpAmt, "Camelot quote should exactly match actual LP amount");
    }

    // Tests
    function test_quoteSwapDepositWithFee_Camelot_balancedPool_swapsTokenA_feesDisabled() public {
        _initializeCamelotBalancedPools();
        _testSwapDepositWithFeeCamelot(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB, false);
    }

    function test_quoteSwapDepositWithFee_Camelot_balancedPool_swapsTokenB_feesDisabled() public {
        _initializeCamelotBalancedPools();
        _testSwapDepositWithFeeCamelot(camelotBalancedPair, camelotBalancedTokenB, camelotBalancedTokenA, false);
    }

    function test_quoteSwapDepositWithFee_Camelot_unbalancedPool_swapsTokenA_feesDisabled() public {
        _initializeCamelotUnbalancedPools();
        _testSwapDepositWithFeeCamelot(camelotUnbalancedPair, camelotUnbalancedTokenA, camelotUnbalancedTokenB, false);
    }

    function test_quoteSwapDepositWithFee_Camelot_unbalancedPool_swapsTokenB_feesDisabled() public {
        _initializeCamelotUnbalancedPools();
        _testSwapDepositWithFeeCamelot(camelotUnbalancedPair, camelotUnbalancedTokenB, camelotUnbalancedTokenA, false);
    }

    function test_quoteSwapDepositWithFee_Camelot_extremeUnbalancedPool_swapsTokenA_feesDisabled() public {
        _initializeCamelotExtremeUnbalancedPools();
        _testSwapDepositWithFeeCamelot(camelotExtremeUnbalancedPair, camelotExtremeTokenA, camelotExtremeTokenB, false);
    }

    function test_quoteSwapDepositWithFee_Camelot_extremeUnbalancedPool_swapsTokenB_feesDisabled() public {
        _initializeCamelotExtremeUnbalancedPools();
        _testSwapDepositWithFeeCamelot(camelotExtremeUnbalancedPair, camelotExtremeTokenB, camelotExtremeTokenA, false);
    }

    // Fees enabled variants
    function test_quoteSwapDepositWithFee_Camelot_balancedPool_swapsTokenA_feesEnabled() public {
        _initializeCamelotBalancedPools();
        _testSwapDepositWithFeeCamelot(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB, true);
    }

    function test_quoteSwapDepositWithFee_Camelot_balancedPool_swapsTokenB_feesEnabled() public {
        _initializeCamelotBalancedPools();
        _testSwapDepositWithFeeCamelot(camelotBalancedPair, camelotBalancedTokenB, camelotBalancedTokenA, true);
    }

    function test_quoteSwapDepositWithFee_Camelot_unbalancedPool_swapsTokenA_feesEnabled() public {
        _initializeCamelotUnbalancedPools();
        _testSwapDepositWithFeeCamelot(camelotUnbalancedPair, camelotUnbalancedTokenA, camelotUnbalancedTokenB, true);
    }

    function test_quoteSwapDepositWithFee_Camelot_unbalancedPool_swapsTokenB_feesEnabled() public {
        _initializeCamelotUnbalancedPools();
        _testSwapDepositWithFeeCamelot(camelotUnbalancedPair, camelotUnbalancedTokenB, camelotUnbalancedTokenA, true);
    }

    function test_quoteSwapDepositWithFee_Camelot_extremeUnbalancedPool_swapsTokenA_feesEnabled() public {
        _initializeCamelotExtremeUnbalancedPools();
        _testSwapDepositWithFeeCamelot(camelotExtremeUnbalancedPair, camelotExtremeTokenA, camelotExtremeTokenB, true);
    }

    function test_quoteSwapDepositWithFee_Camelot_extremeUnbalancedPool_swapsTokenB_feesEnabled() public {
        _initializeCamelotExtremeUnbalancedPools();
        _testSwapDepositWithFeeCamelot(camelotExtremeUnbalancedPair, camelotExtremeTokenB, camelotExtremeTokenA, true);
    }
}
