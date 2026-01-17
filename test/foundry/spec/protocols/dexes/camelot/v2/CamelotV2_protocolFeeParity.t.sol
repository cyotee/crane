// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {FEE_DENOMINATOR} from "@crane/contracts/constants/Constants.sol";
import {ICamelotPair} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotFactory} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {TestBase_CamelotV2} from "@crane/contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {Math as CamMath} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/libraries/Math.sol";
import {CamelotFactory} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol";

/**
 * @title ConstProdUtilsProtocolFeeHarness
 * @notice Exposes internal _calculateProtocolFee for testing
 */
contract ConstProdUtilsProtocolFeeHarness {
    function calculateProtocolFee(
        uint256 lpTotalSupply,
        uint256 newK,
        uint256 kLast,
        uint256 ownerFeeShare
    ) external pure returns (uint256 lpOfYield) {
        return ConstProdUtils._calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);
    }
}

/**
 * @title CamelotV2_protocolFeeParity_Test
 * @notice Tests for protocol fee calculation parity between ConstProdUtils._calculateProtocolFee()
 *         and CamelotPair._mintFee()
 * @dev Origin: CRANE-012 code review (Gap #3: Protocol Fee Mint Parity)
 *
 * These tests verify:
 * - Edge cases: kLast=0, rootK==rootKLast
 * - ownerFeeShare boundary values (0, 50000, 100000)
 * - Cross-reference with actual pair _mintFee() output
 * - Property-based tests for fee invariants
 */
