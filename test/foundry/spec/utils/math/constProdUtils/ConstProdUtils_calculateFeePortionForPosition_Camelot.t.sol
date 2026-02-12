// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Math as CamMath} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/libraries/Math.sol";
import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {CamelotV2Utils} from "contracts/utils/math/CamelotV2Utils.sol";
import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Camelot.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_calculateFeePortionForPosition_Camelot is TestBase_ConstProdUtils_Camelot {
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
        TestBase_ConstProdUtils_Camelot.setUp();
    }

    function test_calculateFeePortionForPosition_Camelot_balancedPool() public {
        _initializeCamelotBalancedPools();
        (uint112 initialReserveA, uint112 initialReserveB, , ) = camelotBalancedPair.getReserves();
        uint256 initialTotalSupply = camelotBalancedPair.totalSupply();
        uint256 initialK = uint256(initialReserveA) * uint256(initialReserveB);

        uint256 ownedLP = initialTotalSupply / 10;
        uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
        uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

        _executeCamelotTradesToGenerateFees(camelotBalancedTokenA, camelotBalancedTokenB);

        (uint112 finalReserveA, uint112 finalReserveB, , ) = camelotBalancedPair.getReserves();
        uint256 finalTotalSupply = camelotBalancedPair.totalSupply();

        assertGt(uint256(finalReserveA) * uint256(finalReserveB), initialK, "Pool K should have grown due to fee accumulation");

        (, address feeTo) = camelotV2Factory.feeInfo();
        (uint256 expectedFeeA, uint256 expectedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP,
            initialPositionA,
            initialPositionB,
            finalReserveA,
            finalReserveB,
            finalTotalSupply
        );

        (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialPositionA, initialPositionB, finalReserveA, finalReserveB, finalTotalSupply
        );

        assertEq(calculatedFeeA, expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(calculatedFeeB, expectedFeeB, "Calculated fee B should equal expected fee B");
    }

    function test_calculateFeePortionForPosition_Camelot_unbalancedPool() public {
        _initializeCamelotUnbalancedPools();
        (uint112 initialReserveA, uint112 initialReserveB, , ) = camelotUnbalancedPair.getReserves();
        uint256 initialTotalSupply = camelotUnbalancedPair.totalSupply();
        uint256 initialK = uint256(initialReserveA) * uint256(initialReserveB);

        uint256 ownedLP = initialTotalSupply / 10;
        uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
        uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

        _executeCamelotTradesToGenerateFees(camelotUnbalancedTokenA, camelotUnbalancedTokenB);

        (uint112 finalReserveA, uint112 finalReserveB, , ) = camelotUnbalancedPair.getReserves();
        uint256 finalTotalSupply = camelotUnbalancedPair.totalSupply();

        assertGt(uint256(finalReserveA) * uint256(finalReserveB), initialK, "Pool K should have grown due to fee accumulation");

        (, address feeTo) = camelotV2Factory.feeInfo();
        (uint256 expectedFeeA, uint256 expectedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP,
            initialPositionA,
            initialPositionB,
            finalReserveA,
            finalReserveB,
            finalTotalSupply
        );

        (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialPositionA, initialPositionB, finalReserveA, finalReserveB, finalTotalSupply
        );

        assertEq(calculatedFeeA, expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(calculatedFeeB, expectedFeeB, "Calculated fee B should equal expected fee B");
    }

    function test_calculateFeePortionForPosition_Camelot_extremeUnbalancedPool() public {
        _initializeCamelotExtremeUnbalancedPools();
        (uint112 initialReserveA, uint112 initialReserveB, , ) = camelotExtremeUnbalancedPair.getReserves();
        uint256 initialTotalSupply = camelotExtremeUnbalancedPair.totalSupply();
        uint256 initialK = uint256(initialReserveA) * uint256(initialReserveB);

        uint256 ownedLP = initialTotalSupply / 10;
        uint256 initialPositionA = (ownedLP * initialReserveA) / initialTotalSupply;
        uint256 initialPositionB = (ownedLP * initialReserveB) / initialTotalSupply;

        _executeCamelotTradesToGenerateFees(camelotExtremeTokenA, camelotExtremeTokenB);

        (uint112 finalReserveA, uint112 finalReserveB, , ) = camelotExtremeUnbalancedPair.getReserves();
        uint256 finalTotalSupply = camelotExtremeUnbalancedPair.totalSupply();

        assertGt(uint256(finalReserveA) * uint256(finalReserveB), initialK, "Pool K should have grown due to fee accumulation");

        (, address feeTo) = camelotV2Factory.feeInfo();
        (uint256 expectedFeeA, uint256 expectedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP,
            initialPositionA,
            initialPositionB,
            finalReserveA,
            finalReserveB,
            finalTotalSupply
        );

        (uint256 calculatedFeeA, uint256 calculatedFeeB) = ConstProdUtils._calculateFeePortionForPosition(
            ownedLP, initialPositionA, initialPositionB, finalReserveA, finalReserveB, finalTotalSupply
        );

        assertEq(calculatedFeeA, expectedFeeA, "Calculated fee A should equal expected fee A");
        assertEq(calculatedFeeB, expectedFeeB, "Calculated fee B should equal expected fee B");
    }
}
