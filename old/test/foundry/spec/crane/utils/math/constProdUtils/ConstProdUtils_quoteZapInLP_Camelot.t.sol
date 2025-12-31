pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";

contract ConstProdUtils_quoteZapInLP_Camelot is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        super.setUp();
    }

    function test_quoteZapInLP_Camelot_balanced_simple() public {
        _initializeCamelotBalancedPools();

        ICamelotPair pair = camelotBalancedPair;
        (uint112 r0, uint112 r1, uint16 f0, uint16 f1) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 feeA, uint256 reserveB, uint256 feeB) = ConstProdUtils._sortReserves(address(camelotBalancedTokenA), pair.token0(), r0, f0, r1, f1);

        uint256 amountIn = 1000e18;

        ConstProdUtils.SwapDepositArgs memory args;
        args.amountIn = amountIn;
        args.lpTotalSupply = totalSupply;
        args.reserveIn = reserveA;
        args.reserveOut = reserveB;
        args.feePercent = feeA; // per-token fee from pair
        args.kLast = pair.kLast();
        (uint256 ownerFeeShare, ) = camelotV2Factory.feeInfo();
        args.ownerFeeShare = ownerFeeShare;
        args.feeOn = false;

        uint256 quotedLP = ConstProdUtils._quoteSwapDepositWithFee(args);
        assertTrue(quotedLP > 0, "quotedLP > 0");
    }

    function test_quoteZapInLP_Camelot_unbalanced_simple() public {
        _initializeCamelotUnbalancedPools();

        ICamelotPair pair = camelotUnbalancedPair;
        (uint112 r0, uint112 r1, uint16 f0, uint16 f1) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 feeA, uint256 reserveB, uint256 feeB) = ConstProdUtils._sortReserves(address(camelotUnbalancedTokenA), pair.token0(), r0, f0, r1, f1);

        uint256 amountIn = 1000e18;
        ConstProdUtils.SwapDepositArgs memory args;
        args.amountIn = amountIn;
        args.lpTotalSupply = totalSupply;
        args.reserveIn = reserveA;
        args.reserveOut = reserveB;
        args.feePercent = feeA;
        args.kLast = pair.kLast();
        (uint256 ownerFeeShare, ) = camelotV2Factory.feeInfo();
        args.ownerFeeShare = ownerFeeShare;
        args.feeOn = false;

        uint256 quotedLP = ConstProdUtils._quoteSwapDepositWithFee(args);
        assertTrue(quotedLP > 0, "quotedLP > 0");
    }

    function test_quoteZapInLP_Camelot_extreme_unbalanced_simple() public {
        _initializeCamelotExtremeUnbalancedPools();
        ICamelotPair pair = camelotExtremeUnbalancedPair;
        (uint112 r0, uint112 r1, uint16 f0, uint16 f1) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 feeA, uint256 reserveB, uint256 feeB) = ConstProdUtils._sortReserves(address(camelotExtremeTokenA), pair.token0(), r0, f0, r1, f1);

        uint256 amountIn = 1000e18;
        ConstProdUtils.SwapDepositArgs memory args;
        args.amountIn = amountIn;
        args.lpTotalSupply = totalSupply;
        args.reserveIn = reserveA;
        args.reserveOut = reserveB;
        args.feePercent = feeA;
        args.kLast = pair.kLast();
        (uint256 ownerFeeShare, ) = camelotV2Factory.feeInfo();
        args.ownerFeeShare = ownerFeeShare;
        args.feeOn = false;

        uint256 quotedLP = ConstProdUtils._quoteSwapDepositWithFee(args);
        assertTrue(quotedLP > 0, "quotedLP > 0");
    }
}
