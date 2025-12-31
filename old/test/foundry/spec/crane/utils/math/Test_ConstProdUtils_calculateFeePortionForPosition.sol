// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestBase_ConstProdUtils.sol";
import "../../../../../../contracts/crane/utils/math/ConstProdUtils.sol";
import "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import "contracts/crane/interfaces/IERC20MintBurn.sol";

contract Test_ConstProdUtils_calculateFeePortionForPosition is TestBase_ConstProdUtils {
    using ConstProdUtils for uint256;

    struct Calc {
        uint256 claimableA;
        uint256 claimableB;
        uint256 tempA;
        uint256 tempB;
        uint256 noFeeA;
        uint256 noFeeB;
        uint256 expectedFeeA;
        uint256 expectedFeeB;
    }

    function _executeCamelotTradesToGenerateFees(IERC20MintBurn tokenA, IERC20MintBurn tokenB) internal {
        // Execute several trades to generate fees and grow the Camelot pool
        // Trade 1: Swap TokenA for TokenB
        uint256 swapAmountA = 100e18; // 100 tokens
        tokenA.mint(address(this), swapAmountA);
        tokenA.approve(address(camV2Router()), swapAmountA);

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

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
        uint256 balanceB = tokenB.balanceOf(address(this));
        if (balanceB > 0) {
            tokenB.approve(address(camV2Router()), balanceB);

            address[] memory pathReverse = new address[](2);
            pathReverse[0] = address(tokenB);
            pathReverse[1] = address(tokenA);

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
        uint256 balanceA = tokenA.balanceOf(address(this));
        if (balanceA > 0) {
            tokenA.approve(address(camV2Router()), balanceA);
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

    function _calculateAccumulatedFees(
        uint256 ownedLP,
        uint256 initialPositionA,
        uint256 initialPositionB,
        uint256 initialTokenABalance,
        uint256 initialTokenBBalance,
        address pairAddress,
        address tokenA,
        address tokenB
    ) internal returns (uint256 actualFeeA, uint256 actualFeeB) {
        // Actually withdraw our LP tokens to get real amounts
        IUniswapV2Pair(pairAddress).transfer(pairAddress, ownedLP);
        (uint256 withdrawnA, uint256 withdrawnB) = IUniswapV2Pair(pairAddress).burn(address(this));

        // Calculate accumulated fees using the correct formula
        actualFeeA = withdrawnA - initialPositionA
            - (IERC20MintBurn(tokenA).balanceOf(address(this)) - initialTokenABalance - withdrawnA);
        actualFeeB = withdrawnB - initialPositionB
            + (initialTokenBBalance - IERC20MintBurn(tokenB).balanceOf(address(this)) + withdrawnB);
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

    function test_calculateFeePortionForPosition_Camelot_balancedPool() public {
        // Record initial state before any trades
        (uint112 initialReserveA, uint112 initialReserveB,,) = camelotBalancedPair.getReserves();
        uint256 initialTotalSupply = camelotBalancedPair.totalSupply();
        console.log("balanced initialReserveA", uint256(initialReserveA));
        console.log("balanced initialReserveB", uint256(initialReserveB));
        console.log("balanced initialTotalSupply", initialTotalSupply);
        uint256 initialK = uint256(initialReserveA) * uint256(initialReserveB);
        console.log("balanced initialK", initialK);

        // Simulate a position holder who owned LP tokens at the initial state
        uint256 ownedLP = initialTotalSupply / 10; // Own 10% of initial total supply
        uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
        uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

        // Record initial token balances for fee calculation
        // uint256 initialTokenABalance = camelotBalancedTokenA.balanceOf(address(this));
        // uint256 initialTokenBBalance = camelotBalancedTokenB.balanceOf(address(this));

        // Execute trades to generate fees and grow the pool
        _executeCamelotTradesToGenerateFees(camelotBalancedTokenA, camelotBalancedTokenB);

        // Record final state after trades and fee accumulation
        (uint112 finalReserveA, uint112 finalReserveB,,) = camelotBalancedPair.getReserves();
        uint256 finalTotalSupply = camelotBalancedPair.totalSupply();

        // Verify that fees were actually generated (K should have grown)
        assertGt(
            uint256(finalReserveA) * uint256(finalReserveB),
            initialK,
            "Pool K should have grown due to fee accumulation"
        );

        // Calculate expected accumulated fees using claimable minus no-fee amounts (clamped to 0)
        Calc memory c;
        c.claimableA = (ownedLP * finalReserveA) / finalTotalSupply;
        c.claimableB = (ownedLP * finalReserveB) / finalTotalSupply;
        c.tempA = (initialPositionA * initialPositionB * finalReserveA) / finalReserveB;
        c.noFeeA = Math.sqrt(c.tempA);
        c.tempB = (initialPositionA * initialPositionB * finalReserveB) / finalReserveA;
        c.noFeeB = Math.sqrt(c.tempB);
        c.expectedFeeA = c.claimableA > c.noFeeA ? c.claimableA - c.noFeeA : 0;
        c.expectedFeeB = c.claimableB > c.noFeeB ? c.claimableB - c.noFeeB : 0;

        // Test the function with real fee accumulation
        (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialPositionA, initialPositionB, finalReserveA, finalReserveB, finalTotalSupply
        );

        // Validate exact equality
        assertEq(calculatedFeeA, c.expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(calculatedFeeB, c.expectedFeeB, "Calculated fee B should equal expected fee B");
    }

    function test_calculateFeePortionForPosition_Camelot_unbalancedPool() public {
        // Record initial state before any trades
        (uint112 initialReserveA, uint112 initialReserveB,,) = camelotUnbalancedPair.getReserves();
        uint256 initialTotalSupply = camelotUnbalancedPair.totalSupply();
        console.log("unbalanced initialReserveA", uint256(initialReserveA));
        console.log("unbalanced initialReserveB", uint256(initialReserveB));
        console.log("unbalanced initialTotalSupply", initialTotalSupply);
        uint256 initialK = uint256(initialReserveA) * uint256(initialReserveB);
        console.log("unbalanced initialK", initialK);

        // Simulate a position holder who owned LP tokens at the initial state
        uint256 ownedLP = initialTotalSupply / 10; // Own 10% of initial total supply
        uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
        uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

        // Record initial token balances for fee calculation
        // uint256 initialTokenABalance = camelotUnbalancedTokenA.balanceOf(address(this));
        // uint256 initialTokenBBalance = camelotUnbalancedTokenB.balanceOf(address(this));

        // Execute trades to generate fees and grow the pool
        _executeCamelotTradesToGenerateFees(camelotUnbalancedTokenA, camelotUnbalancedTokenB);

        // Record final state after trades and fee accumulation
        (uint112 finalReserveA, uint112 finalReserveB,,) = camelotUnbalancedPair.getReserves();
        uint256 finalTotalSupply = camelotUnbalancedPair.totalSupply();

        // Verify that fees were actually generated (K should have grown)
        assertGt(
            uint256(finalReserveA) * uint256(finalReserveB),
            initialK,
            "Pool K should have grown due to fee accumulation"
        );

        // Calculate expected accumulated fees using claimable minus no-fee amounts (clamped to 0)
        Calc memory c;
        c.claimableA = (ownedLP * finalReserveA) / finalTotalSupply;
        c.claimableB = (ownedLP * finalReserveB) / finalTotalSupply;
        c.tempA = (initialPositionA * initialPositionB * finalReserveA) / finalReserveB;
        c.noFeeA = Math.sqrt(c.tempA);
        c.tempB = (initialPositionA * initialPositionB * finalReserveB) / finalReserveA;
        c.noFeeB = Math.sqrt(c.tempB);
        c.expectedFeeA = c.claimableA > c.noFeeA ? c.claimableA - c.noFeeA : 0;
        c.expectedFeeB = c.claimableB > c.noFeeB ? c.claimableB - c.noFeeB : 0;

        // Test the function with real fee accumulation
        (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialPositionA, initialPositionB, finalReserveA, finalReserveB, finalTotalSupply
        );

        // Validate exact equality
        assertEq(calculatedFeeA, c.expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(calculatedFeeB, c.expectedFeeB, "Calculated fee B should equal expected fee B");
    }

    function test_calculateFeePortionForPosition_Camelot_extremeUnbalancedPool() public {
        // Record initial state before any trades
        (uint112 initialReserveA, uint112 initialReserveB,,) = camelotExtremeUnbalancedPair.getReserves();
        uint256 initialTotalSupply = camelotExtremeUnbalancedPair.totalSupply();
        console.log("extreme initialReserveA", uint256(initialReserveA));
        console.log("extreme initialReserveB", uint256(initialReserveB));
        console.log("extreme initialTotalSupply", initialTotalSupply);
        uint256 initialK = uint256(initialReserveA) * uint256(initialReserveB);
        console.log("extreme initialK", initialK);

        // Simulate a position holder who owned LP tokens at the initial state
        uint256 ownedLP = initialTotalSupply / 10; // Own 10% of initial total supply
        uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
        uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

        // Record initial token balances for fee calculation
        // uint256 initialTokenABalance = camelotExtremeTokenA.balanceOf(address(this));
        // uint256 initialTokenBBalance = camelotExtremeTokenB.balanceOf(address(this));

        // Execute trades to generate fees and grow the pool
        _executeCamelotTradesToGenerateFees(camelotExtremeTokenA, camelotExtremeTokenB);

        // Record final state after trades and fee accumulation
        (uint112 finalReserveA, uint112 finalReserveB,,) = camelotExtremeUnbalancedPair.getReserves();
        uint256 finalTotalSupply = camelotExtremeUnbalancedPair.totalSupply();

        // Verify that fees were actually generated (K should have grown)
        assertGt(
            uint256(finalReserveA) * uint256(finalReserveB),
            initialK,
            "Pool K should have grown due to fee accumulation"
        );

        // Calculate expected accumulated fees using claimable minus no-fee amounts (clamped to 0)
        Calc memory c;
        c.claimableA = (ownedLP * finalReserveA) / finalTotalSupply;
        c.claimableB = (ownedLP * finalReserveB) / finalTotalSupply;
        c.tempA = (initialPositionA * initialPositionB * finalReserveA) / finalReserveB;
        c.noFeeA = Math.sqrt(c.tempA);
        c.tempB = (initialPositionA * initialPositionB * finalReserveB) / finalReserveA;
        c.noFeeB = Math.sqrt(c.tempB);
        c.expectedFeeA = c.claimableA > c.noFeeA ? c.claimableA - c.noFeeA : 0;
        c.expectedFeeB = c.claimableB > c.noFeeB ? c.claimableB - c.noFeeB : 0;

        // Test the function with real fee accumulation
        (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialPositionA, initialPositionB, finalReserveA, finalReserveB, finalTotalSupply
        );

        // Validate exact equality
        assertEq(calculatedFeeA, c.expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(calculatedFeeB, c.expectedFeeB, "Calculated fee B should equal expected fee B");
    }

    // TODO Resolve Stack too deep error
    // function test_calculateFeePortionForPosition_Uniswap_balancedPool() public {
    //     // Record initial state before any trades
    //     (uint112 initialReserveA, uint112 initialReserveB, ) = uniswapBalancedPair.getReserves();
    //     uint256 initialTotalSupply = uniswapBalancedPair.totalSupply();
    //     uint256 initialK = initialReserveA * initialReserveB;

    //     // Simulate a position holder who owned LP tokens at the initial state
    //     uint256 ownedLP = initialTotalSupply / 10; // Own 10% of initial total supply
    //     uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
    //     uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

    //     // Record initial token balances for fee calculation
    //     uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
    //     uint256 initialTokenBBalance = uniswapBalancedTokenB.balanceOf(address(this));

    //     // Execute trades to generate fees and grow the pool
    //     _executeUniswapTradesToGenerateFees();

    //     // Record final state after trades and fee accumulation
    //     (uint112 finalReserveA, uint112 finalReserveB, ) = uniswapBalancedPair.getReserves();
    //     uint256 finalTotalSupply = uniswapBalancedPair.totalSupply();
    //     uint256 finalK = finalReserveA * finalReserveB;

    //     // Verify that fees were actually generated (K should have grown)
    //     assertGt(finalK, initialK, "Pool K should have grown due to fee accumulation");

    //     // Actually withdraw our LP tokens to get real amounts
    //     uniswapBalancedPair.transfer(address(uniswapBalancedPair), ownedLP);
    //     (uint256 withdrawnA, uint256 withdrawnB) = uniswapBalancedPair.burn(address(this));

    //     // Calculate actual accumulated fees from withdrawal
    //     uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
    //     uint256 finalTokenBBalance = uniswapBalancedTokenB.balanceOf(address(this));

    //     // Calculate user payments (trades we executed)
    //     uint256 userPaymentsInA = finalTokenABalance - initialTokenABalance - withdrawnA;
    //     uint256 userPaymentsOutB = initialTokenBBalance - finalTokenBBalance + withdrawnB;

    //     // Calculate accumulated fees using the correct formula
    //     uint256 actualAccumulatedFeeA = withdrawnA - initialPositionA - userPaymentsInA;
    //     uint256 actualAccumulatedFeeB = withdrawnB - initialPositionB + userPaymentsOutB;

    //     // Test the function with real fee accumulation
    //     (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
    //         ownedLP,
    //         initialPositionA,
    //         initialPositionB,
    //         finalReserveA,
    //         finalReserveB,
    //         finalTotalSupply
    //     );

    //     // Validate exact equality
    //     assertEq(calculatedFeeA, actualAccumulatedFeeA,
    //         "Calculated fee A should equal actual accumulated fee A");
    //     assertEq(calculatedFeeB, actualAccumulatedFeeB,
    //         "Calculated fee B should equal actual accumulated fee B");
    // }

    // TODO Resolve Stack too deep error
    // function test_calculateFeePortionForPosition_Uniswap_unbalancedPool() public {
    //     // Record initial state before any trades
    //     (uint112 initialReserveA, uint112 initialReserveB, ) = uniswapUnbalancedPair.getReserves();
    //     uint256 initialTotalSupply = uniswapUnbalancedPair.totalSupply();
    //     uint256 initialK = initialReserveA * initialReserveB;

    //     // Simulate a position holder who owned LP tokens at the initial state
    //     uint256 ownedLP = initialTotalSupply / 10; // Own 10% of initial total supply
    //     uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
    //     uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

    //     // Record initial token balances for fee calculation
    //     uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
    //     uint256 initialTokenBBalance = uniswapBalancedTokenB.balanceOf(address(this));

    //     // Execute trades to generate fees and grow the pool
    //     _executeUniswapTradesToGenerateFees();

    //     // Record final state after trades and fee accumulation
    //     (uint112 finalReserveA, uint112 finalReserveB, ) = uniswapUnbalancedPair.getReserves();
    //     uint256 finalTotalSupply = uniswapUnbalancedPair.totalSupply();
    //     uint256 finalK = finalReserveA * finalReserveB;

    //     // Verify that fees were actually generated (K should have grown)
    //     assertGt(finalK, initialK, "Pool K should have grown due to fee accumulation");

    //     // Actually withdraw our LP tokens to get real amounts
    //     uniswapUnbalancedPair.transfer(address(uniswapUnbalancedPair), ownedLP);
    //     (uint256 withdrawnA, uint256 withdrawnB) = uniswapUnbalancedPair.burn(address(this));

    //     // Calculate actual accumulated fees from withdrawal
    //     uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
    //     uint256 finalTokenBBalance = uniswapBalancedTokenB.balanceOf(address(this));

    //     // Calculate user payments (trades we executed)
    //     uint256 userPaymentsInA = finalTokenABalance - initialTokenABalance - withdrawnA;
    //     uint256 userPaymentsOutB = initialTokenBBalance - finalTokenBBalance + withdrawnB;

    //     // Calculate accumulated fees using the correct formula
    //     uint256 actualAccumulatedFeeA = withdrawnA - initialPositionA - userPaymentsInA;
    //     uint256 actualAccumulatedFeeB = withdrawnB - initialPositionB + userPaymentsOutB;

    //     // Test the function with real fee accumulation
    //     (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
    //         ownedLP,
    //         initialPositionA,
    //         initialPositionB,
    //         finalReserveA,
    //         finalReserveB,
    //         finalTotalSupply
    //     );

    //     // Validate exact equality
    //     assertEq(calculatedFeeA, actualAccumulatedFeeA,
    //         "Calculated fee A should equal actual accumulated fee A");
    //     assertEq(calculatedFeeB, actualAccumulatedFeeB,
    //         "Calculated fee B should equal actual accumulated fee B");
    // }

    // TODO Resolve Stack too deep error
    // function test_calculateFeePortionForPosition_Uniswap_extremeUnbalancedPool() public {
    //     // Record initial state before any trades
    //     (uint112 initialReserveA, uint112 initialReserveB, ) = uniswapExtremeUnbalancedPair.getReserves();
    //     uint256 initialTotalSupply = uniswapExtremeUnbalancedPair.totalSupply();
    //     uint256 initialK = initialReserveA * initialReserveB;

    //     // Simulate a position holder who owned LP tokens at the initial state
    //     uint256 ownedLP = initialTotalSupply / 10; // Own 10% of initial total supply
    //     uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
    //     uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

    //     // Record initial token balances for fee calculation
    //     uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
    //     uint256 initialTokenBBalance = uniswapBalancedTokenB.balanceOf(address(this));

    //     // Execute trades to generate fees and grow the pool
    //     _executeUniswapTradesToGenerateFees();

    //     // Record final state after trades and fee accumulation
    //     (uint112 finalReserveA, uint112 finalReserveB, ) = uniswapExtremeUnbalancedPair.getReserves();
    //     uint256 finalTotalSupply = uniswapExtremeUnbalancedPair.totalSupply();
    //     uint256 finalK = finalReserveA * finalReserveB;

    //     // Verify that fees were actually generated (K should have grown)
    //     assertGt(finalK, initialK, "Pool K should have grown due to fee accumulation");

    //     // Actually withdraw our LP tokens to get real amounts
    //     uniswapExtremeUnbalancedPair.transfer(address(uniswapExtremeUnbalancedPair), ownedLP);
    //     (uint256 withdrawnA, uint256 withdrawnB) = uniswapExtremeUnbalancedPair.burn(address(this));

    //     // Calculate actual accumulated fees from withdrawal
    //     uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
    //     uint256 finalTokenBBalance = uniswapBalancedTokenB.balanceOf(address(this));

    //     // Calculate user payments (trades we executed)
    //     uint256 userPaymentsInA = finalTokenABalance - initialTokenABalance - withdrawnA;
    //     uint256 userPaymentsOutB = initialTokenBBalance - finalTokenBBalance + withdrawnB;

    //     // Calculate accumulated fees using the correct formula
    //     uint256 actualAccumulatedFeeA = withdrawnA - initialPositionA - userPaymentsInA;
    //     uint256 actualAccumulatedFeeB = withdrawnB - initialPositionB + userPaymentsOutB;

    //     // Test the function with real fee accumulation
    //     (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
    //         ownedLP,
    //         initialPositionA,
    //         initialPositionB,
    //         finalReserveA,
    //         finalReserveB,
    //         finalTotalSupply
    //     );

    //     // Validate exact equality
    //     assertEq(calculatedFeeA, actualAccumulatedFeeA,
    //         "Calculated fee A should equal actual accumulated fee A");
    //     assertEq(calculatedFeeB, actualAccumulatedFeeB,
    //         "Calculated fee B should equal actual accumulated fee B");
    // }
}
