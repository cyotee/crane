// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Aerodrome.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/Pool.sol";

contract ConstProdUtils_quoteZapInLP_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    using ConstProdUtils for uint256;

    function setUp() public override {
        TestBase_ConstProdUtils_Aerodrome.setUp();
    }

    function test_quoteZapInLP_Aerodrome_balanced_simple() public {
        _initializeAerodromeBalancedPools();

        Pool pair = aeroBalancedPool;
        (uint256 r0, uint256 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroBalancedTokenA), pair.token0(), r0, r1);

        uint256 amountIn = 1000e18;

        ConstProdUtils.SwapDepositArgs memory args;
        args.amountIn = amountIn;
        args.lpTotalSupply = totalSupply;
        args.reserveIn = reserveA;
        args.reserveOut = reserveB;
        // Aerodrome per-pair fee
        args.feePercent = factory.getFee(address(pair), false);
        args.kLast = 0;
        args.ownerFeeShare = 0;
        args.feeOn = false;

        uint256 quotedLP = ConstProdUtils._quoteSwapDepositWithFee(args);
        assertTrue(quotedLP > 0, "quotedLP > 0");
    }

    function test_quoteZapInLP_Aerodrome_unbalanced_simple() public {
        _initializeAerodromeUnbalancedPools();

        Pool pair = aeroUnbalancedPool;
        (uint256 r0, uint256 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroUnbalancedTokenA), pair.token0(), r0, r1);

        uint256 amountIn = 1000e18;
        ConstProdUtils.SwapDepositArgs memory args;
        args.amountIn = amountIn;
        args.lpTotalSupply = totalSupply;
        args.reserveIn = reserveA;
        args.reserveOut = reserveB;
        args.feePercent = factory.getFee(address(pair), false);
        args.kLast = 0;
        args.ownerFeeShare = 0;
        args.feeOn = false;

        uint256 quotedLP = ConstProdUtils._quoteSwapDepositWithFee(args);
        assertTrue(quotedLP > 0, "quotedLP > 0");
    }

    function test_quoteZapInLP_Aerodrome_extreme_unbalanced_simple() public {
        _initializeAerodromeExtremeUnbalancedPools();
        Pool pair = aeroExtremeUnbalancedPool;
        (uint256 r0, uint256 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroExtremeTokenA), pair.token0(), r0, r1);

        uint256 amountIn = 1000e18;
        ConstProdUtils.SwapDepositArgs memory args;
        args.amountIn = amountIn;
        args.lpTotalSupply = totalSupply;
        args.reserveIn = reserveA;
        args.reserveOut = reserveB;
        args.feePercent = factory.getFee(address(pair), false);
        args.kLast = 0;
        args.ownerFeeShare = 0;
        args.feeOn = false;

        uint256 quotedLP = ConstProdUtils._quoteSwapDepositWithFee(args);
        assertTrue(quotedLP > 0, "quotedLP > 0");
    }
}
