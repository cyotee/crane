// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";

contract ConstProdUtils_quoteZapOutLP_Camelot is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        super.setUp();
    }

    function test_quoteZapOutLP_Camelot_balancedPool_simple() public {
        _initializeCamelotBalancedPools();

        ICamelotPair pair = camelotBalancedPair;
        (uint112 r0, uint112 r1, uint16 f0, uint16 f1) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(camelotBalancedTokenA), pair.token0(), r0, r1);

        uint256 desiredOut = reserveA / 10; // 10%

        (uint256 ownerFeeShare, ) = camelotV2Factory.feeInfo();
        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveA,
            reserveOther: reserveB,
            feePercent: uint256(pair.token0() == address(camelotBalancedTokenA) ? f0 : f1),
            feeDenominator: 100000,
            kLast: pair.kLast(),
            ownerFeeShare: ownerFeeShare,
            feeOn: false,
            protocolFeeDenominator: 100000
        });

        uint256 quoted = ConstProdUtils._quoteZapOutToTargetWithFee(args);
        assertTrue(quoted > 0, "quoted > 0");
        assertTrue(quoted <= totalSupply, "quoted <= totalSupply");

        uint256 balBefore = camelotBalancedTokenA.balanceOf(address(this));
        pair.transfer(address(pair), quoted);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 saleAmount;
        if (address(camelotBalancedTokenA) == pair.token0()) {
            saleAmount = a1;
        } else {
            saleAmount = a0;
        }
        if (saleAmount > 0) {
            camelotBalancedTokenB.approve(address(camelotV2Router), saleAmount);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                saleAmount, 1, _buildPath(address(camelotBalancedTokenB), address(camelotBalancedTokenA)), address(this), address(0), block.timestamp
            );
        }
        uint256 balAfter = camelotBalancedTokenA.balanceOf(address(this));
        uint256 actualReceived = balAfter - balBefore;
        assertTrue(actualReceived >= desiredOut, "received >= desiredOut");
    }

    function test_quoteZapOutLP_Camelot_unbalancedPool_simple() public {
        _initializeCamelotUnbalancedPools();

        ICamelotPair pair = camelotUnbalancedPair;
        (uint112 r0, uint112 r1, uint16 f0, uint16 f1) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(camelotUnbalancedTokenA), pair.token0(), r0, r1);

        uint256 desiredOut = reserveA / 10; // 10%

        (uint256 ownerFeeShare, ) = camelotV2Factory.feeInfo();
        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveA,
            reserveOther: reserveB,
            feePercent: 500,
            feeDenominator: 100000,
            kLast: pair.kLast(),
            ownerFeeShare: ownerFeeShare,
            feeOn: false,
            protocolFeeDenominator: 100000
        });

        uint256 quoted = ConstProdUtils._quoteZapOutToTargetWithFee(args);
        assertTrue(quoted > 0, "quoted > 0");
        assertTrue(quoted <= totalSupply, "quoted <= totalSupply");

        uint256 balBefore = camelotUnbalancedTokenA.balanceOf(address(this));
        pair.transfer(address(pair), quoted);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 saleAmount;
        if (address(camelotUnbalancedTokenA) == pair.token0()) {
            saleAmount = a1;
        } else {
            saleAmount = a0;
        }
        if (saleAmount > 0) {
            camelotUnbalancedTokenB.approve(address(camelotV2Router), saleAmount);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                saleAmount, 1, _buildPath(address(camelotUnbalancedTokenB), address(camelotUnbalancedTokenA)), address(this), address(0), block.timestamp
            );
        }
        uint256 balAfter = camelotUnbalancedTokenA.balanceOf(address(this));
        uint256 actualReceived = balAfter - balBefore;
        assertTrue(actualReceived >= desiredOut, "received >= desiredOut");
    }

    function test_quoteZapOutLP_Camelot_extremeUnbalancedPool_simple() public {
        _initializeCamelotExtremeUnbalancedPools();

        ICamelotPair pair = camelotExtremeUnbalancedPair;
        (uint112 r0, uint112 r1, uint16 f0, uint16 f1) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(camelotExtremeTokenA), pair.token0(), r0, r1);

        uint256 desiredOut = reserveA / 10; // 10%

        (uint256 ownerFeeShare, ) = camelotV2Factory.feeInfo();
        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveA,
            reserveOther: reserveB,
            feePercent: 500,
            feeDenominator: 100000,
            kLast: pair.kLast(),
            ownerFeeShare: ownerFeeShare,
            feeOn: false,
            protocolFeeDenominator: 100000
        });

        uint256 quoted = ConstProdUtils._quoteZapOutToTargetWithFee(args);
        assertTrue(quoted > 0, "quoted > 0");
        assertTrue(quoted <= totalSupply, "quoted <= totalSupply");

        uint256 balBefore = camelotExtremeTokenA.balanceOf(address(this));
        pair.transfer(address(pair), quoted);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 saleAmount;
        if (address(camelotExtremeTokenA) == pair.token0()) {
            saleAmount = a1;
        } else {
            saleAmount = a0;
        }
        if (saleAmount > 0) {
            camelotExtremeTokenB.approve(address(camelotV2Router), saleAmount);
            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                saleAmount, 1, _buildPath(address(camelotExtremeTokenB), address(camelotExtremeTokenA)), address(this), address(0), block.timestamp
            );
        }
        uint256 balAfter = camelotExtremeTokenA.balanceOf(address(this));
        uint256 actualReceived = balAfter - balBefore;
        assertTrue(actualReceived >= desiredOut, "received >= desiredOut");
    }

    function _buildPath(address a, address b) internal pure returns (address[] memory path) {
        path = new address[](2);
        path[0] = a;
        path[1] = b;
    }
}
