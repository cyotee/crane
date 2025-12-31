// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {IUniswapV2Pair} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IERC20MintBurn} from "contracts/crane/interfaces/IERC20MintBurn.sol";
import "forge-std/console.sol";

/**
 * @title Test_ConstProdUtils_calculateProtocolFee
 * @dev Comprehensive tests for _calculateProtocolFee() with execution validation
 */
contract Test_ConstProdUtils_calculateProtocolFee is TestBase_ConstProdUtils {
    using ConstProdUtils for uint256;

    function test_calculateProtocolFee_ExecutionValidation_BalancedPool() public {
        _testProtocolFeeExecutionValidation(uniswapBalancedPair, uniswapBalancedTokenA, uniswapBalancedTokenB);
    }

    function test_calculateProtocolFee_ExecutionValidation_UnbalancedPool() public {
        _testProtocolFeeExecutionValidation(uniswapUnbalancedPair, uniswapUnbalancedTokenA, uniswapUnbalancedTokenB);
    }

    function test_calculateProtocolFee_ExecutionValidation_ExtremeUnbalancedPool() public {
        _testProtocolFeeExecutionValidation(uniswapExtremeUnbalancedPair, uniswapExtremeTokenA, uniswapExtremeTokenB);
    }

    function _testProtocolFeeExecutionValidation(IUniswapV2Pair pair, IERC20MintBurn tokenA, IERC20MintBurn tokenB)
        internal
    {
        // Create a test address to receive protocol fees
        address protocolFeeRecipient = makeAddr("protocolFeeRecipient");

        // Enable protocol fees by setting feeTo address
        vm.prank(uniswapV2Factory().feeToSetter());
        uniswapV2Factory().setFeeTo(protocolFeeRecipient);

        // Get initial state
        // (uint112 reserveA, uint112 reserveB, ) = pair.getReserves();
        uint256 initialK = pair.kLast();
        uint256 initialTotalSupply = pair.totalSupply();

        // Generate trading activity to create K growth
        _generateTradingActivity(pair, tokenA, tokenB);

        // Get state after trading but before withdrawal
        (uint112 newReserveA, uint112 newReserveB,) = pair.getReserves();
        uint256 newK = uint256(newReserveA) * uint256(newReserveB);
        // uint256 newTotalSupply = pair.totalSupply();

        // Calculate expected protocol fee using our function
        uint256 expectedProtocolFee = ConstProdUtils._calculateProtocolFee(
            initialTotalSupply,
            newK,
            initialK,
            16667 // ownerFeeShare = 1/6
        );

        // Get our LP token balance and burn half of it
        uint256 ourLpBalance = pair.balanceOf(address(this));
        uint256 lpToBurn = ourLpBalance / 2;

        // Burn LP tokens to trigger protocol fee minting
        pair.transfer(address(pair), lpToBurn);
        pair.burn(address(this));

        // Check the actual protocol fee minted to the recipient
        uint256 actualProtocolFee = pair.balanceOf(protocolFeeRecipient);

        // Compare expected vs actual
        assertEq(actualProtocolFee, expectedProtocolFee, "Protocol fee calculation mismatch");

        // Verify K growth occurred
        assertTrue(newK > initialK, "K should have grown from trading activity");
    }

    function _generateTradingActivity(IUniswapV2Pair pair, IERC20MintBurn tokenA, IERC20MintBurn tokenB) internal {
        // Perform several swaps to generate trading activity and K growth
        uint256 swapAmount = 100e18;

        // Swap A for B
        tokenA.mint(address(this), swapAmount);
        tokenA.approve(address(uniswapV2Router()), swapAmount);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uniswapV2Router().swapExactTokensForTokens(swapAmount, 0, path, address(this), block.timestamp);

        // Swap B for A
        uint256 tokenBBalance = tokenB.balanceOf(address(this));
        tokenB.approve(address(uniswapV2Router()), tokenBBalance);

        path[0] = address(tokenB);
        path[1] = address(tokenA);

        uniswapV2Router().swapExactTokensForTokens(tokenBBalance, 0, path, address(this), block.timestamp);
    }
}
