// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/Pool.sol";
import {IRouter} from "contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_swapDepositQuote_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    function setUp() public override {
        super.setUp();
    }

    function test_quoteSwapDepositWithFee_Aerodrome_balancedPool_basic() public {
        _initializeAerodromeBalancedPools();
        Pool pair = aeroBalancedPool;
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        (uint256 reserveA, uint256 feeA, uint256 reserveB, uint256 feeB) = ConstProdUtils._sortReserves(
            address(aeroBalancedTokenA), pair.token0(), reserve0, uint256(factory.getFee(address(pair), false)), reserve1, uint256(factory.getFee(address(pair), false))
        );

        uint256 lpTotalSupply = pair.totalSupply();
        uint256 amountIn = 1e18;

        uint256 expectedLp = ConstProdUtils._quoteSwapDepositWithFee(
            amountIn, lpTotalSupply, reserveA, reserveB, feeA, 0, 0, false
        );

        assertGt(expectedLp, 0, "Expected LP quote should be greater than 0");
    }

    function test_swapDepositQuote_Aerodrome_balancedPool() public {
        _initializeAerodromeBalancedPools();

        Pool pair = aeroBalancedPool;
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 amountIn = 1000e18;
        uint256 lpTotalSupply = pair.totalSupply();

        (uint256 reserveA, uint256 tokenAFee, uint256 reserveB, uint256 tokenBFee) = ConstProdUtils._sortReserves(
            address(aeroBalancedTokenA), pair.token0(), reserve0, uint256(factory.getFee(address(pair), false)), reserve1, uint256(factory.getFee(address(pair), false))
        );

        uint256 feePercent = tokenAFee;

        uint256 ownerFeeShare = 0;
        uint256 kLast = 0;
        uint256 expectedLPTokens = ConstProdUtils._quoteSwapDepositWithFee(
            amountIn,
            lpTotalSupply,
            reserveA,
            reserveB,
            feePercent,
            kLast,
            ownerFeeShare,
            false
        );

        uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent);
        assertGt(expectedLPTokens, 0, "expectedLPTokens > 0");
        assertGt(swapAmount, 0, "swapAmount > 0");
    }
}
