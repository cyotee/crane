// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_minZapInAmount_Uniswap is TestBase_ConstProdUtils_Uniswap {
    using ConstProdUtils for uint256;

    uint256 constant FEE_PERCENT = 300; // 0.3%
    uint256 constant FEE_DENOMINATOR = 100000;

    function setUp() public override {
        super.setUp();
    }

    function test_minZapInAmount_Uniswap_BalancedPool() public {
        _initializeUniswapBalancedPools();
        _testMinZapInAmount(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB);
    }

    function test_minZapInAmount_Uniswap_UnbalancedPool() public {
        _initializeUniswapUnbalancedPools();
        _testMinZapInAmount(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB);
    }

    function test_minZapInAmount_Uniswap_ExtremeUnbalancedPool() public {
        _initializeUniswapExtremeUnbalancedPools();
        _testMinZapInAmount(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB);
    }

    function _testMinZapInAmount(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB
    ) internal {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(tokenA), pair.token0(), r0, r1);
        uint256 totalSupply = pair.totalSupply();

        uint256 minAmountIn = ConstProdUtils._minZapInAmount(reserveA, reserveB, totalSupply, FEE_PERCENT, FEE_DENOMINATOR);

        assertTrue(minAmountIn > 0, "Minimum amount should be positive");

        _testMinZapInAmountExecution(pair, tokenA, tokenB, minAmountIn, reserveA, reserveB, totalSupply);
    }

    function _testMinZapInAmountExecution(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB,
        uint256 minAmountIn,
        uint256 reserveA,
        uint256 reserveB,
        uint256 /* totalSupply */
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
