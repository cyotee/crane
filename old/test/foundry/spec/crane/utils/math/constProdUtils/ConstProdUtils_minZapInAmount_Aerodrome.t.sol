// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Aerodrome.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/Pool.sol";

contract ConstProdUtils_minZapInAmount_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    using ConstProdUtils for uint256;

    uint256 constant FEE_PERCENT = 300; // 0.3%
    uint256 constant FEE_DENOMINATOR = 100000;

    function setUp() public override {
        super.setUp();
    }

    function test_minZapInAmount_Aerodrome_BalancedPool() public {
        _initializeAerodromeBalancedPools();
        _testMinZapInAmount(aeroBalancedPool, aeroBalancedTokenA, aeroBalancedTokenB);
    }

    function test_minZapInAmount_Aerodrome_UnbalancedPool() public {
        _initializeAerodromeUnbalancedPools();
        _testMinZapInAmount(aeroUnbalancedPool, aeroUnbalancedTokenA, aeroUnbalancedTokenB);
    }

    function test_minZapInAmount_Aerodrome_ExtremeUnbalancedPool() public {
        _initializeAerodromeExtremeUnbalancedPools();
        _testMinZapInAmount(aeroExtremeUnbalancedPool, aeroExtremeTokenA, aeroExtremeTokenB);
    }

    function _testMinZapInAmount(
        Pool pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB
    ) internal {
        (uint256 r0, uint256 r1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(tokenA), pair.token0(), r0, r1);
        uint256 totalSupply = pair.totalSupply();

        uint256 minAmountIn = ConstProdUtils._minZapInAmount(reserveA, reserveB, totalSupply, FEE_PERCENT, FEE_DENOMINATOR);

        assertTrue(minAmountIn > 0, "Minimum amount should be positive");

        _testMinZapInAmountExecution(pair, tokenA, tokenB, minAmountIn, reserveA, reserveB, totalSupply);
    }

    function _testMinZapInAmountExecution(
        Pool,
        ERC20PermitMintableStub,
        ERC20PermitMintableStub,
        uint256 minAmountIn,
        uint256 reserveA,
        uint256 reserveB,
        uint256
    ) internal {
        uint256 swapAmount = minAmountIn._swapDepositSaleAmt(reserveA, FEE_PERCENT);
        uint256 equivLiquidity = swapAmount._equivLiquidity(reserveA, reserveB);
        uint256 remainingAmount = minAmountIn - swapAmount;

        assertEq(swapAmount + remainingAmount, minAmountIn, "Swap amount + remaining should equal original input");
        assertTrue(equivLiquidity >= 1, "Equivalent liquidity should be positive");
        assertTrue(minAmountIn >= swapAmount, "Minimum amount should be at least the swap amount");
        assertTrue(remainingAmount > 0, "Remaining amount should be positive");
    }
}
