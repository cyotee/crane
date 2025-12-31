// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";

contract PowerCalculatorC2ATarget_IPower_power_Test is Test_Crane {
    // Define MAX_NUM as a constant
    uint256 constant MAX_NUM = 0x200000000000000000000000000000000;

    function setUp() public virtual override {
        owner(address(this));
        // super.setUp();
    }

    function testSimplePower() public {
        (uint256 result, uint8 precision) = powerCalculator().power(2, 1, 1, 1);
        /// forge-lint: disable-next-line(incorrect-shift)
        uint256 expected = 2 * (1 << precision); // 2^1 = 2, scaled
        assertApproxEqRel(result, expected, 1e15); // Allow 0.001% error
        // assertEq(result, expected); // Allow 0.001% error
    }

    function testFractionalPower() public {
        (uint256 result, uint8 precision) = powerCalculator().power(4, 1, 1, 2);
        /// forge-lint: disable-next-line(incorrect-shift)
        uint256 expected = 2 * (1 << precision); // 4^(1/2) = 2, scaled
        assertApproxEqRel(result, expected, 1e15);
        // assertEq(result, expected);
    }

    function testEdgeCaseLargeBase() public {
        uint256 maxNum = 0x200000000000000000000000000000000 - 1;
        (uint256 result, uint8 precision) = powerCalculator().power(maxNum, 1, 1, 1000);
        // Expected result requires external calculation, e.g., (2^125 - 1)^(0.001)
        // For testing, ensure it doesn't revert and result is reasonable
        /// forge-lint: disable-next-line(incorrect-shift)
        assertGt(result, 1 << precision); // Should be > 1
    }

    function testZeroExponent() public {
        (uint256 result, uint8 precision) = powerCalculator().power(5, 1, 0, 1);
        /// forge-lint: disable-next-line(incorrect-shift)
        uint256 expected = 1 * (1 << precision); // 5^0 = 1, scaled
        // assertApproxEqRel(result, expected, 1e15);
        assertEq(result, expected);
    }

    // General fuzzing test with bounded inputs
    // function testFuzzPower(uint256 baseN, uint256 baseD, uint32 expN, uint32 expD) public {
    //     // Constrain baseD: 1 <= baseD <= MAX_NUM - 1
    //     // vm.assume(baseD >= 1);
    //     // vm.assume(baseD <= MAX_NUM - 1);

    //     // Constrain baseN: baseD <= baseN < MAX_NUM
    //     // vm.assume(baseN >= baseD);
    //     // vm.assume(baseN < MAX_NUM);
    //     baseD = bound(baseD, 1, MAX_NUM - 1);
    //     baseN = bound(baseN, baseD, MAX_NUM - 1);

    //     // Constrain expD: 1 <= expD <= type(uint32).max (implicitly satisfied by uint32, but explicit for clarity)
    //     vm.assume(expD >= 1);

    //     // expN is already bounded by uint32 (0 to type(uint32).max), no additional constraint needed

    //     // Call the power function
    //     (uint256 result, uint8 precision) = powerCalculator().power(baseN, baseD, expN, expD);

    //     // Verify basic properties
    //     assertTrue(precision >= 32 && precision <= 127); // Precision should be between 32 and 127
    //     if (expN == 0) {
    //         // When exponent is zero, result should be 1 * 2^precision
    //         uint256 expected = uint256(1) << precision;
    //         assertEq(result, expected);
    //     } else if (baseN > 0) {
    //         // For non-zero base and exponent, result should be positive
    //         assertGt(result, 0);
    //     }
    // }

    // Fuzzing test for exponent = 1
    // function testFuzzPowerExponentOne(uint256 baseN, uint256 baseD) public {
    //     // Constrain baseD: 1 <= baseD <= MAX_NUM - 1
    //     // vm.assume(baseD >= 1);
    //     // vm.assume(baseD <= MAX_NUM - 1);

    //     // Constrain baseN: baseD <= baseN < MAX_NUM
    //     // vm.assume(baseN >= baseD);
    //     // vm.assume(baseN < MAX_NUM);
    //     baseD = bound(baseD, 1, MAX_NUM - 1);
    //     baseN = bound(baseN, baseD, MAX_NUM - 1);

    //     uint32 expN = 1;
    //     uint32 expD = 1;

    //     (uint256 result, uint8 precision) = powerCalculator().power(baseN, baseD, expN, expD);

    //     // For exponent = 1, result should approximate (baseN / baseD) * 2^precision
    //     uint256 expected = (baseN * (1 << precision)) / baseD;
    //     // Allow small tolerance due to precision limitations
    //     assertApproxEqRel(result, expected, 1e15); // 0.001% relative tolerance
    // }

    // Fuzzing test for edge case: maximum base
    // function testFuzzPowerMaxBase(uint32 expN, uint32 expD) public {
    //     uint256 baseN = MAX_NUM - 1; // Maximum allowed baseN
    //     uint256 baseD = 1;

    //     // Constrain expD: >= 1
    //     vm.assume(expD >= 1);

    //     // Limit expN to prevent overflow (arbitrary reasonable bound)
    //     vm.assume(expN <= 1000);
    //     // baseD = bound(baseD, 1, MAX_NUM - 1);
    //     // baseN = bound(baseN, baseD, MAX_NUM - 1);

    //     (uint256 result, uint8 precision) = powerCalculator().power(baseN, baseD, expN, expD);

    //     // Result should be large but not overflow uint256
    //     assertLt(result, type(uint256).max);
    // }
}
