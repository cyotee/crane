// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/veFXSYieldDistributorV4-Tests.js` (local mock veFXS)

import {Test} from "forge-std/Test.sol";
import {veFXSYieldDistributorV4} from
    "@crane/contracts/protocols/tokens/stable/frax/Staking/veFXSYieldDistributorV4.sol";
import {MintableERC20} from "@crane/contracts/protocols/tokens/stable/frax/mocks/MintableERC20.sol";
import {MockVeFXS} from "@crane/contracts/protocols/tokens/stable/frax/mocks/MockVeFXS.sol";

contract veFXSYieldDistributorV4_Test is Test {
    uint256 internal constant WEEK = 7 days;
    uint256 internal constant STAKER1_VEFXS = 200_000e18;
    uint256 internal constant STAKER2_VEFXS = 1_250e18;
    uint256 internal constant NOTIFY_HALF = 3.5e18;

    address internal timelock;
    address internal notifier;
    address internal staker1;
    address internal staker2;

    MintableERC20 internal rewardToken;
    MockVeFXS internal veFXS;
    veFXSYieldDistributorV4 internal distributor;

    function setUp() public {
        timelock = makeAddr("timelock");
        notifier = makeAddr("notifier");
        staker1 = makeAddr("staker1");
        staker2 = makeAddr("staker2");

        rewardToken = new MintableERC20("FXS", "FXS");
        veFXS = new MockVeFXS();

        uint256 lockEnd = block.timestamp + (4 * 365 days);
        veFXS.configure(staker1, STAKER1_VEFXS, lockEnd);
        veFXS.configure(staker2, STAKER2_VEFXS, lockEnd);

        distributor = new veFXSYieldDistributorV4(address(this), address(rewardToken), timelock, address(veFXS));

        distributor.toggleRewardNotifier(notifier);
        rewardToken.mint(notifier, 1_000_000e18);
    }

    function _notifyTwoHalves() internal {
        vm.startPrank(notifier);
        rewardToken.approve(address(distributor), NOTIFY_HALF * 2);
        distributor.notifyRewardAmount(NOTIFY_HALF);
        distributor.notifyRewardAmount(NOTIFY_HALF);
        vm.stopPrank();
    }

    function test_Deploy_initialState() public view {
        assertEq(distributor.owner(), address(this));
        assertEq(distributor.emitted_token_address(), address(rewardToken));
        assertEq(distributor.timelock_address(), timelock);
        assertEq(distributor.yieldDuration(), WEEK);
        assertTrue(distributor.reward_notifiers(address(this)));
    }

    function test_notifyRewardAmount_reverts_non_notifier() public {
        address stranger = makeAddr("stranger");
        vm.prank(stranger);
        vm.expectRevert("Sender not whitelisted");
        distributor.notifyRewardAmount(NOTIFY_HALF);
    }

    function test_initialization_notifyDoublesWeeklyRate() public {
        _notifyTwoHalves();
        assertApproxEqRel(distributor.getYieldForDuration(), NOTIFY_HALF * 2, 1e12);
    }

    function test_normalYield_weeklyEmissionWithinBounds() public {
        _notifyTwoHalves();

        vm.prank(staker1);
        distributor.getYield();
        vm.prank(staker2);
        distributor.getYield();

        assertEq(distributor.earned(staker1), 0);
        assertEq(distributor.earned(staker2), 0);

        vm.warp(block.timestamp + WEEK + 1);
        distributor.sync();

        vm.prank(staker1);
        distributor.checkpoint();
        vm.prank(staker2);
        distributor.checkpoint();

        uint256 earned1 = distributor.earned(staker1);
        uint256 earned2 = distributor.earned(staker2);
        uint256 totalEarned = earned1 + earned2;

        uint256 durationYield = distributor.getYieldForDuration();
        uint256 fraction = distributor.fractionParticipating();
        uint256 expected = (durationYield * fraction) / 1e6;

        assertGe(totalEarned, (expected * 99) / 100, "under-emission");
        assertLe(totalEarned, (expected * 101) / 100, "over-emission");

        uint256 balBefore = rewardToken.balanceOf(staker1);
        vm.prank(staker1);
        distributor.getYield();
        assertGt(rewardToken.balanceOf(staker1), balBefore);
    }

    function test_greylist_blocks_getYield() public {
        _notifyTwoHalves();
        vm.warp(block.timestamp + WEEK + 1);

        distributor.greylistAddress(staker1);

        vm.prank(staker1);
        vm.expectRevert("Address has been greylisted");
        distributor.getYield();
    }

    function test_ungreylist_allows_getYield() public {
        _notifyTwoHalves();
        vm.warp(block.timestamp + WEEK + 1);

        distributor.greylistAddress(staker1);
        distributor.greylistAddress(staker1);

        vm.prank(staker1);
        distributor.checkpoint();
        distributor.getYield();
    }

    /// @dev Port of upstream second-week notify + staker2 carryover claim.
    function test_secondWeek_notify_staker2ClaimsCarryover() public {
        _notifyTwoHalves();

        vm.prank(staker1);
        distributor.getYield();
        vm.prank(staker2);
        distributor.getYield();

        vm.warp(block.timestamp + WEEK + 1);
        distributor.sync();
        vm.prank(staker1);
        distributor.checkpoint();
        vm.prank(staker2);
        distributor.checkpoint();

        uint256 staker2Week1Earned = distributor.earned(staker2);

        vm.startPrank(notifier);
        rewardToken.approve(address(distributor), 70e18);
        distributor.notifyRewardAmount(70e18);
        vm.stopPrank();

        vm.warp(block.timestamp + 2 * WEEK + 1);
        distributor.sync();
        vm.prank(staker1);
        distributor.checkpoint();
        vm.prank(staker2);
        distributor.checkpoint();

        assertGt(distributor.earned(staker2), staker2Week1Earned);

        uint256 balBefore = rewardToken.balanceOf(staker2);
        vm.prank(staker2);
        distributor.getYield();
        assertGt(rewardToken.balanceOf(staker2), balBefore);
    }

    /// @dev Port of upstream: no yield accrues after veFXS lock expires.
    function test_expiredVeFXS_earnedZeroAfterLockEnd() public {
        _notifyTwoHalves();

        uint256 shortLockEnd = block.timestamp + 14 days;
        veFXS.configure(staker1, STAKER1_VEFXS, shortLockEnd);

        vm.warp(block.timestamp + WEEK + 1);
        vm.prank(staker1);
        distributor.checkpoint();

        vm.warp(shortLockEnd + 1 days);
        vm.prank(staker1);
        distributor.checkpoint();

        assertEq(distributor.earned(staker1), 0);

        vm.prank(staker1);
        distributor.getYield();
        assertEq(rewardToken.balanceOf(staker1), 0);
    }

    function test_setPauses_blocksYieldCollection() public {
        _notifyTwoHalves();
        vm.warp(block.timestamp + WEEK + 1);

        distributor.setPauses(true);

        vm.prank(staker1);
        vm.expectRevert("Yield collection is paused");
        distributor.getYield();
    }
}