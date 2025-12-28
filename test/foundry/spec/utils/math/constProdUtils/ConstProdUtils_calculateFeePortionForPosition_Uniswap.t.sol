// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {BetterMath as Math} from "@crane/contracts/utils/math/BetterMath.sol";
import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Uniswap.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_calculateFeePortionForPosition_Uniswap is TestBase_ConstProdUtils_Uniswap {
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

    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
    }

    function test_calculateFeePortionForPosition_Uniswap_balancedPool() public {
        _initializeUniswapBalancedPools();
        (uint112 initialReserveA, uint112 initialReserveB, ) = uniswapBalancedPair.getReserves();
        uint256 initialTotalSupply = uniswapBalancedPair.totalSupply();
        uint256 initialK = uint256(initialReserveA) * uint256(initialReserveB);

        uint256 ownedLP = initialTotalSupply / 10;
        uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
        uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

        _executeUniswapTradesToGenerateFees(uniswapBalancedTokenA, uniswapBalancedTokenB);

        (uint112 finalReserveA, uint112 finalReserveB, ) = uniswapBalancedPair.getReserves();
        uint256 finalTotalSupply = uniswapBalancedPair.totalSupply();

        assertGt(uint256(finalReserveA) * uint256(finalReserveB), initialK, "Pool K should have grown due to fee accumulation");

        Calc memory c;
        c.claimableA = (ownedLP * finalReserveA) / finalTotalSupply;
        c.claimableB = (ownedLP * finalReserveB) / finalTotalSupply;
        c.tempA = (initialPositionA * initialPositionB * finalReserveA) / finalReserveB;
        c.noFeeA = Math._sqrt(c.tempA);
        c.tempB = (initialPositionA * initialPositionB * finalReserveB) / finalReserveA;
        c.noFeeB = Math._sqrt(c.tempB);
        c.expectedFeeA = c.claimableA > c.noFeeA ? c.claimableA - c.noFeeA : 0;
        c.expectedFeeB = c.claimableB > c.noFeeB ? c.claimableB - c.noFeeB : 0;

        (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialPositionA, initialPositionB, finalReserveA, finalReserveB, finalTotalSupply
        );

        assertEq(calculatedFeeA, c.expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(calculatedFeeB, c.expectedFeeB, "Calculated fee B should equal expected fee B");
    }

    function test_calculateFeePortionForPosition_Uniswap_unbalancedPool() public {
        _initializeUniswapUnbalancedPools();
        (uint112 initialReserveA, uint112 initialReserveB, ) = uniswapUnbalancedPair.getReserves();
        uint256 initialTotalSupply = uniswapUnbalancedPair.totalSupply();
        uint256 initialK = uint256(initialReserveA) * uint256(initialReserveB);

        uint256 ownedLP = initialTotalSupply / 10;
        uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
        uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

        _executeUniswapTradesToGenerateFees(uniswapUnbalancedTokenA, uniswapUnbalancedTokenB);

        (uint112 finalReserveA, uint112 finalReserveB, ) = uniswapUnbalancedPair.getReserves();
        uint256 finalTotalSupply = uniswapUnbalancedPair.totalSupply();

        assertGt(uint256(finalReserveA) * uint256(finalReserveB), initialK, "Pool K should have grown due to fee accumulation");

        Calc memory c;
        c.claimableA = (ownedLP * finalReserveA) / finalTotalSupply;
        c.claimableB = (ownedLP * finalReserveB) / finalTotalSupply;
        c.tempA = (initialPositionA * initialPositionB * finalReserveA) / finalReserveB;
        c.noFeeA = Math._sqrt(c.tempA);
        c.tempB = (initialPositionA * initialPositionB * finalReserveB) / finalReserveA;
        c.noFeeB = Math._sqrt(c.tempB);
        c.expectedFeeA = c.claimableA > c.noFeeA ? c.claimableA - c.noFeeA : 0;
        c.expectedFeeB = c.claimableB > c.noFeeB ? c.claimableB - c.noFeeB : 0;

        (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialPositionA, initialPositionB, finalReserveA, finalReserveB, finalTotalSupply
        );

        assertEq(calculatedFeeA, c.expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(calculatedFeeB, c.expectedFeeB, "Calculated fee B should equal expected fee B");
    }

    function test_calculateFeePortionForPosition_Uniswap_extremeUnbalancedPool() public {
        _initializeUniswapExtremeUnbalancedPools();
        (uint112 initialReserveA, uint112 initialReserveB, ) = uniswapExtremeUnbalancedPair.getReserves();
        uint256 initialTotalSupply = uniswapExtremeUnbalancedPair.totalSupply();
        uint256 initialK = uint256(initialReserveA) * uint256(initialReserveB);

        uint256 ownedLP = initialTotalSupply / 10;
        uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
        uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

        _executeUniswapTradesToGenerateFees(uniswapExtremeTokenA, uniswapExtremeTokenB);

        (uint112 finalReserveA, uint112 finalReserveB, ) = uniswapExtremeUnbalancedPair.getReserves();
        uint256 finalTotalSupply = uniswapExtremeUnbalancedPair.totalSupply();

        assertGt(uint256(finalReserveA) * uint256(finalReserveB), initialK, "Pool K should have grown due to fee accumulation");

        Calc memory c;
        c.claimableA = (ownedLP * finalReserveA) / finalTotalSupply;
        c.claimableB = (ownedLP * finalReserveB) / finalTotalSupply;
        c.tempA = (initialPositionA * initialPositionB * finalReserveA) / finalReserveB;
        c.noFeeA = Math._sqrt(c.tempA);
        c.tempB = (initialPositionA * initialPositionB * finalReserveB) / finalReserveA;
        c.noFeeB = Math._sqrt(c.tempB);
        c.expectedFeeA = c.claimableA > c.noFeeA ? c.claimableA - c.noFeeA : 0;
        c.expectedFeeB = c.claimableB > c.noFeeB ? c.claimableB - c.noFeeB : 0;

        (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialPositionA, initialPositionB, finalReserveA, finalReserveB, finalTotalSupply
        );

        assertEq(calculatedFeeA, c.expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(calculatedFeeB, c.expectedFeeB, "Calculated fee B should equal expected fee B");
    }

    // further Uniswap variants (unbalanced/extreme) can be added similarly
}
