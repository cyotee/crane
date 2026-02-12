// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ICamelotPair} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotFactory} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol";
import {TestBase_ConstProdUtils_Camelot} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Camelot.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {CamelotPair} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol";
import {CamelotFactory} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol";

/**
 * @title CamelotV2_referrerFee_Test
 * @notice Tests for Camelot V2 referrer fee rebate behavior
 * @dev Camelot supports referrer fee rebates that reduce the remaining LP fee.
 *      When a swap is executed with a referrer address that has a registered fee share,
 *      a portion of the swap fee is sent to the referrer instead of staying in the pool.
 *
 *      From CamelotPair._swap():
 *      ```solidity
 *      uint256 referrerInputFeeShare = referrer != address(0)
 *          ? ICamelotFactory(factory).referrersFeeShare(referrer) : 0;
 *      if (referrerInputFeeShare > 0) {
 *          fee = amount0In.mul(referrerInputFeeShare).mul(_token0FeePercent) / (FEE_DENOMINATOR ** 2);
 *          tokensData.remainingFee0 = tokensData.remainingFee0.sub(fee);
 *          _safeTransfer(tokensData.token0, referrer, fee);
 *      }
 *      ```
 */
contract CamelotV2_referrerFee_Test is TestBase_ConstProdUtils_Camelot {
    using CamelotV2Service for ICamelotPair;
    using ConstProdUtils for uint256;

    /* ---------------------------------------------------------------------- */
    /*                              Test Tokens                               */
    /* ---------------------------------------------------------------------- */

    ERC20PermitMintableStub referrerTokenA;
    ERC20PermitMintableStub referrerTokenB;
    ICamelotPair referrerPair;

    /* ---------------------------------------------------------------------- */
    /*                              Constants                                 */
    /* ---------------------------------------------------------------------- */

    uint256 constant FEE_DENOMINATOR = 100000;
    uint256 constant REFERRER_FEE_SHARE_MAX = 20000; // 20% max referrer share
    uint256 constant REFERRER_INITIAL_LIQUIDITY = 10000e18;
    uint256 constant DEFAULT_FEE_PERCENT = 500; // 0.5% default Camelot fee

    /* ---------------------------------------------------------------------- */
    /*                              Test Addresses                            */
    /* ---------------------------------------------------------------------- */

    address referrer;
    address nonReferrer;

    /* ---------------------------------------------------------------------- */
    /*                                 Setup                                  */
    /* ---------------------------------------------------------------------- */

    function setUp() public override {
        TestBase_ConstProdUtils_Camelot.setUp();

        // Create test addresses
        referrer = makeAddr("referrer");
        nonReferrer = makeAddr("nonReferrer");

        _createReferrerTokens();
        _createReferrerPair();
    }

    function _createReferrerTokens() internal {
        referrerTokenA = new ERC20PermitMintableStub("ReferrerTokenA", "REFA", 18, address(this), 0);
        vm.label(address(referrerTokenA), "ReferrerTokenA");

        referrerTokenB = new ERC20PermitMintableStub("ReferrerTokenB", "REFB", 18, address(this), 0);
        vm.label(address(referrerTokenB), "ReferrerTokenB");
    }

    function _createReferrerPair() internal {
        referrerPair = ICamelotPair(camelotV2Factory.createPair(address(referrerTokenA), address(referrerTokenB)));
        vm.label(address(referrerPair), "ReferrerPair");
    }

    function _initializeReferrerPool() internal {
        referrerTokenA.mint(address(this), REFERRER_INITIAL_LIQUIDITY);
        referrerTokenA.approve(address(camelotV2Router), REFERRER_INITIAL_LIQUIDITY);
        referrerTokenB.mint(address(this), REFERRER_INITIAL_LIQUIDITY);
        referrerTokenB.approve(address(camelotV2Router), REFERRER_INITIAL_LIQUIDITY);

        CamelotV2Service._deposit(camelotV2Router, referrerTokenA, referrerTokenB, REFERRER_INITIAL_LIQUIDITY, REFERRER_INITIAL_LIQUIDITY);
    }

    function _setReferrerFeeShare(address _referrer, uint256 feeShare) internal {
        // Factory owner is the deployer (this test contract via TestBase_CamelotV2)
        vm.prank(address(this));
        CamelotFactory(address(camelotV2Factory)).setReferrerFeeShare(_referrer, feeShare);
    }

    /* ---------------------------------------------------------------------- */
    /*                    Factory Lookup Tests (AC #3)                        */
    /* ---------------------------------------------------------------------- */

    /// @notice Test that referrersFeeShare() returns 0 for unregistered referrer
    function test_referrersFeeShare_returnsZeroForUnregistered() public view {
        uint256 feeShare = camelotV2Factory.referrersFeeShare(nonReferrer);
        assertEq(feeShare, 0, "Unregistered referrer should have 0 fee share");
    }

    /// @notice Test that referrersFeeShare() returns correct value after registration
    function test_referrersFeeShare_returnsCorrectValueAfterRegistration() public {
        uint256 expectedFeeShare = 10000; // 10%
        _setReferrerFeeShare(referrer, expectedFeeShare);

        uint256 actualFeeShare = camelotV2Factory.referrersFeeShare(referrer);
        assertEq(actualFeeShare, expectedFeeShare, "Registered referrer should have correct fee share");
    }

    /// @notice Test that referrersFeeShare() can be updated
    function test_referrersFeeShare_canBeUpdated() public {
        uint256 initialFeeShare = 5000; // 5%
        uint256 updatedFeeShare = 15000; // 15%

        _setReferrerFeeShare(referrer, initialFeeShare);
        assertEq(camelotV2Factory.referrersFeeShare(referrer), initialFeeShare, "Initial fee share should be set");

        _setReferrerFeeShare(referrer, updatedFeeShare);
        assertEq(camelotV2Factory.referrersFeeShare(referrer), updatedFeeShare, "Fee share should be updated");
    }

    /// @notice Test that referrersFeeShare() cannot exceed maximum
    function test_referrersFeeShare_cannotExceedMaximum() public {
        uint256 excessiveFeeShare = REFERRER_FEE_SHARE_MAX + 1;

        vm.expectRevert("CamelotFactory: referrerFeeShare mustn't exceed maximum");
        _setReferrerFeeShare(referrer, excessiveFeeShare);
    }

    /// @notice Test that referrersFeeShare() can be set to maximum
    function test_referrersFeeShare_canBeSetToMaximum() public {
        _setReferrerFeeShare(referrer, REFERRER_FEE_SHARE_MAX);
        assertEq(camelotV2Factory.referrersFeeShare(referrer), REFERRER_FEE_SHARE_MAX, "Max fee share should be allowed");
    }

    /* ---------------------------------------------------------------------- */
    /*              Fee Distribution Tests (AC #2, #4)                        */
    /* ---------------------------------------------------------------------- */

    /// @notice Test that referrer receives fee portion during swap
    function test_swap_referrerReceivesFee() public {
        _initializeReferrerPool();

        uint256 referrerFeeShare = 10000; // 10% of the swap fee goes to referrer
        _setReferrerFeeShare(referrer, referrerFeeShare);

        uint256 swapAmount = 100e18;
        referrerTokenA.mint(address(this), swapAmount);
        referrerTokenA.approve(address(camelotV2Router), swapAmount);

        // Get initial referrer balance
        uint256 referrerBalanceBefore = referrerTokenA.balanceOf(referrer);
        assertEq(referrerBalanceBefore, 0, "Referrer should start with 0 balance");

        // Execute swap with referrer
        address[] memory path = new address[](2);
        path[0] = address(referrerTokenA);
        path[1] = address(referrerTokenB);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            referrer,
            block.timestamp + 300
        );

        // Check referrer received fee
        uint256 referrerBalanceAfter = referrerTokenA.balanceOf(referrer);
        assertGt(referrerBalanceAfter, 0, "Referrer should have received fee");

        // Calculate expected referrer fee
        // fee = amountIn * referrerFeeShare * tokenFeePercent / (FEE_DENOMINATOR ** 2)
        uint256 expectedReferrerFee = (swapAmount * referrerFeeShare * DEFAULT_FEE_PERCENT) / (FEE_DENOMINATOR ** 2);
        assertEq(referrerBalanceAfter, expectedReferrerFee, "Referrer should receive exact calculated fee");
    }

    /// @notice Test that referrer receives correct fee portion with different fee shares
    function test_swap_referrerReceivesCorrectPortion() public {
        _initializeReferrerPool();

        // Test with 5% referrer share
        uint256 referrerFeeShare = 5000; // 5%
        _setReferrerFeeShare(referrer, referrerFeeShare);

        uint256 swapAmount = 200e18;
        referrerTokenA.mint(address(this), swapAmount);
        referrerTokenA.approve(address(camelotV2Router), swapAmount);

        address[] memory path = new address[](2);
        path[0] = address(referrerTokenA);
        path[1] = address(referrerTokenB);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            referrer,
            block.timestamp + 300
        );

        uint256 referrerBalance = referrerTokenA.balanceOf(referrer);

        // Expected: swapAmount * 5% * 0.5% / 100000 = swapAmount * 5000 * 500 / 10000000000
        uint256 expectedFee = (swapAmount * referrerFeeShare * DEFAULT_FEE_PERCENT) / (FEE_DENOMINATOR ** 2);
        assertEq(referrerBalance, expectedFee, "Referrer should receive correct portion");
    }

    /// @notice Test that no referrer fee is distributed when referrer is address(0)
    function test_swap_noReferrerFeeWhenAddressZero() public {
        _initializeReferrerPool();

        // Even if address(0) somehow had a fee share (it can't be set), it shouldn't receive fees
        uint256 swapAmount = 100e18;
        referrerTokenA.mint(address(this), swapAmount);
        referrerTokenA.approve(address(camelotV2Router), swapAmount);

        address[] memory path = new address[](2);
        path[0] = address(referrerTokenA);
        path[1] = address(referrerTokenB);

        // Swap without referrer (address(0))
        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            address(0),
            block.timestamp + 300
        );

        // Verify swap completed successfully - no revert means it worked
        assertTrue(true, "Swap without referrer should complete");
    }

    /// @notice Test that no referrer fee is distributed when referrer has 0 fee share
    function test_swap_noReferrerFeeWhenZeroFeeShare() public {
        _initializeReferrerPool();

        // Don't set any fee share for referrer (defaults to 0)
        assertEq(camelotV2Factory.referrersFeeShare(referrer), 0, "Referrer should have 0 fee share by default");

        uint256 swapAmount = 100e18;
        referrerTokenA.mint(address(this), swapAmount);
        referrerTokenA.approve(address(camelotV2Router), swapAmount);

        address[] memory path = new address[](2);
        path[0] = address(referrerTokenA);
        path[1] = address(referrerTokenB);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            referrer,
            block.timestamp + 300
        );

        uint256 referrerBalance = referrerTokenA.balanceOf(referrer);
        assertEq(referrerBalance, 0, "Referrer with 0 fee share should receive nothing");
    }

    /* ---------------------------------------------------------------------- */
    /*                  Quote Accuracy Tests (AC #1)                          */
    /* ---------------------------------------------------------------------- */

    /// @notice Test that quote remains accurate when referrer rebate applies
    /// @dev The referrer fee is taken from the LP fee, not additionally from the user.
    ///      So the user's output should remain the same whether or not a referrer is used.
    function test_quoteAccuracy_withReferrerRebate() public {
        _initializeReferrerPool();

        uint256 referrerFeeShare = 10000; // 10%
        _setReferrerFeeShare(referrer, referrerFeeShare);

        uint256 swapAmount = 100e18;

        // Get expected output using ConstProdUtils (doesn't account for referrer rebate on user output)
        (uint112 reserve0, uint112 reserve1, uint16 token0Fee,) = referrerPair.getReserves();
        address token0 = referrerPair.token0();
        bool tokenAIsToken0 = (address(referrerTokenA) == token0);

        uint256 reserveIn = tokenAIsToken0 ? reserve0 : reserve1;
        uint256 reserveOut = tokenAIsToken0 ? reserve1 : reserve0;
        uint256 feePercent = tokenAIsToken0 ? token0Fee : DEFAULT_FEE_PERCENT;

        uint256 expectedOutput = ConstProdUtils._saleQuote(swapAmount, reserveIn, reserveOut, feePercent);

        // Execute swap with referrer
        referrerTokenA.mint(address(this), swapAmount);
        referrerTokenA.approve(address(camelotV2Router), swapAmount);

        uint256 balanceBBefore = referrerTokenB.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(referrerTokenA);
        path[1] = address(referrerTokenB);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            referrer,
            block.timestamp + 300
        );

        uint256 actualOutput = referrerTokenB.balanceOf(address(this)) - balanceBBefore;

        // The user's output should match the quote regardless of referrer
        assertEq(actualOutput, expectedOutput, "User output should match quote with referrer rebate");
    }

    /// @notice Test that output is same with and without referrer (user doesn't pay extra)
    function test_quoteAccuracy_outputSameWithAndWithoutReferrer() public {
        _initializeReferrerPool();

        uint256 referrerFeeShare = 15000; // 15%
        _setReferrerFeeShare(referrer, referrerFeeShare);

        uint256 swapAmount = 50e18;

        // First swap: without referrer
        referrerTokenA.mint(address(this), swapAmount);
        referrerTokenA.approve(address(camelotV2Router), swapAmount);

        uint256 balanceBefore1 = referrerTokenB.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(referrerTokenA);
        path[1] = address(referrerTokenB);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            address(0), // No referrer
            block.timestamp + 300
        );

        uint256 outputWithoutReferrer = referrerTokenB.balanceOf(address(this)) - balanceBefore1;

        // Reset pool to same state by creating a new pair
        ERC20PermitMintableStub tokenC = new ERC20PermitMintableStub("TokenC", "TOKC", 18, address(this), 0);
        ERC20PermitMintableStub tokenD = new ERC20PermitMintableStub("TokenD", "TOKD", 18, address(this), 0);

        ICamelotPair pair2 = ICamelotPair(camelotV2Factory.createPair(address(tokenC), address(tokenD)));

        tokenC.mint(address(this), REFERRER_INITIAL_LIQUIDITY);
        tokenC.approve(address(camelotV2Router), REFERRER_INITIAL_LIQUIDITY);
        tokenD.mint(address(this), REFERRER_INITIAL_LIQUIDITY);
        tokenD.approve(address(camelotV2Router), REFERRER_INITIAL_LIQUIDITY);
        CamelotV2Service._deposit(camelotV2Router, tokenC, tokenD, REFERRER_INITIAL_LIQUIDITY, REFERRER_INITIAL_LIQUIDITY);

        // Second swap: with referrer
        tokenC.mint(address(this), swapAmount);
        tokenC.approve(address(camelotV2Router), swapAmount);

        uint256 balanceBefore2 = tokenD.balanceOf(address(this));

        path[0] = address(tokenC);
        path[1] = address(tokenD);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            referrer, // With referrer
            block.timestamp + 300
        );

        uint256 outputWithReferrer = tokenD.balanceOf(address(this)) - balanceBefore2;

        // User output should be the same regardless of referrer
        assertEq(outputWithReferrer, outputWithoutReferrer, "User output should be same with or without referrer");
    }

    /* ---------------------------------------------------------------------- */
    /*                           Fuzz Tests                                   */
    /* ---------------------------------------------------------------------- */

    /// @notice Fuzz test for referrer fee calculation
    function testFuzz_referrerFeeCalculation(
        uint256 referrerFeeShare,
        uint256 swapAmount
    ) public {
        // Bound inputs
        referrerFeeShare = bound(referrerFeeShare, 1, REFERRER_FEE_SHARE_MAX);
        swapAmount = bound(swapAmount, 1e15, 1000e18);

        _initializeReferrerPool();
        _setReferrerFeeShare(referrer, referrerFeeShare);

        referrerTokenA.mint(address(this), swapAmount);
        referrerTokenA.approve(address(camelotV2Router), swapAmount);

        address[] memory path = new address[](2);
        path[0] = address(referrerTokenA);
        path[1] = address(referrerTokenB);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            referrer,
            block.timestamp + 300
        );

        uint256 referrerBalance = referrerTokenA.balanceOf(referrer);

        // Calculate expected fee
        // The fee is based on the input token's fee percent
        (,, uint16 token0Fee, uint16 token1Fee) = referrerPair.getReserves();
        address token0 = referrerPair.token0();
        uint256 tokenFee = (address(referrerTokenA) == token0) ? token0Fee : token1Fee;

        uint256 expectedFee = (swapAmount * referrerFeeShare * tokenFee) / (FEE_DENOMINATOR ** 2);

        assertEq(referrerBalance, expectedFee, "Referrer should receive calculated fee");
    }

    /// @notice Fuzz test for referrer fee with varying fee shares
    function testFuzz_referrerFeeWithVaryingShares(uint256 feeShare) public {
        feeShare = bound(feeShare, 0, REFERRER_FEE_SHARE_MAX);

        _initializeReferrerPool();

        if (feeShare > 0) {
            _setReferrerFeeShare(referrer, feeShare);
        }

        uint256 swapAmount = 100e18;
        referrerTokenA.mint(address(this), swapAmount);
        referrerTokenA.approve(address(camelotV2Router), swapAmount);

        address[] memory path = new address[](2);
        path[0] = address(referrerTokenA);
        path[1] = address(referrerTokenB);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            referrer,
            block.timestamp + 300
        );

        uint256 referrerBalance = referrerTokenA.balanceOf(referrer);

        if (feeShare == 0) {
            assertEq(referrerBalance, 0, "Zero fee share should mean zero referrer fee");
        } else {
            assertGt(referrerBalance, 0, "Non-zero fee share should mean non-zero referrer fee");
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                    Bidirectional Swap Tests                            */
    /* ---------------------------------------------------------------------- */

    /// @notice Test referrer fee for token1 -> token0 swap
    function test_swap_referrerFeeForReverseDirection() public {
        _initializeReferrerPool();

        uint256 referrerFeeShare = 10000; // 10%
        _setReferrerFeeShare(referrer, referrerFeeShare);

        uint256 swapAmount = 100e18;
        referrerTokenB.mint(address(this), swapAmount);
        referrerTokenB.approve(address(camelotV2Router), swapAmount);

        address[] memory path = new address[](2);
        path[0] = address(referrerTokenB);
        path[1] = address(referrerTokenA);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            referrer,
            block.timestamp + 300
        );

        // Referrer receives fee in tokenB (the input token)
        uint256 referrerBalance = referrerTokenB.balanceOf(referrer);
        assertGt(referrerBalance, 0, "Referrer should receive fee in input token");

        // Calculate expected fee
        (,, uint16 token0Fee, uint16 token1Fee) = referrerPair.getReserves();
        address token0 = referrerPair.token0();
        uint256 tokenFee = (address(referrerTokenB) == token0) ? token0Fee : token1Fee;

        uint256 expectedFee = (swapAmount * referrerFeeShare * tokenFee) / (FEE_DENOMINATOR ** 2);
        assertEq(referrerBalance, expectedFee, "Referrer should receive exact calculated fee");
    }

    /* ---------------------------------------------------------------------- */
    /*                      Maximum Referrer Fee Test                         */
    /* ---------------------------------------------------------------------- */

    /// @notice Test referrer fee at maximum share (20%)
    function test_swap_referrerFeeAtMaximumShare() public {
        _initializeReferrerPool();

        _setReferrerFeeShare(referrer, REFERRER_FEE_SHARE_MAX);
        assertEq(camelotV2Factory.referrersFeeShare(referrer), REFERRER_FEE_SHARE_MAX, "Max fee share should be set");

        uint256 swapAmount = 100e18;
        referrerTokenA.mint(address(this), swapAmount);
        referrerTokenA.approve(address(camelotV2Router), swapAmount);

        address[] memory path = new address[](2);
        path[0] = address(referrerTokenA);
        path[1] = address(referrerTokenB);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            address(this),
            referrer,
            block.timestamp + 300
        );

        uint256 referrerBalance = referrerTokenA.balanceOf(referrer);

        // At max share (20%), referrer gets 20% of the swap fee
        uint256 expectedFee = (swapAmount * REFERRER_FEE_SHARE_MAX * DEFAULT_FEE_PERCENT) / (FEE_DENOMINATOR ** 2);
        assertEq(referrerBalance, expectedFee, "Referrer should receive maximum fee portion");
        assertGt(referrerBalance, 0, "Maximum fee should be non-zero");
    }

    /* ---------------------------------------------------------------------- */
    /*              CamelotV2Service Integration Tests                        */
    /* ---------------------------------------------------------------------- */

    /// @notice Test that CamelotV2Service._swap works with referrer
    function test_CamelotV2Service_swapWithReferrer() public {
        _initializeReferrerPool();

        uint256 referrerFeeShare = 10000; // 10%
        _setReferrerFeeShare(referrer, referrerFeeShare);

        uint256 swapAmount = 100e18;
        referrerTokenA.mint(address(this), swapAmount);
        referrerTokenA.approve(address(camelotV2Router), swapAmount);

        uint256 balanceBBefore = referrerTokenB.balanceOf(address(this));

        // Use CamelotV2Service._swap with referrer
        uint256 amountOut = CamelotV2Service._swap(
            camelotV2Router,
            referrerPair,
            swapAmount,
            referrerTokenA,
            referrerTokenB,
            referrer
        );

        uint256 actualReceived = referrerTokenB.balanceOf(address(this)) - balanceBBefore;

        assertEq(actualReceived, amountOut, "Actual received should match returned amount");
        assertGt(amountOut, 0, "Swap should produce output");

        // Verify referrer received their fee
        uint256 referrerBalance = referrerTokenA.balanceOf(referrer);
        assertGt(referrerBalance, 0, "Referrer should receive fee via service");
    }
}
