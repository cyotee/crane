// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "contracts/protocols/dexes/camelot/v2/CamelotV2Service.sol";
import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Camelot.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";

contract ConstProdUtils_saleQuoteMin_Camelot is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        TestBase_ConstProdUtils_Camelot.setUp();
    }

    function test_saleQuoteMin_Camelot_BalancedPool() public {
        _initializeCamelotBalancedPools();
        _testSaleQuoteMin_Camelot(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB);
    }

    function test_saleQuoteMin_Camelot_UnbalancedPool() public {
        _initializeCamelotUnbalancedPools();
        _testSaleQuoteMin_Camelot(camelotUnbalancedPair, camelotUnbalancedTokenA, camelotUnbalancedTokenB);
    }

    function test_saleQuoteMin_Camelot_ExtremeUnbalancedPool() public {
        _initializeCamelotExtremeUnbalancedPools();
        _testSaleQuoteMin_Camelot(camelotExtremeUnbalancedPair, camelotExtremeTokenA, camelotExtremeTokenB);
    }

    function _testSaleQuoteMin_Camelot(
        ICamelotPair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB
    ) internal {
        (uint112 r0, uint112 r1, uint16 token0Fee, uint16 token1Fee) = pair.getReserves();
        (uint256 reserveIn, uint256 fee, uint256 reserveOut, ) = ConstProdUtils._sortReserves(
            address(tokenA), pair.token0(), r0, uint256(token0Fee), r1, uint256(token1Fee)
        );

        uint256 feeDenominator = 100_000;

        // Minimum input to receive at least 1 unit of output (Camelot uses feeDenominator)
        uint256 expectedMinInput = ConstProdUtils._purchaseQuote(1, reserveIn, reserveOut, fee, feeDenominator);

        tokenA.mint(address(this), expectedMinInput);

        uint256 actualOutput = CamelotV2Service._swap(
            camelotV2Router,
            pair,
            expectedMinInput,
            tokenA,
            tokenB,
            address(0)
        );

        assertGe(actualOutput, 1, "Should get at least 1 unit of output");

        console.log("Expected min input:", expectedMinInput);
        console.log("Actual output:", actualOutput);
    }
}
