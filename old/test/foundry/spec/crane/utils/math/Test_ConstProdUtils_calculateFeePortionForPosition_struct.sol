// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestBase_ConstProdUtils.sol";
import "../../../../../../contracts/crane/utils/math/ConstProdUtils.sol";

contract Test_ConstProdUtils_calculateFeePortionForPosition_struct is TestBase_ConstProdUtils {
    using ConstProdUtils for uint256;

    struct FeeCalculationData {
        uint256 ownedLP;
        uint256 initialPositionA;
        uint256 initialPositionB;
        uint256 initialTokenABalance;
        uint256 initialTokenBBalance;
        uint256 initialReserveA;
        uint256 initialReserveB;
        uint256 initialTotalSupply;
        uint256 initialK;
        uint256 finalReserveA;
        uint256 finalReserveB;
        uint256 finalTotalSupply;
        uint256 withdrawnA;
        uint256 withdrawnB;
        uint256 finalTokenABalance;
        uint256 finalTokenBBalance;
        uint256 actualAccumulatedFeeA;
        uint256 actualAccumulatedFeeB;
        uint256 calculatedFeeA;
        uint256 calculatedFeeB;
    }

    function test_calculateFeePortionForPosition_Camelot_executionValidation() public {
        FeeCalculationData memory data;

        // Record initial state before any trades
        (data.initialReserveA, data.initialReserveB,,) = camelotBalancedPair.getReserves();
        data.initialTotalSupply = camelotBalancedPair.totalSupply();
        data.initialK = data.initialReserveA * data.initialReserveB;

        // Simulate a position holder who owned LP tokens at the initial state
        data.ownedLP = data.initialTotalSupply / 10; // Own 10% of initial total supply
        data.initialPositionA = (data.ownedLP * data.initialReserveA) / data.initialTotalSupply;
        data.initialPositionB = (data.ownedLP * data.initialReserveB) / data.initialTotalSupply;

        // Execute trades to generate fees and grow the pool
        _executeCamelotTradesToGenerateFees();

        // Record final state after trades and fee accumulation
        (data.finalReserveA, data.finalReserveB,,) = camelotBalancedPair.getReserves();
        data.finalTotalSupply = camelotBalancedPair.totalSupply();

        // Verify that fees were actually generated (K should have grown)
        assertGt(
            data.finalReserveA * data.finalReserveB, data.initialK, "Pool K should have grown due to fee accumulation"
        );

        // Test the function with real fee accumulation
        (data.calculatedFeeA, data.calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            data.ownedLP,
            data.initialPositionA,
            data.initialPositionB,
            data.finalReserveA,
            data.finalReserveB,
            data.finalTotalSupply
        );

        // Calculate what the LP position should actually claim
        uint256 claimableA = (data.ownedLP * data.finalReserveA) / data.finalTotalSupply;
        uint256 claimableB = (data.ownedLP * data.finalReserveB) / data.finalTotalSupply;

        // Calculate what the LP position would be worth without fees (based on initial position and current price ratio)
        uint256 tempA = (data.initialPositionA * data.initialPositionB * data.finalReserveA) / data.finalReserveB;
        uint256 noFeeA = Math.sqrt(tempA);
        uint256 tempB = (data.initialPositionA * data.initialPositionB * data.finalReserveB) / data.finalReserveA;
        uint256 noFeeB = Math.sqrt(tempB);

        // Expected fees are the difference between claimable and no-fee amounts
        uint256 expectedFeeA = claimableA > noFeeA ? claimableA - noFeeA : 0;
        uint256 expectedFeeB = claimableB > noFeeB ? claimableB - noFeeB : 0;

        // Debug logging
        console.log("=== CAMELOT FEE CALCULATION DEBUG ===");
        console.log("Initial Position A:", data.initialPositionA);
        console.log("Initial Position B:", data.initialPositionB);
        console.log("Final Reserve A:", data.finalReserveA);
        console.log("Final Reserve B:", data.finalReserveB);
        console.log("Final Total Supply:", data.finalTotalSupply);
        console.log("Claimable A:", claimableA);
        console.log("Claimable B:", claimableB);
        console.log("No Fee A:", noFeeA);
        console.log("No Fee B:", noFeeB);
        console.log("Expected Fee A:", expectedFeeA);
        console.log("Expected Fee B:", expectedFeeB);
        console.log("Calculated Fee A:", data.calculatedFeeA);
        console.log("Calculated Fee B:", data.calculatedFeeB);
        console.log("=== END DEBUG ===");

        // Validate exact equality
        assertEq(data.calculatedFeeA, expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(data.calculatedFeeB, expectedFeeB, "Calculated fee B should equal expected fee B");
    }

    function test_calculateFeePortionForPosition_Uniswap_executionValidation() public {
        FeeCalculationData memory data;

        // Record initial state before any trades
        (data.initialReserveA, data.initialReserveB,) = uniswapBalancedPair.getReserves();
        data.initialTotalSupply = uniswapBalancedPair.totalSupply();
        data.initialK = data.initialReserveA * data.initialReserveB;

        // Simulate a position holder who owned LP tokens at the initial state
        data.ownedLP = data.initialTotalSupply / 10; // Own 10% of initial total supply
        data.initialPositionA = (data.ownedLP * data.initialReserveA) / data.initialTotalSupply;
        data.initialPositionB = (data.ownedLP * data.initialReserveB) / data.initialTotalSupply;

        // Execute trades to generate fees and grow the pool
        _executeUniswapTradesToGenerateFees();

        // Record final state after trades and fee accumulation
        (data.finalReserveA, data.finalReserveB,) = uniswapBalancedPair.getReserves();
        data.finalTotalSupply = uniswapBalancedPair.totalSupply();

        // Verify that fees were actually generated (K should have grown)
        assertGt(
            data.finalReserveA * data.finalReserveB, data.initialK, "Pool K should have grown due to fee accumulation"
        );

        // Test the function with real fee accumulation
        (data.calculatedFeeA, data.calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            data.ownedLP,
            data.initialPositionA,
            data.initialPositionB,
            data.finalReserveA,
            data.finalReserveB,
            data.finalTotalSupply
        );

        // Calculate what the LP position should actually claim
        uint256 claimableA = (data.ownedLP * data.finalReserveA) / data.finalTotalSupply;
        uint256 claimableB = (data.ownedLP * data.finalReserveB) / data.finalTotalSupply;

        // Calculate what the LP position would be worth without fees (based on initial position and current price ratio)
        uint256 tempA = (data.initialPositionA * data.initialPositionB * data.finalReserveA) / data.finalReserveB;
        uint256 noFeeA = Math.sqrt(tempA);
        uint256 tempB = (data.initialPositionA * data.initialPositionB * data.finalReserveB) / data.finalReserveA;
        uint256 noFeeB = Math.sqrt(tempB);

        // Expected fees are the difference between claimable and no-fee amounts
        uint256 expectedFeeA = claimableA > noFeeA ? claimableA - noFeeA : 0;
        uint256 expectedFeeB = claimableB > noFeeB ? claimableB - noFeeB : 0;

        // Debug logging
        console.log("=== UNISWAP FEE CALCULATION DEBUG ===");
        console.log("Initial Position A:", data.initialPositionA);
        console.log("Initial Position B:", data.initialPositionB);
        console.log("Final Reserve A:", data.finalReserveA);
        console.log("Final Reserve B:", data.finalReserveB);
        console.log("Final Total Supply:", data.finalTotalSupply);
        console.log("Claimable A:", claimableA);
        console.log("Claimable B:", claimableB);
        console.log("No Fee A:", noFeeA);
        console.log("No Fee B:", noFeeB);
        console.log("Expected Fee A:", expectedFeeA);
        console.log("Expected Fee B:", expectedFeeB);
        console.log("Calculated Fee A:", data.calculatedFeeA);
        console.log("Calculated Fee B:", data.calculatedFeeB);
        console.log("=== END DEBUG ===");

        // Validate exact equality
        assertEq(data.calculatedFeeA, expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(data.calculatedFeeB, expectedFeeB, "Calculated fee B should equal expected fee B");
    }

    function _executeCamelotTradesToGenerateFees() internal {
        // Execute several trades to generate fees and grow the Camelot pool
        // Trade 1: Swap TokenA for TokenB
        uint256 swapAmountA = 100e18; // 100 tokens
        camelotBalancedTokenA.mint(address(this), swapAmountA);
        camelotBalancedTokenA.approve(address(camV2Router()), swapAmountA);

        address[] memory path = new address[](2);
        path[0] = address(camelotBalancedTokenA);
        path[1] = address(camelotBalancedTokenB);

        camV2Router()
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmountA,
                0, // Accept any amount of output tokens
                path,
                address(this),
                address(0), // No referrer
                block.timestamp + 300
            );

        // Trade 2: Swap TokenB for TokenA
        uint256 balanceB = camelotBalancedTokenB.balanceOf(address(this));
        if (balanceB > 0) {
            camelotBalancedTokenB.approve(address(camV2Router()), balanceB);

            address[] memory pathReverse = new address[](2);
            pathReverse[0] = address(camelotBalancedTokenB);
            pathReverse[1] = address(camelotBalancedTokenA);

            camV2Router()
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    balanceB,
                    0, // Accept any amount of output tokens
                    pathReverse,
                    address(this),
                    address(0), // No referrer
                    block.timestamp + 300
                );
        }

        // Trade 3: Another swap to generate more fees
        uint256 balanceA = camelotBalancedTokenA.balanceOf(address(this));
        if (balanceA > 0) {
            camelotBalancedTokenA.approve(address(camV2Router()), balanceA);
            camV2Router()
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    balanceA,
                    0, // Accept any amount of output tokens
                    path,
                    address(this),
                    address(0), // No referrer
                    block.timestamp + 300
                );
        }
    }

    function _executeUniswapTradesToGenerateFees() internal {
        // Execute several trades to generate fees and grow the Uniswap pool
        // Trade 1: Swap TokenA for TokenB
        uint256 swapAmountA = 100e18; // 100 tokens
        uniswapBalancedTokenA.mint(address(this), swapAmountA);
        uniswapBalancedTokenA.approve(address(uniswapV2Router()), swapAmountA);

        address[] memory path = new address[](2);
        path[0] = address(uniswapBalancedTokenA);
        path[1] = address(uniswapBalancedTokenB);

        uniswapV2Router()
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmountA,
                0, // Accept any amount of output tokens
                path,
                address(this),
                block.timestamp + 300
            );

        // Trade 2: Swap TokenB for TokenA
        uint256 balanceB = uniswapBalancedTokenB.balanceOf(address(this));
        if (balanceB > 0) {
            uniswapBalancedTokenB.approve(address(uniswapV2Router()), balanceB);

            address[] memory pathReverse = new address[](2);
            pathReverse[0] = address(uniswapBalancedTokenB);
            pathReverse[1] = address(uniswapBalancedTokenA);

            uniswapV2Router()
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    balanceB,
                    0, // Accept any amount of output tokens
                    pathReverse,
                    address(this),
                    block.timestamp + 300
                );
        }

        // Trade 3: Another swap to generate more fees
        uint256 balanceA = uniswapBalancedTokenA.balanceOf(address(this));
        if (balanceA > 0) {
            uniswapBalancedTokenA.approve(address(uniswapV2Router()), balanceA);
            uniswapV2Router()
                .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    balanceA,
                    0, // Accept any amount of output tokens
                    path,
                    address(this),
                    block.timestamp + 300
                );
        }
    }
}
