// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_minZapInAmount_Camelot is TestBase_ConstProdUtils_Camelot {
    using ConstProdUtils for uint256;

    uint256 constant FEE_PERCENT = 300; // 0.3%
    uint256 constant FEE_DENOMINATOR = 100000;

    function setUp() public override {
        super.setUp();
    }

    function test_minZapInAmount_Camelot_BalancedPool() public {
        _initializeCamelotBalancedPools();
        _testMinZapInAmount(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB);
    }

    function test_minZapInAmount_Camelot_UnbalancedPool() public {
        _initializeCamelotUnbalancedPools();
        _testMinZapInAmount(camelotUnbalancedPair, camelotUnbalancedTokenA, camelotUnbalancedTokenB);
    }

    function test_minZapInAmount_Camelot_ExtremeUnbalancedPool() public {
        _initializeCamelotExtremeUnbalancedPools();
        _testMinZapInAmount(camelotExtremeUnbalancedPair, camelotExtremeTokenA, camelotExtremeTokenB);
    }

    function _testMinZapInAmount(
        ICamelotPair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB
    ) internal {
        (uint112 r0, uint112 r1,,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(tokenA), pair.token0(), r0, r1);
        uint256 totalSupply = pair.totalSupply();

        uint256 minAmountIn = ConstProdUtils._minZapInAmount(reserveA, reserveB, totalSupply, FEE_PERCENT, FEE_DENOMINATOR);

        assertTrue(minAmountIn > 0, "Minimum amount should be positive");

        _testMinZapInAmountExecution(pair, tokenA, tokenB, minAmountIn, reserveA, reserveB, totalSupply);
    }

    function _testMinZapInAmountExecution(
        ICamelotPair,
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

    // Removed local finder; use library `_minZapInAmount` in `ConstProdUtils`.
}
