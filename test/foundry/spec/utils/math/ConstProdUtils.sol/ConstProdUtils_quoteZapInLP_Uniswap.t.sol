// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";

contract ConstProdUtils_quoteZapInLP_Uniswap is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        super.setUp();
    }


    function test_quoteZapInLP_Uniswap_balanced_simple() public {
        _initializeUniswapBalancedPools();

        IUniswapV2Pair pair = uniswapBalancedPair;
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenA), pair.token0(), r0, r1);

        uint256 amountIn = 1000e18;

        ConstProdUtils.SwapDepositArgs memory args;
        args.amountIn = amountIn;
        args.lpTotalSupply = totalSupply;
        args.reserveIn = reserveA;
        args.reserveOut = reserveB;
        args.feePercent = 300; // 0.3%
        args.kLast = pair.kLast();
        args.ownerFeeShare = 16666;
        args.feeOn = false;

        uint256 quotedLP = ConstProdUtils._quoteSwapDepositWithFee(args);
        assertTrue(quotedLP > 0, "quotedLP > 0");
    }

    function test_quoteZapInLP_Uniswap_unbalanced_simple() public {
        _initializeUniswapUnbalancedPools();
        IUniswapV2Pair pair = uniswapUnbalancedPair;
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenA), pair.token0(), r0, r1);

        uint256 amountIn = 1000e18;
        ConstProdUtils.SwapDepositArgs memory args;
        args.amountIn = amountIn;
        args.lpTotalSupply = totalSupply;
        args.reserveIn = reserveA;
        args.reserveOut = reserveB;
        args.feePercent = 300;
        args.kLast = pair.kLast();
        args.ownerFeeShare = 16666;
        args.feeOn = false;

        uint256 quotedLP = ConstProdUtils._quoteSwapDepositWithFee(args);
        assertTrue(quotedLP > 0, "quotedLP > 0");
    }

    function test_quoteZapInLP_Uniswap_extreme_unbalanced_simple() public {
        _initializeUniswapExtremeUnbalancedPools();
        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenA), pair.token0(), r0, r1);

        uint256 amountIn = 1000e18;
        ConstProdUtils.SwapDepositArgs memory args;
        args.amountIn = amountIn;
        args.lpTotalSupply = totalSupply;
        args.reserveIn = reserveA;
        args.reserveOut = reserveB;
        args.feePercent = 300;
        args.kLast = pair.kLast();
        args.ownerFeeShare = 16666;
        args.feeOn = false;

        uint256 quotedLP = ConstProdUtils._quoteSwapDepositWithFee(args);
        assertTrue(quotedLP > 0, "quotedLP > 0");
    }
}
