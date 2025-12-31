// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Uniswap.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_calculateProtocolFee_Uniswap_Test is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
    }

    function test_calculateProtocolFee_ExecutionValidation_BalancedPool() public {
        _initializeUniswapBalancedPools();
        _testProtocolFeeExecutionValidation(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB);
    }

    function test_calculateProtocolFee_ExecutionValidation_UnbalancedPool() public {
        _initializeUniswapUnbalancedPools();
        _testProtocolFeeExecutionValidation(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB);
    }

    function test_calculateProtocolFee_ExecutionValidation_ExtremeUnbalancedPool() public {
        _initializeUniswapExtremeUnbalancedPools();
        _testProtocolFeeExecutionValidation(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB);
    }

    function _testProtocolFeeExecutionValidation(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB
    ) internal {
        address protocolFeeRecipient = makeAddr("protocolFeeRecipient");

        // Enable protocol fees
        vm.prank(uniswapV2FeeToSetter);
        uniswapV2Factory.setFeeTo(protocolFeeRecipient);

        uint256 initialK = pair.kLast();
        uint256 initialTotalSupply = pair.totalSupply();

        _generateTradingActivity(pair, tokenA, tokenB);

        (uint112 newReserveA, uint112 newReserveB,) = pair.getReserves();
        uint256 newK = uint256(newReserveA) * uint256(newReserveB);

        uint256 expectedProtocolFee = ConstProdUtils._calculateProtocolFee(initialTotalSupply, newK, initialK, 16667);

        uint256 ourLpBalance = pair.balanceOf(address(this));
        uint256 lpToBurn = ourLpBalance / 2;

        pair.transfer(address(pair), lpToBurn);
        pair.burn(address(this));

        uint256 actualProtocolFee = pair.balanceOf(protocolFeeRecipient);
        assertEq(actualProtocolFee, expectedProtocolFee, "Protocol fee calculation mismatch");
        assertTrue(newK > initialK, "K should have grown from trading activity");
    }

    function _generateTradingActivity(
        IUniswapV2Pair pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB
    ) internal {
        uint256 swapAmount = 100e18;

        tokenA.mint(address(this), swapAmount);
        tokenA.approve(address(uniswapV2Router), swapAmount);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uniswapV2Router.swapExactTokensForTokens(swapAmount, 0, path, address(this), block.timestamp);

        uint256 tokenBBalance = tokenB.balanceOf(address(this));
        tokenB.approve(address(uniswapV2Router), tokenBBalance);

        path[0] = address(tokenB);
        path[1] = address(tokenA);

        uniswapV2Router.swapExactTokensForTokens(tokenBBalance, 0, path, address(this), block.timestamp);
    }
}