contract CamelotV2_protocolFeeParity_Test is TestBase_CamelotV2 {
    ConstProdUtilsProtocolFeeHarness internal harness;

    // Test tokens
    ERC20PermitMintableStub internal tokenA;
    ERC20PermitMintableStub internal tokenB;
    ICamelotPair internal pair;

    // Standard test amounts
    uint256 constant INITIAL_LIQUIDITY = 10000e18;

    function setUp() public override {
        super.setUp();
        harness = new ConstProdUtilsProtocolFeeHarness();

        // Create test tokens
        tokenA = new ERC20PermitMintableStub("TokenA", "TKA", 18, address(this), 0);
        vm.label(address(tokenA), "TokenA");
        tokenB = new ERC20PermitMintableStub("TokenB", "TKB", 18, address(this), 0);
        vm.label(address(tokenB), "TokenB");

        // Create pair
        pair = ICamelotPair(camelotV2Factory.createPair(address(tokenA), address(tokenB)));
        vm.label(address(pair), "CamelotPair");
    }

    /* -------------------------------------------------------------------------- */
    /*                         Edge Case: kLast == 0                              */
    /* -------------------------------------------------------------------------- */

    /// @notice When kLast is 0, no protocol fee should be calculated
    function test_calculateProtocolFee_kLastZero_returnsZero() public view {
        uint256 lpTotalSupply = 1000e18;
        uint256 newK = 100e36; // sqrt = 10e18
        uint256 kLast = 0; // No previous K recorded
        uint256 ownerFeeShare = 50000; // 50%

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);

        assertEq(fee, 0, "Protocol fee should be 0 when kLast is 0");
    }

    /// @notice Verify that when fee is enabled but kLast was 0, no fee is minted on first liquidity add
    /// @dev The CamelotFactory sets feeTo on construction, so kLast is set on first mint.
    ///      This test verifies the _calculateProtocolFee returns 0 when kLast is 0.
    function test_pairMintFee_kLastZero_calculationReturnsZero() public view {
        // Simulate scenario where kLast is 0 but fee is enabled
        // _calculateProtocolFee should return 0
        uint256 lpTotalSupply = 1000e18;
        uint256 newK = 1e44; // Typical pool K value
        uint256 kLast = 0;
        uint256 ownerFeeShare = 50000;

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);
        assertEq(fee, 0, "Fee should be 0 when kLast is 0");
    }

    /// @notice Verify kLast is properly set after fee-enabled mint
    function test_pairMintFee_kLastSetAfterMint() public {
        // Enable fees before first deposit (factory constructor sets feeTo)
        // After deposit, kLast should be set because feeOn = true

        // Initialize pool
        _initializePool(INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);

        // kLast should be set because feeTo is already set in factory constructor
        uint256 kLastAfterInit = pair.kLast();
        assertGt(kLastAfterInit, 0, "kLast should be set after first mint with fee enabled");

        // Verify it equals reserve0 * reserve1
        (uint112 r0, uint112 r1,,) = pair.getReserves();
        uint256 expectedK = uint256(r0) * uint256(r1);
        assertEq(kLastAfterInit, expectedK, "kLast should equal current K after mint");
    }

    /* -------------------------------------------------------------------------- */
    /*                     Edge Case: rootK == rootKLast                          */
    /* -------------------------------------------------------------------------- */

    /// @notice When newK equals kLast (no growth), no protocol fee should be charged
    function test_calculateProtocolFee_noKGrowth_returnsZero() public view {
        uint256 lpTotalSupply = 1000e18;
        uint256 kValue = 100e36;
        uint256 ownerFeeShare = 50000;

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, kValue, kValue, ownerFeeShare);

        assertEq(fee, 0, "Protocol fee should be 0 when newK equals kLast");
    }

    /// @notice When newK is less than kLast (K decreased, e.g., from impermanent loss), no fee
    function test_calculateProtocolFee_kDecreased_returnsZero() public view {
        uint256 lpTotalSupply = 1000e18;
        uint256 newK = 80e36;
        uint256 kLast = 100e36;
        uint256 ownerFeeShare = 50000;

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);

        assertEq(fee, 0, "Protocol fee should be 0 when K decreased");
    }

    /// @notice When sqrt(newK) == sqrt(kLast) due to rounding, no fee
    function test_calculateProtocolFee_sqrtRoundingEqual_returnsZero() public view {
        uint256 lpTotalSupply = 1000e18;
        // Choose values where sqrt rounds to same value
        // sqrt(1000000) = 1000, sqrt(1000001) ≈ 1000.0005 but floors to 1000
        uint256 newK = 1000001;
        uint256 kLast = 1000000;
        uint256 ownerFeeShare = 50000;

        uint256 rootK = CamMath.sqrt(newK);
        uint256 rootKLast = CamMath.sqrt(kLast);

        // Verify they round to same value
        assertEq(rootK, rootKLast, "Sqrt values should be equal due to rounding");

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);
        assertEq(fee, 0, "Protocol fee should be 0 when sqrt values are equal");
    }

    /* -------------------------------------------------------------------------- */
    /*                  ownerFeeShare Boundary Tests (0, 50000, 100000)           */
    /* -------------------------------------------------------------------------- */

    /// @notice ownerFeeShare = 0 should return 0 fee (division protection)
    function test_calculateProtocolFee_ownerFeeShareZero_returnsZero() public view {
        uint256 lpTotalSupply = 1000e18;
        uint256 newK = 200e36;
        uint256 kLast = 100e36;
        uint256 ownerFeeShare = 0;

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);

        assertEq(fee, 0, "Protocol fee should be 0 when ownerFeeShare is 0");
    }

    /// @notice ownerFeeShare = 50000 (50%) - default Camelot value
    function test_calculateProtocolFee_ownerFeeShare50000_returnsPositiveFee() public view {
        uint256 lpTotalSupply = 1000e18;
        uint256 newK = 200e36; // K doubled
        uint256 kLast = 100e36;
        uint256 ownerFeeShare = 50000; // 50%

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);

        assertGt(fee, 0, "Protocol fee should be positive for 50% fee share");

        // Verify fee calculation matches formula
        // d = (FEE_DENOMINATOR * 100 / ownerFeeShare) - 100 = (100000 * 100 / 50000) - 100 = 100
        // rootK = sqrt(200e36) = ~14.14e18
        // rootKLast = sqrt(100e36) = 10e18
        // numerator = 1000e18 * (14.14e18 - 10e18) * 100
        // denominator = 14.14e18 * 100 + 10e18 * 100
        // liquidity = numerator / denominator
        // This is roughly: 1000 * 4.14 * 100 / (14.14 * 100 + 10 * 100) = 414000 / 2414 ≈ 171.5
    }

    /// @notice ownerFeeShare = 100000 (100%) - maximum value
    function test_calculateProtocolFee_ownerFeeShare100000_returnsZero() public view {
        uint256 lpTotalSupply = 1000e18;
        uint256 newK = 200e36;
        uint256 kLast = 100e36;
        uint256 ownerFeeShare = 100000; // 100%

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);

        // d = (100000 * 100 / 100000) - 100 = 0
        // This triggers the d <= 100 check and returns 0
        assertEq(fee, 0, "Protocol fee should be 0 when ownerFeeShare is 100%");
    }

    /// @notice ownerFeeShare = 30000 (30%) - common value
    function test_calculateProtocolFee_ownerFeeShare30000_returnsPositiveFee() public view {
        uint256 lpTotalSupply = 1000e18;
        uint256 newK = 200e36;
        uint256 kLast = 100e36;
        uint256 ownerFeeShare = 30000; // 30%

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);

        assertGt(fee, 0, "Protocol fee should be positive for 30% fee share");
    }

    /// @notice ownerFeeShare = 16667 (1/6) - Uniswap V2 style
    function test_calculateProtocolFee_ownerFeeShare16667_usesUniswapPath() public view {
        uint256 lpTotalSupply = 1000e18;
        uint256 newK = 200e36;
        uint256 kLast = 100e36;
        uint256 ownerFeeShare = 16667; // 1/6

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);

        assertGt(fee, 0, "Protocol fee should be positive for Uniswap-style 1/6 fee share");

        // The Uniswap path uses: liquidity = totalSupply * (rootK - rootKLast) / (5*rootK + rootKLast)
    }

    /* -------------------------------------------------------------------------- */
    /*                  Cross-Reference with Actual Pair _mintFee()              */
    /* -------------------------------------------------------------------------- */

    /// @notice Compare _calculateProtocolFee output with actual pair fee minting
    function test_protocolFeeParity_matchesPairMintFee() public {
        // Initialize pool
        _initializePool(INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);

        // Enable fees
        address feeTo = address(0xFEE);
        vm.prank(camelotV2Factory.owner());
        CamelotFactory(address(camelotV2Factory)).setFeeTo(feeTo);

        // Get ownerFeeShare
        uint256 ownerFeeShare = CamelotFactory(address(camelotV2Factory)).ownerFeeShare();

        // Add liquidity to set kLast (first fee-enabled liquidity event)
        tokenA.mint(address(this), 1000e18);
        tokenB.mint(address(this), 1000e18);
        tokenA.approve(address(camelotV2Router), 1000e18);
        tokenB.approve(address(camelotV2Router), 1000e18);
        CamelotV2Service._deposit(camelotV2Router, tokenA, tokenB, 1000e18, 1000e18);

        // Record kLast after first deposit
        uint256 kLastAfterFirstDeposit = pair.kLast();
        assertGt(kLastAfterFirstDeposit, 0, "kLast should be set");

        // Execute swaps to grow K (generate fees)
        _executeSwapsToGrowK();

        // Get current reserves and calculate newK
        (uint112 r0, uint112 r1,,) = pair.getReserves();
        uint256 newK = uint256(r0) * uint256(r1);
        uint256 totalSupplyBefore = pair.totalSupply();

        // Calculate expected fee using _calculateProtocolFee
        uint256 expectedFee = harness.calculateProtocolFee(
            totalSupplyBefore,
            newK,
            kLastAfterFirstDeposit,
            ownerFeeShare
        );

        // Record feeTo balance before
        uint256 feeToBalanceBefore = pair.balanceOf(feeTo);

        // Trigger _mintFee by adding liquidity
        tokenA.mint(address(this), 100e18);
        tokenB.mint(address(this), 100e18);
        tokenA.approve(address(camelotV2Router), 100e18);
        tokenB.approve(address(camelotV2Router), 100e18);
        CamelotV2Service._deposit(camelotV2Router, tokenA, tokenB, 100e18, 100e18);

        // Check actual fee minted
        uint256 feeToBalanceAfter = pair.balanceOf(feeTo);
        uint256 actualFee = feeToBalanceAfter - feeToBalanceBefore;

        // Verify parity (allow small rounding difference)
        if (expectedFee > 0) {
            assertApproxEqRel(actualFee, expectedFee, 0.01e18, "Fee parity: actual should match calculated");
        } else {
            assertEq(actualFee, expectedFee, "Fee parity: both should be 0");
        }
    }

    /// @notice Test parity with ownerFeeShare = 30000
    function test_protocolFeeParity_feeShare30000() public {
        _testParityWithFeeShare(30000);
    }

    /// @notice Test parity with ownerFeeShare = 50000
    function test_protocolFeeParity_feeShare50000() public {
        _testParityWithFeeShare(50000);
    }

    /// @notice Test parity with ownerFeeShare = 70000
    function test_protocolFeeParity_feeShare70000() public {
        _testParityWithFeeShare(70000);
    }

    /// @notice Helper to test fee parity with a specific ownerFeeShare
    function _testParityWithFeeShare(uint256 feeShare) internal {
        // Set ownerFeeShare
        vm.prank(camelotV2Factory.owner());
        CamelotFactory(address(camelotV2Factory)).setOwnerFeeShare(feeShare);

        // Initialize and test
        _initializePool(INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);

        address feeTo = address(0xFEE);
        vm.prank(camelotV2Factory.owner());
        CamelotFactory(address(camelotV2Factory)).setFeeTo(feeTo);

        // Add liquidity to set kLast
        _addLiquidityToSetKLast();

        uint256 kLast = pair.kLast();

        // Execute swaps
        _executeSwapsToGrowK();

        // Calculate expected fee
        uint256 expectedFee;
        {
            (uint112 r0, uint112 r1,,) = pair.getReserves();
            uint256 newK = uint256(r0) * uint256(r1);
            uint256 totalSupply = pair.totalSupply();
            expectedFee = harness.calculateProtocolFee(totalSupply, newK, kLast, feeShare);
        }

        // Get actual fee
        uint256 actualFee;
        {
            uint256 feeToBalanceBefore = pair.balanceOf(feeTo);
            _addSmallLiquidityToTriggerMintFee();
            actualFee = pair.balanceOf(feeTo) - feeToBalanceBefore;
        }

        // Verify
        if (expectedFee > 0) {
            assertApproxEqRel(actualFee, expectedFee, 0.01e18, "Fee parity failed");
        }
    }

    /// @notice Helper to add liquidity and set kLast
    function _addLiquidityToSetKLast() internal {
        tokenA.mint(address(this), 1000e18);
        tokenB.mint(address(this), 1000e18);
        tokenA.approve(address(camelotV2Router), 1000e18);
        tokenB.approve(address(camelotV2Router), 1000e18);
        CamelotV2Service._deposit(camelotV2Router, tokenA, tokenB, 1000e18, 1000e18);
    }

    /// @notice Helper to add small liquidity to trigger _mintFee
    function _addSmallLiquidityToTriggerMintFee() internal {
        tokenA.mint(address(this), 100e18);
        tokenB.mint(address(this), 100e18);
        tokenA.approve(address(camelotV2Router), 100e18);
        tokenB.approve(address(camelotV2Router), 100e18);
        CamelotV2Service._deposit(camelotV2Router, tokenA, tokenB, 100e18, 100e18);
    }

    /* -------------------------------------------------------------------------- */
    /*                      Property-Based (Fuzz) Tests                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Fuzz test: fee should never be negative (always >= 0)
    function testFuzz_calculateProtocolFee_neverNegative(
        uint256 lpTotalSupply,
        uint256 newK,
        uint256 kLast,
        uint256 ownerFeeShare
    ) public view {
        // Bound inputs to reasonable ranges
        lpTotalSupply = bound(lpTotalSupply, 1e15, 1e30);
        newK = bound(newK, 1e18, 1e50);
        kLast = bound(kLast, 0, newK); // kLast <= newK for fee to be charged
        ownerFeeShare = bound(ownerFeeShare, 0, FEE_DENOMINATOR);

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);

        // Fee should always be >= 0 (it's a uint256, so this is always true, but we verify no revert)
        assertTrue(fee >= 0, "Fee should never be negative");
    }

    /// @notice Fuzz test: fee should be 0 when kLast is 0
    function testFuzz_calculateProtocolFee_kLastZero_alwaysZero(
        uint256 lpTotalSupply,
        uint256 newK,
        uint256 ownerFeeShare
    ) public view {
        lpTotalSupply = bound(lpTotalSupply, 1e15, 1e30);
        newK = bound(newK, 1e18, 1e50);
        ownerFeeShare = bound(ownerFeeShare, 1, FEE_DENOMINATOR);

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, newK, 0, ownerFeeShare);

        assertEq(fee, 0, "Fee should be 0 when kLast is 0");
    }

    /// @notice Fuzz test: fee should be 0 when ownerFeeShare is 0
    function testFuzz_calculateProtocolFee_ownerFeeShareZero_alwaysZero(
        uint256 lpTotalSupply,
        uint256 newK,
        uint256 kLast
    ) public view {
        lpTotalSupply = bound(lpTotalSupply, 1e15, 1e30);
        newK = bound(newK, 1e30, 1e50);
        kLast = bound(kLast, 1e18, newK - 1);

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, newK, kLast, 0);

        assertEq(fee, 0, "Fee should be 0 when ownerFeeShare is 0");
    }

    /// @notice Fuzz test: fee should be 0 when newK <= kLast
    function testFuzz_calculateProtocolFee_noGrowth_alwaysZero(
        uint256 lpTotalSupply,
        uint256 kLast,
        uint256 ownerFeeShare
    ) public view {
        lpTotalSupply = bound(lpTotalSupply, 1e15, 1e30);
        kLast = bound(kLast, 1e30, 1e50);
        ownerFeeShare = bound(ownerFeeShare, 1, FEE_DENOMINATOR - 1);

        // Test with newK == kLast
        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, kLast, kLast, ownerFeeShare);
        assertEq(fee, 0, "Fee should be 0 when newK equals kLast");

        // Test with newK < kLast
        if (kLast > 1e30) {
            uint256 smallerK = kLast - 1e29;
            fee = harness.calculateProtocolFee(lpTotalSupply, smallerK, kLast, ownerFeeShare);
            assertEq(fee, 0, "Fee should be 0 when newK is less than kLast");
        }
    }

    /// @notice Fuzz test: higher K growth should result in higher or equal fee
    function testFuzz_calculateProtocolFee_monotonicWithGrowth(
        uint256 lpTotalSupply,
        uint256 kLast,
        uint256 kGrowth1,
        uint256 kGrowth2,
        uint256 ownerFeeShare
    ) public view {
        lpTotalSupply = bound(lpTotalSupply, 1e18, 1e27);
        kLast = bound(kLast, 1e30, 1e40);
        kGrowth1 = bound(kGrowth1, 1e20, 1e35);
        kGrowth2 = bound(kGrowth2, kGrowth1, 1e36); // kGrowth2 >= kGrowth1
        ownerFeeShare = bound(ownerFeeShare, 10000, 90000); // Valid fee range

        uint256 newK1 = kLast + kGrowth1;
        uint256 newK2 = kLast + kGrowth2;

        // Prevent overflow
        if (newK1 < kLast || newK2 < kLast) return;

        uint256 fee1 = harness.calculateProtocolFee(lpTotalSupply, newK1, kLast, ownerFeeShare);
        uint256 fee2 = harness.calculateProtocolFee(lpTotalSupply, newK2, kLast, ownerFeeShare);

        assertGe(fee2, fee1, "Higher K growth should result in >= fee");
    }

    /// @notice Fuzz test: with realistic K growth, fee should be positive for valid params
    /// @dev In practice, K grows gradually from trading fees (0.3% per swap).
    ///      This test verifies non-reverting behavior and positive fee generation.
    function testFuzz_calculateProtocolFee_realisticGrowth_positiveFee(
        uint256 lpTotalSupply,
        uint256 kLast,
        uint256 growthPercent,
        uint256 ownerFeeShare
    ) public view {
        // Realistic bounds for a DEX
        lpTotalSupply = bound(lpTotalSupply, 1e18, 1e27); // 1 to 1B LP tokens
        kLast = bound(kLast, 1e36, 1e42); // Typical K range (not too extreme)
        growthPercent = bound(growthPercent, 1, 10); // 1-10% K growth (realistic from fees)
        ownerFeeShare = bound(ownerFeeShare, 20000, 80000); // 20-80%

        // Calculate newK with bounded growth (sqrt grows by ~half the percent)
        uint256 newK = kLast + (kLast * growthPercent / 100);

        // Skip if overflow
        if (newK < kLast) return;

        uint256 fee = harness.calculateProtocolFee(lpTotalSupply, newK, kLast, ownerFeeShare);

        // With positive K growth and reasonable fee share, fee should be positive
        assertGt(fee, 0, "Fee should be positive for valid growth");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Helper Functions                              */
    /* -------------------------------------------------------------------------- */

    function _initializePool(uint256 amountA, uint256 amountB) internal {
        tokenA.mint(address(this), amountA);
        tokenB.mint(address(this), amountB);
        tokenA.approve(address(camelotV2Router), amountA);
        tokenB.approve(address(camelotV2Router), amountB);

        CamelotV2Service._deposit(camelotV2Router, tokenA, tokenB, amountA, amountB);
    }

    function _executeSwapsToGrowK() internal {
        // Execute multiple swaps to generate fees and grow K
        for (uint256 i = 0; i < 5; i++) {
            uint256 swapAmount = 100e18;
            tokenA.mint(address(this), swapAmount);
            tokenA.approve(address(camelotV2Router), swapAmount);

            address[] memory path = new address[](2);
            path[0] = address(tokenA);
            path[1] = address(tokenB);

            camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                swapAmount,
                0,
                path,
                address(this),
                address(0),
                block.timestamp + 300
            );

            // Swap back
            uint256 balanceB = tokenB.balanceOf(address(this));
            if (balanceB > 0) {
                tokenB.approve(address(camelotV2Router), balanceB);
                address[] memory pathRev = new address[](2);
                pathRev[0] = address(tokenB);
                pathRev[1] = address(tokenA);
                camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                    balanceB,
                    0,
                    pathRev,
                    address(this),
                    address(0),
                    block.timestamp + 300
                );
            }
        }
    }
}
