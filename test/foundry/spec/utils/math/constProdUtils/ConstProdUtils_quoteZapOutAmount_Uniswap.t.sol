// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";

contract ConstProdUtils_quoteZapOutAmount_Uniswap is TestBase_ConstProdUtils_Uniswap {
    using ConstProdUtils for uint256;

    uint256 constant FEE_PERCENT = 300; // 0.3%
    uint256 constant FEE_DENOMINATOR = 100000;

    function setUp() public override {
        super.setUp();
    }

    function test_quoteZapOutAmount_Uniswap_BalancedPool() public {
        _initializeUniswapBalancedPools();
        _testQuoteZapOutAmount(uniswapBalancedPair);
    }

    function test_quoteZapOutAmount_Uniswap_UnbalancedPool() public {
        _initializeUniswapUnbalancedPools();
        _testQuoteZapOutAmount(uniswapUnbalancedPair);
    }

    function test_quoteZapOutAmount_Uniswap_ExtremeUnbalancedPool() public {
        _initializeUniswapExtremeUnbalancedPools();
        _testQuoteZapOutAmount(uniswapExtremeUnbalancedPair);
    }

    function _testQuoteZapOutAmount(IUniswapV2Pair pair) internal {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(0), pair.token0(), r0, r1);
        uint256 totalSupply = pair.totalSupply();

        // Choose a reasonable desiredOut: small fraction of reserveA
        uint256 desiredOut = reserveA / 1000;

        uint256 lpNeeded = ConstProdUtils._quoteZapOutToTargetWithFee(
            desiredOut,
            totalSupply,
            reserveA,
            reserveB,
            FEE_PERCENT,
            FEE_DENOMINATOR,
            /*kLast*/ 0,
            /*ownerFeeShare*/ 0,
            /*feeOn*/ false
        );

        // Basic invariants
        assertTrue(lpNeeded <= totalSupply, "lpNeeded should not exceed total supply");
        // zero-case handled
        if (desiredOut > 0) {
            assertTrue(lpNeeded > 0, "lpNeeded should be positive for non-zero desiredOut");
        }
    }
}
