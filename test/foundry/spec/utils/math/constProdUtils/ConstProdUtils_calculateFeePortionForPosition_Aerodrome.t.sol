// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {BetterMath as Math} from "@crane/contracts/utils/math/BetterMath.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Aerodrome.sol";
import {IRouter} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import "forge-std/console.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/stubs/Pool.sol";

contract ConstProdUtils_calculateFeePortionForPosition_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
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
        TestBase_ConstProdUtils_Aerodrome.setUp();
    }

    function test_calculateFeePortionForPosition_Aerodrome_balancedPool() public {
        _initializeAerodromeBalancedPools();
        uint256 initialReserveA = aeroBalancedPool.reserve0();
        uint256 initialReserveB = aeroBalancedPool.reserve1();
        uint256 initialTotalSupply = aeroBalancedPool.totalSupply();
        uint256 initialK = uint256(initialReserveA) * uint256(initialReserveB);

        uint256 ownedLP = initialTotalSupply / 10;
        uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
        uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

        _executeAerodromeTradesToGenerateFees(aeroBalancedTokenA, aeroBalancedTokenB);

        uint256 finalReserveA = aeroBalancedPool.reserve0();
        uint256 finalReserveB = aeroBalancedPool.reserve1();
        uint256 finalTotalSupply = aeroBalancedPool.totalSupply();

        assertGt(uint256(finalReserveA) * uint256(finalReserveB), initialK, "Pool K should have grown due to fee accumulation");

        Calc memory c;
        c.claimableA = (ownedLP * finalReserveA) / finalTotalSupply;
        c.claimableB = (ownedLP * finalReserveB) / finalTotalSupply;
        // match library ordering: sA = (initialA * initialB * reserveA) / reserveB
        c.tempA = Math._mulDiv(initialPositionA, Math._mulDiv(initialPositionB, finalReserveA, 1), finalReserveB);
        c.noFeeA = Math._sqrt(c.tempA);
        // sB = (initialA * initialB * reserveB) / reserveA
        c.tempB = Math._mulDiv(initialPositionA, Math._mulDiv(initialPositionB, finalReserveB, 1), finalReserveA);
        console.log("initialPositionA", initialPositionA);
        console.log("initialPositionB", initialPositionB);
        console.log("finalReserveA", finalReserveA);
        console.log("finalReserveB", finalReserveB);
        console.log("c.tempB", c.tempB);
        c.noFeeB = Math._sqrt(c.tempB);
        c.expectedFeeA = c.claimableA > c.noFeeA ? c.claimableA - c.noFeeA : 0;
        c.expectedFeeB = c.claimableB > c.noFeeB ? c.claimableB - c.noFeeB : 0;

        (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialPositionA, initialPositionB, finalReserveA, finalReserveB, finalTotalSupply
        );

        console.log("claimableB", c.claimableB);
        console.log("noFeeB", c.noFeeB);
        console.log("expectedFeeB", c.expectedFeeB);
        console.log("calculatedFeeB", calculatedFeeB);
        assertEq(calculatedFeeA, c.expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(calculatedFeeB, c.expectedFeeB, "Calculated fee B should equal expected fee B");
    }

    function test_calculateFeePortionForPosition_Aerodrome_unbalancedPool() public {
        _initializeAerodromeUnbalancedPools();
        uint256 initialReserveA = aeroUnbalancedPool.reserve0();
        uint256 initialReserveB = aeroUnbalancedPool.reserve1();
        uint256 initialTotalSupply = aeroUnbalancedPool.totalSupply();
        uint256 initialK = uint256(initialReserveA) * uint256(initialReserveB);

        uint256 ownedLP = initialTotalSupply / 10;
        uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
        uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

        _executeAerodromeTradesToGenerateFees(aeroUnbalancedTokenA, aeroUnbalancedTokenB);

        uint256 finalReserveA = aeroUnbalancedPool.reserve0();
        uint256 finalReserveB = aeroUnbalancedPool.reserve1();
        uint256 finalTotalSupply = aeroUnbalancedPool.totalSupply();

        assertGt(uint256(finalReserveA) * uint256(finalReserveB), initialK, "Pool K should have grown due to fee accumulation");

        Calc memory c;
        c.claimableA = (ownedLP * finalReserveA) / finalTotalSupply;
        c.claimableB = (ownedLP * finalReserveB) / finalTotalSupply;
        c.tempA = Math._mulDiv(initialPositionA, Math._mulDiv(initialPositionB, finalReserveA, 1), finalReserveB);
        c.noFeeA = Math._sqrt(c.tempA);
        c.tempB = Math._mulDiv(initialPositionA, Math._mulDiv(initialPositionB, finalReserveB, 1), finalReserveA);
        c.noFeeB = Math._sqrt(c.tempB);
        c.expectedFeeA = c.claimableA > c.noFeeA ? c.claimableA - c.noFeeA : 0;
        c.expectedFeeB = c.claimableB > c.noFeeB ? c.claimableB - c.noFeeB : 0;

        (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialPositionA, initialPositionB, finalReserveA, finalReserveB, finalTotalSupply
        );

        console.log("claimableB", c.claimableB);
        console.log("noFeeB", c.noFeeB);
        console.log("expectedFeeB", c.expectedFeeB);
        console.log("calculatedFeeB", calculatedFeeB);
        assertEq(calculatedFeeA, c.expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(calculatedFeeB, c.expectedFeeB, "Calculated fee B should equal expected fee B");
    }

    function test_calculateFeePortionForPosition_Aerodrome_extremeUnbalancedPool() public {
        _initializeAerodromeExtremeUnbalancedPools();
        uint256 initialReserveA = aeroExtremeUnbalancedPool.reserve0();
        uint256 initialReserveB = aeroExtremeUnbalancedPool.reserve1();
        uint256 initialTotalSupply = aeroExtremeUnbalancedPool.totalSupply();
        uint256 initialK = uint256(initialReserveA) * uint256(initialReserveB);

        uint256 ownedLP = initialTotalSupply / 10;
        uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
        uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

        _executeAerodromeTradesToGenerateFees(aeroExtremeTokenA, aeroExtremeTokenB);

        uint256 finalReserveA = aeroExtremeUnbalancedPool.reserve0();
        uint256 finalReserveB = aeroExtremeUnbalancedPool.reserve1();
        uint256 finalTotalSupply = aeroExtremeUnbalancedPool.totalSupply();

        assertGt(uint256(finalReserveA) * uint256(finalReserveB), initialK, "Pool K should have grown due to fee accumulation");

        Calc memory c;
        c.claimableA = (ownedLP * finalReserveA) / finalTotalSupply;
        c.claimableB = (ownedLP * finalReserveB) / finalTotalSupply;
        c.tempA = Math._mulDiv(initialPositionA, Math._mulDiv(initialPositionB, finalReserveA, 1), finalReserveB);
        c.noFeeA = Math._sqrt(c.tempA);
        c.tempB = Math._mulDiv(initialPositionA, Math._mulDiv(initialPositionB, finalReserveB, 1), finalReserveA);
        c.noFeeB = Math._sqrt(c.tempB);
        c.expectedFeeA = c.claimableA > c.noFeeA ? c.claimableA - c.noFeeA : 0;
        c.expectedFeeB = c.claimableB > c.noFeeB ? c.claimableB - c.noFeeB : 0;

        (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialPositionA, initialPositionB, finalReserveA, finalReserveB, finalTotalSupply
        );

        console.log("claimableB", c.claimableB);
        console.log("noFeeB", c.noFeeB);
        console.log("expectedFeeB", c.expectedFeeB);
        console.log("calculatedFeeB", calculatedFeeB);
        assertEq(calculatedFeeA, c.expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(calculatedFeeB, c.expectedFeeB, "Calculated fee B should equal expected fee B");
    }

    // further Aerodrome variants (unbalanced/extreme) can be added similarly
}
