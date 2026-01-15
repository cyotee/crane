// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ICamelotPair} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol";
import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Camelot.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {CamelotPair} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol";

/**
 * @title CamelotV2_asymmetricFees_Test
 * @notice Tests for Camelot V2 asymmetric fee behavior (token0FeePercent != token1FeePercent)
 * @dev Camelot V2's distinguishing feature is directional fees where different swap directions
 *      can have different fee rates. This test suite verifies this behavior.
 */
contract CamelotV2_asymmetricFees_Test is TestBase_ConstProdUtils_Camelot {
    using CamelotV2Service for ICamelotPair;
    using ConstProdUtils for uint256;

    /* ---------------------------------------------------------------------- */
    /*                              Test Tokens                               */
    /* ---------------------------------------------------------------------- */

    ERC20PermitMintableStub asymmetricTokenA;
    ERC20PermitMintableStub asymmetricTokenB;
    ICamelotPair asymmetricPair;

    /* ---------------------------------------------------------------------- */
    /*                              Constants                                 */
    /* ---------------------------------------------------------------------- */

    uint256 constant FEE_DENOMINATOR = 100000;
    uint256 constant MAX_FEE_PERCENT = 2000; // 2%
    uint256 constant ASYMMETRIC_INITIAL_LIQUIDITY = 10000e18;

    /* ---------------------------------------------------------------------- */
    /*                                 Setup                                  */
    /* ---------------------------------------------------------------------- */

    function setUp() public override {
        TestBase_ConstProdUtils_Camelot.setUp();
        _createAsymmetricTokens();
        _createAsymmetricPair();
    }

    function _createAsymmetricTokens() internal {
        asymmetricTokenA = new ERC20PermitMintableStub("AsymmetricTokenA", "ASYMA", 18, address(this), 0);
        vm.label(address(asymmetricTokenA), "AsymmetricTokenA");

        asymmetricTokenB = new ERC20PermitMintableStub("AsymmetricTokenB", "ASYMB", 18, address(this), 0);
        vm.label(address(asymmetricTokenB), "AsymmetricTokenB");
    }

    function _createAsymmetricPair() internal {
        asymmetricPair = ICamelotPair(camelotV2Factory.createPair(address(asymmetricTokenA), address(asymmetricTokenB)));
        vm.label(address(asymmetricPair), "AsymmetricPair");
    }

    function _initializeAsymmetricPool() internal {
        asymmetricTokenA.mint(address(this), ASYMMETRIC_INITIAL_LIQUIDITY);
        asymmetricTokenA.approve(address(camelotV2Router), ASYMMETRIC_INITIAL_LIQUIDITY);
        asymmetricTokenB.mint(address(this), ASYMMETRIC_INITIAL_LIQUIDITY);
        asymmetricTokenB.approve(address(camelotV2Router), ASYMMETRIC_INITIAL_LIQUIDITY);

        CamelotV2Service._deposit(camelotV2Router, asymmetricTokenA, asymmetricTokenB, ASYMMETRIC_INITIAL_LIQUIDITY, ASYMMETRIC_INITIAL_LIQUIDITY);
    }

    function _setAsymmetricFees(uint16 token0Fee, uint16 token1Fee) internal {
        // The feePercentOwner is the deployer of CamelotFactory (this contract's setUp uses camelotV2FeeToSetter indirectly)
        // In TestBase_CamelotV2, the factory is created with feeToSetter as the constructor arg,
        // but feePercentOwner is set to msg.sender (this test contract).
        vm.prank(address(this));
        CamelotPair(address(asymmetricPair)).setFeePercent(token0Fee, token1Fee);
    }

    /* ---------------------------------------------------------------------- */
    /*                         Asymmetric Fee Tests                           */
    /* ---------------------------------------------------------------------- */

    /// @notice Test that asymmetric fees can be set on a pair
    function test_setAsymmetricFees_updatesCorrectly() public {
        _initializeAsymmetricPool();

        uint16 newToken0Fee = 300; // 0.3%
        uint16 newToken1Fee = 1000; // 1.0%

        _setAsymmetricFees(newToken0Fee, newToken1Fee);

        (, , uint16 actualToken0Fee, uint16 actualToken1Fee) = asymmetricPair.getReserves();

        assertEq(actualToken0Fee, newToken0Fee, "Token0 fee should be updated");
        assertEq(actualToken1Fee, newToken1Fee, "Token1 fee should be updated");
    }

    /// @notice Test that swapping token0 -> token1 uses token0Fee
    function test_swap_token0ToToken1_usesToken0Fee() public {
        _initializeAsymmetricPool();

        uint16 token0Fee = 300; // 0.3%
        uint16 token1Fee = 1000; // 1.0%
        _setAsymmetricFees(token0Fee, token1Fee);

        uint256 swapAmount = 100e18;
        asymmetricTokenA.mint(address(this), swapAmount);
        asymmetricTokenA.approve(address(camelotV2Router), swapAmount);

        (uint112 reserve0, uint112 reserve1, , ) = asymmetricPair.getReserves();

        // Determine which token is token0 (tokenA or tokenB)
        address token0 = asymmetricPair.token0();
        bool tokenAIsToken0 = (address(asymmetricTokenA) == token0);

        // Calculate expected output using the correct fee
        uint256 expectedFee = tokenAIsToken0 ? token0Fee : token1Fee;
        uint256 reserveIn = tokenAIsToken0 ? reserve0 : reserve1;
        uint256 reserveOut = tokenAIsToken0 ? reserve1 : reserve0;

        uint256 expectedOut = ConstProdUtils._saleQuote(swapAmount, reserveIn, reserveOut, expectedFee);

        uint256 balanceBefore = asymmetricTokenB.balanceOf(address(this));

        // Execute swap
        uint256 amountOut = CamelotV2Service._swap(
            camelotV2Router,
            asymmetricPair,
            swapAmount,
            asymmetricTokenA,
            asymmetricTokenB,
            address(0)
        );

        uint256 balanceAfter = asymmetricTokenB.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(amountOut, expectedOut, "Output should match expected with correct fee");
        assertEq(actualReceived, expectedOut, "Actual received should match expected");
    }

    /// @notice Test that swapping token1 -> token0 uses token1Fee
    function test_swap_token1ToToken0_usesToken1Fee() public {
        _initializeAsymmetricPool();

        uint16 token0Fee = 300; // 0.3%
        uint16 token1Fee = 1000; // 1.0%
        _setAsymmetricFees(token0Fee, token1Fee);

        uint256 swapAmount = 100e18;
        asymmetricTokenB.mint(address(this), swapAmount);
        asymmetricTokenB.approve(address(camelotV2Router), swapAmount);

        (uint112 reserve0, uint112 reserve1, , ) = asymmetricPair.getReserves();

        // Determine which token is token0 (tokenA or tokenB)
        address token0 = asymmetricPair.token0();
        bool tokenBIsToken0 = (address(asymmetricTokenB) == token0);

        // Calculate expected output using the correct fee (token B's fee)
        uint256 expectedFee = tokenBIsToken0 ? token0Fee : token1Fee;
        uint256 reserveIn = tokenBIsToken0 ? reserve0 : reserve1;
        uint256 reserveOut = tokenBIsToken0 ? reserve1 : reserve0;

        uint256 expectedOut = ConstProdUtils._saleQuote(swapAmount, reserveIn, reserveOut, expectedFee);

        uint256 balanceBefore = asymmetricTokenA.balanceOf(address(this));

        // Execute swap
        uint256 amountOut = CamelotV2Service._swap(
            camelotV2Router,
            asymmetricPair,
            swapAmount,
            asymmetricTokenB,
            asymmetricTokenA,
            address(0)
        );

        uint256 balanceAfter = asymmetricTokenA.balanceOf(address(this));
        uint256 actualReceived = balanceAfter - balanceBefore;

        assertEq(amountOut, expectedOut, "Output should match expected with correct fee");
        assertEq(actualReceived, expectedOut, "Actual received should match expected");
    }

    /// @notice Test that bidirectional swaps produce different outputs with asymmetric fees
    function test_asymmetricFees_swapDirectionsMatterForOutput() public {
        _initializeAsymmetricPool();

        uint16 token0Fee = 300; // 0.3%
        uint16 token1Fee = 1500; // 1.5%
        _setAsymmetricFees(token0Fee, token1Fee);

        uint256 swapAmount = 100e18;

        // Get reserves
        (uint112 reserve0, uint112 reserve1, , ) = asymmetricPair.getReserves();

        // Calculate outputs for both directions (using the same reserves for fair comparison)
        // When swapping X -> Y, we use X's fee
        uint256 output0To1 = ConstProdUtils._saleQuote(swapAmount, reserve0, reserve1, token0Fee);
        uint256 output1To0 = ConstProdUtils._saleQuote(swapAmount, reserve1, reserve0, token1Fee);

        // With different fees, outputs should be different
        // The direction with lower fee should give more output
        assertTrue(output0To1 != output1To0, "Outputs should differ with asymmetric fees");

        // Lower fee direction should yield more
        if (token0Fee < token1Fee) {
            assertGt(output0To1, output1To0, "Lower fee direction (0->1) should yield more");
        } else {
            assertGt(output1To0, output0To1, "Lower fee direction (1->0) should yield more");
        }
    }

    /// @notice Verify _sortReservesStruct correctly returns the input token's fee
    function test_sortReservesStruct_selectsFeeByDirection() public {
        _initializeAsymmetricPool();

        uint16 token0Fee = 200; // 0.2%
        uint16 token1Fee = 800; // 0.8%
        _setAsymmetricFees(token0Fee, token1Fee);

        address token0 = asymmetricPair.token0();
        bool tokenAIsToken0 = (address(asymmetricTokenA) == token0);

        // Test with tokenA as input
        CamelotV2Service.ReserveInfo memory reservesA = CamelotV2Service._sortReservesStruct(asymmetricPair, asymmetricTokenA);

        if (tokenAIsToken0) {
            assertEq(reservesA.feePercent, token0Fee, "TokenA (token0) should have token0Fee");
            assertEq(reservesA.unknownFee, token1Fee, "TokenB (token1) should have token1Fee");
        } else {
            assertEq(reservesA.feePercent, token1Fee, "TokenA (token1) should have token1Fee");
            assertEq(reservesA.unknownFee, token0Fee, "TokenB (token0) should have token0Fee");
        }

        // Test with tokenB as input
        CamelotV2Service.ReserveInfo memory reservesB = CamelotV2Service._sortReservesStruct(asymmetricPair, asymmetricTokenB);

        if (!tokenAIsToken0) {
            assertEq(reservesB.feePercent, token0Fee, "TokenB (token0) should have token0Fee");
            assertEq(reservesB.unknownFee, token1Fee, "TokenA (token1) should have token1Fee");
        } else {
            assertEq(reservesB.feePercent, token1Fee, "TokenB (token1) should have token1Fee");
            assertEq(reservesB.unknownFee, token0Fee, "TokenA (token0) should have token0Fee");
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                              Fuzz Tests                                */
    /* ---------------------------------------------------------------------- */

    /// @notice Fuzz test for asymmetric fees with varying fee values
    function testFuzz_asymmetricFees_swapDirection(
        uint16 token0Fee,
        uint16 token1Fee,
        uint256 swapAmount
    ) public {
        // Bound fees to valid Camelot range (1 to 2000 = 0.001% to 2%)
        token0Fee = uint16(bound(uint256(token0Fee), 1, MAX_FEE_PERCENT));
        token1Fee = uint16(bound(uint256(token1Fee), 1, MAX_FEE_PERCENT));

        // Ensure asymmetry
        vm.assume(token0Fee != token1Fee);

        // Bound swap amount to reasonable range
        swapAmount = bound(swapAmount, 1e15, 1000e18);

        _initializeAsymmetricPool();
        _setAsymmetricFees(token0Fee, token1Fee);

        // Mint tokens for swap
        asymmetricTokenA.mint(address(this), swapAmount);
        asymmetricTokenA.approve(address(camelotV2Router), swapAmount);

        // Get reserves and determine token ordering
        (uint112 reserve0, uint112 reserve1, uint16 actualFee0, uint16 actualFee1) = asymmetricPair.getReserves();

        assertEq(actualFee0, token0Fee, "Token0 fee should match");
        assertEq(actualFee1, token1Fee, "Token1 fee should match");

        // Perform swap tokenA -> tokenB
        address token0 = asymmetricPair.token0();
        bool tokenAIsToken0 = (address(asymmetricTokenA) == token0);

        uint256 expectedFee = tokenAIsToken0 ? token0Fee : token1Fee;
        uint256 reserveIn = tokenAIsToken0 ? reserve0 : reserve1;
        uint256 reserveOut = tokenAIsToken0 ? reserve1 : reserve0;

        uint256 expectedOut = ConstProdUtils._saleQuote(swapAmount, reserveIn, reserveOut, expectedFee);

        uint256 amountOut = CamelotV2Service._swap(
            camelotV2Router,
            asymmetricPair,
            swapAmount,
            asymmetricTokenA,
            asymmetricTokenB,
            address(0)
        );

        assertEq(amountOut, expectedOut, "Output should match expected with fuzzed fees");
        assertGt(amountOut, 0, "Output should be positive");
    }

    /// @notice Fuzz test verifying both swap directions with same input amount
    function testFuzz_asymmetricFees_bothDirections(
        uint16 token0Fee,
        uint16 token1Fee,
        uint256 swapAmount
    ) public {
        // Bound fees to valid Camelot range
        token0Fee = uint16(bound(uint256(token0Fee), 100, MAX_FEE_PERCENT)); // Min 0.1% for measurable difference
        token1Fee = uint16(bound(uint256(token1Fee), 100, MAX_FEE_PERCENT));

        // Ensure different fees for meaningful test
        vm.assume(token0Fee != token1Fee);
        vm.assume(token0Fee > 0 && token1Fee > 0);

        // Bound swap amount - keep it small relative to liquidity to avoid extreme price impact
        swapAmount = bound(swapAmount, 1e16, 100e18);

        _initializeAsymmetricPool();
        _setAsymmetricFees(token0Fee, token1Fee);

        // Mint tokens for both directions
        asymmetricTokenA.mint(address(this), swapAmount);
        asymmetricTokenA.approve(address(camelotV2Router), swapAmount);
        asymmetricTokenB.mint(address(this), swapAmount);
        asymmetricTokenB.approve(address(camelotV2Router), swapAmount);

        // Get initial balances
        uint256 balanceABefore = asymmetricTokenA.balanceOf(address(this));
        uint256 balanceBBefore = asymmetricTokenB.balanceOf(address(this));

        // Swap A -> B
        uint256 outputAToB = CamelotV2Service._swap(
            camelotV2Router,
            asymmetricPair,
            swapAmount,
            asymmetricTokenA,
            asymmetricTokenB,
            address(0)
        );

        // Get new reserves after first swap
        (uint112 reserve0After, uint112 reserve1After, , ) = asymmetricPair.getReserves();

        // Swap B -> A
        uint256 outputBToA = CamelotV2Service._swap(
            camelotV2Router,
            asymmetricPair,
            swapAmount,
            asymmetricTokenB,
            asymmetricTokenA,
            address(0)
        );

        // Both swaps should produce positive output
        assertGt(outputAToB, 0, "A->B swap should produce output");
        assertGt(outputBToA, 0, "B->A swap should produce output");

        // With asymmetric fees, the outputs should generally be different
        // (unless the reserves happen to make them equal, which is unlikely)
        // We can't assert they're always different due to mathematical edge cases,
        // but we verify the fee selection mechanism works
        address token0 = asymmetricPair.token0();
        bool tokenAIsToken0 = (address(asymmetricTokenA) == token0);

        // Verify fee selection is correct by checking reserves struct
        CamelotV2Service.ReserveInfo memory resA = CamelotV2Service._sortReservesStruct(asymmetricPair, asymmetricTokenA);
        CamelotV2Service.ReserveInfo memory resB = CamelotV2Service._sortReservesStruct(asymmetricPair, asymmetricTokenB);

        if (tokenAIsToken0) {
            assertEq(resA.feePercent, token0Fee, "TokenA input should use token0Fee");
            assertEq(resB.feePercent, token1Fee, "TokenB input should use token1Fee");
        } else {
            assertEq(resA.feePercent, token1Fee, "TokenA input should use token1Fee");
            assertEq(resB.feePercent, token0Fee, "TokenB input should use token0Fee");
        }
    }

    /// @notice Fuzz test that extreme fee asymmetry works correctly
    function testFuzz_extremeAsymmetry(uint256 swapAmount) public {
        // Use extreme fee difference
        uint16 lowFee = 100; // 0.1%
        uint16 highFee = 2000; // 2.0% (max allowed)

        swapAmount = bound(swapAmount, 1e16, 500e18);

        _initializeAsymmetricPool();
        _setAsymmetricFees(lowFee, highFee);

        asymmetricTokenA.mint(address(this), swapAmount);
        asymmetricTokenA.approve(address(camelotV2Router), swapAmount);

        // Swap should work without reverting
        uint256 amountOut = CamelotV2Service._swap(
            camelotV2Router,
            asymmetricPair,
            swapAmount,
            asymmetricTokenA,
            asymmetricTokenB,
            address(0)
        );

        assertGt(amountOut, 0, "Extreme asymmetry swap should produce output");

        // Verify reserves are still valid
        (uint112 r0, uint112 r1, , ) = asymmetricPair.getReserves();
        assertGt(r0, 0, "Reserve0 should be positive after swap");
        assertGt(r1, 0, "Reserve1 should be positive after swap");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Direct Pair Swap Tests                           */
    /* ---------------------------------------------------------------------- */

    /// @notice Test pair's getAmountOut with asymmetric fees returns correct value
    function test_pairGetAmountOut_respectsAsymmetricFees() public {
        _initializeAsymmetricPool();

        uint16 token0Fee = 300;
        uint16 token1Fee = 900;
        _setAsymmetricFees(token0Fee, token1Fee);

        uint256 amountIn = 100e18;

        address token0 = asymmetricPair.token0();
        address token1 = asymmetricPair.token1();

        // Get output for swapping token0
        uint256 output0 = asymmetricPair.getAmountOut(amountIn, token0);

        // Get output for swapping token1
        uint256 output1 = asymmetricPair.getAmountOut(amountIn, token1);

        // With symmetric reserves but asymmetric fees, outputs should differ
        // Lower fee should give higher output
        assertGt(output0, output1, "Token0 (lower fee) should give more output than Token1 (higher fee)");
    }

    /* ---------------------------------------------------------------------- */
    /*                       Edge Case Tests                                  */
    /* ---------------------------------------------------------------------- */

    /// @notice Test equal fees (control case - should behave like symmetric)
    function test_equalFees_symmetricBehavior() public {
        _initializeAsymmetricPool();

        uint16 equalFee = 500; // 0.5%
        _setAsymmetricFees(equalFee, equalFee);

        uint256 swapAmount = 100e18;

        (uint112 reserve0, uint112 reserve1, , ) = asymmetricPair.getReserves();

        // With equal reserves and equal fees, outputs should be equal
        uint256 output0To1 = ConstProdUtils._saleQuote(swapAmount, reserve0, reserve1, equalFee);
        uint256 output1To0 = ConstProdUtils._saleQuote(swapAmount, reserve1, reserve0, equalFee);

        assertEq(output0To1, output1To0, "Equal fees should give symmetric outputs with equal reserves");
    }

    /// @notice Test minimum fee boundary
    function test_minimumFeeBoundary() public {
        _initializeAsymmetricPool();

        uint16 minFee = 1; // 0.001%
        uint16 regularFee = 500;
        _setAsymmetricFees(minFee, regularFee);

        uint256 swapAmount = 100e18;
        asymmetricTokenA.mint(address(this), swapAmount);
        asymmetricTokenA.approve(address(camelotV2Router), swapAmount);

        // Should not revert
        uint256 amountOut = CamelotV2Service._swap(
            camelotV2Router,
            asymmetricPair,
            swapAmount,
            asymmetricTokenA,
            asymmetricTokenB,
            address(0)
        );

        assertGt(amountOut, 0, "Minimum fee swap should produce output");
    }

    /// @notice Test maximum fee boundary
    function test_maximumFeeBoundary() public {
        _initializeAsymmetricPool();

        uint16 maxFee = 2000; // 2.0%
        uint16 regularFee = 500;
        _setAsymmetricFees(maxFee, regularFee);

        uint256 swapAmount = 100e18;
        asymmetricTokenA.mint(address(this), swapAmount);
        asymmetricTokenA.approve(address(camelotV2Router), swapAmount);

        // Should not revert
        uint256 amountOut = CamelotV2Service._swap(
            camelotV2Router,
            asymmetricPair,
            swapAmount,
            asymmetricTokenA,
            asymmetricTokenB,
            address(0)
        );

        assertGt(amountOut, 0, "Maximum fee swap should produce output");
    }
}
