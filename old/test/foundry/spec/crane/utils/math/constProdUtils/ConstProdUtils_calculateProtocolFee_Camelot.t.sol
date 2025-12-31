// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Camelot.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_calculateProtocolFee_Camelot_Test is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        super.setUp();
    }

    function test_calculateProtocolFee_ExecutionValidation_BalancedPool() public {
        _initializeCamelotBalancedPools();
        _testProtocolFeeExecutionValidation(camelotBalancedPair, camelotBalancedTokenA, camelotBalancedTokenB);
    }

    function test_calculateProtocolFee_ExecutionValidation_UnbalancedPool() public {
        _initializeCamelotUnbalancedPools();
        _testProtocolFeeExecutionValidation(camelotUnbalancedPair, camelotUnbalancedTokenA, camelotUnbalancedTokenB);
    }

    function test_calculateProtocolFee_ExecutionValidation_ExtremeUnbalancedPool() public {
        _initializeCamelotExtremeUnbalancedPools();
        _testProtocolFeeExecutionValidation(camelotExtremeUnbalancedPair, camelotExtremeTokenA, camelotExtremeTokenB);
    }

    function _testProtocolFeeExecutionValidation(
        ICamelotPair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB
    ) internal {
        address feeTo = camelotV2FeeToSetter;
        // Protocol fees are enabled in the TestBase and feeTo is the factory's fee recipient

        uint256 initialK = pair.kLast();
        uint256 initialTotalSupply = pair.totalSupply();

        _generateTradingActivity(pair, tokenA, tokenB);

        (uint112 newReserveA, uint112 newReserveB, ,) = pair.getReserves();
        uint256 newK = uint256(newReserveA) * uint256(newReserveB);

        (uint256 ownerFeeShare, ) = camelotV2Factory.feeInfo();
        uint256 expectedProtocolFee = ConstProdUtils._calculateProtocolFee(initialTotalSupply, newK, initialK, ownerFeeShare);

        uint256 ourLpBalance = pair.balanceOf(address(this));
        uint256 lpToBurn = ourLpBalance / 2;

        pair.transfer(address(pair), lpToBurn);
        pair.burn(address(this));

        uint256 actualProtocolFee = pair.balanceOf(feeTo);
        assertEq(actualProtocolFee, expectedProtocolFee, "Protocol fee calculation mismatch");
        assertTrue(newK > initialK, "K should have grown from trading activity");
    }

    function _generateTradingActivity(
        ICamelotPair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB
    ) internal {
        uint256 swapAmount = 100e18;

        tokenA.mint(address(this), swapAmount);
        tokenA.approve(address(camelotV2Router), swapAmount);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmount, 0, path, address(this), address(0), block.timestamp);

        uint256 tokenBBalance = tokenB.balanceOf(address(this));
        tokenB.approve(address(camelotV2Router), tokenBBalance);

        path[0] = address(tokenB);
        path[1] = address(tokenA);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenBBalance, 0, path, address(this), address(0), block.timestamp);
    }
}
