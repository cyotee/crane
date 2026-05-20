// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/old_tests/StakingRewardsDualV5-Tests.js` (local mocks)

import {Test} from "forge-std/Test.sol";
import {StakingRewardsDualV5} from
    "@crane/contracts/protocols/tokens/stable/frax/Staking/StakingRewardsDualV5.sol";
import {MintableERC20} from "@crane/contracts/protocols/tokens/stable/frax/mocks/MintableERC20.sol";
import {MockVeFXS} from "@crane/contracts/protocols/tokens/stable/frax/mocks/MockVeFXS.sol";
import {MockUniswapV2Pair} from "@crane/contracts/protocols/tokens/stable/frax/mocks/MockUniswapV2Pair.sol";

contract StakingRewardsDualV5_Test is Test {
    uint256 internal constant WEEK = 7 days;
    uint256 internal constant LP_STAKE = 7.5e18;
    uint256 internal constant REWARD_RATE0 = 10e18 / WEEK;

    address internal timelock;
    address internal staker1;
    address internal staker2;

    MintableERC20 internal frax;
    MintableERC20 internal reward0;
    MintableERC20 internal reward1;
    MockUniswapV2Pair internal lp;
    MockVeFXS internal veFXS;
    StakingRewardsDualV5 internal farm;

    function setUp() public {
        timelock = makeAddr("timelock");
        staker1 = makeAddr("staker1");
        staker2 = makeAddr("staker2");

        frax = new MintableERC20("FRAX", "FRAX");
        reward0 = new MintableERC20("FXS", "FXS");
        reward1 = new MintableERC20("IQ", "IQ");
        lp = new MockUniswapV2Pair(address(frax), address(reward1), 1_000_000e18, 1_000_000e18);
        veFXS = new MockVeFXS();

        farm = new StakingRewardsDualV5(
            address(this),
            address(reward0),
            address(reward1),
            address(lp),
            address(frax),
            timelock,
            address(veFXS)
        );

        farm.toggleToken1Rewards();
        farm.setRewardRates(REWARD_RATE0, 0, false);

        reward0.mint(address(farm), 1_000_000e18);
        lp.mint(staker1, 100e18);
        lp.mint(staker2, 100e18);

        veFXS.configure(staker1, 0.1e18, block.timestamp + 4 * 365 days);
    }

    function test_Deploy_initialState() public view {
        assertEq(farm.owner(), address(this));
        assertEq(farm.timelock_address(), timelock);
        assertGt(farm.fraxPerLPToken(), 0);
        assertEq(farm.rewardsDuration(), WEEK);
        assertFalse(farm.token1_rewards_on());
    }

    function test_lockMultiplier_scalesWithDuration() public view {
        uint256 oneDay = farm.lockMultiplier(1 days);
        uint256 threeYears = farm.lockMultiplier(3 * 365 days);
        assertGt(threeYears, oneDay);
        assertLe(threeYears, farm.lock_max_multiplier());
    }

    function test_stakeLocked_tracksLiquidityAndWeight() public {
        vm.startPrank(staker1);
        lp.approve(address(farm), LP_STAKE);
        farm.stakeLocked(LP_STAKE, 7 days);
        vm.stopPrank();

        assertEq(farm.lockedLiquidityOf(staker1), LP_STAKE);
        assertEq(farm.totalLiquidityLocked(), LP_STAKE);
        assertGt(farm.combinedWeightOf(staker1), LP_STAKE);
        assertEq(farm.lockedStakesOf(staker1).length, 1);
    }

    function test_withdrawLocked_reverts_beforeUnlock() public {
        vm.startPrank(staker1);
        lp.approve(address(farm), LP_STAKE);
        farm.stakeLocked(LP_STAKE, 7 days);
        bytes32 kekId = farm.lockedStakesOf(staker1)[0].kek_id;
        vm.expectRevert("Stake is still locked!");
        farm.withdrawLocked(kekId);
        vm.stopPrank();
    }

    function test_withdrawLocked_returnsLpAfterLockExpires() public {
        vm.startPrank(staker1);
        lp.approve(address(farm), LP_STAKE);
        farm.stakeLocked(LP_STAKE, 7 days);
        bytes32 kekId = farm.lockedStakesOf(staker1)[0].kek_id;
        vm.stopPrank();

        vm.warp(block.timestamp + 7 days + 1);

        uint256 balBefore = lp.balanceOf(staker1);
        vm.prank(staker1);
        farm.withdrawLocked(kekId);

        assertEq(lp.balanceOf(staker1), balBefore + LP_STAKE);
        assertEq(farm.lockedLiquidityOf(staker1), 0);
    }

    function test_getReward_accruesToken0OverWeek() public {
        vm.startPrank(staker1);
        lp.approve(address(farm), LP_STAKE);
        farm.stakeLocked(LP_STAKE, 7 days);
        vm.stopPrank();

        vm.warp(block.timestamp + WEEK + 1);
        farm.sync();

        uint256 balBefore = reward0.balanceOf(staker1);
        vm.prank(staker1);
        (uint256 paid0,) = farm.getReward();

        assertGt(paid0, 0);
        assertEq(reward0.balanceOf(staker1), balBefore + paid0);
    }

    function test_greylist_blocksStake() public {
        farm.greylistAddress(staker2);

        vm.startPrank(staker2);
        lp.approve(address(farm), LP_STAKE);
        vm.expectRevert("Address has been greylisted");
        farm.stakeLocked(LP_STAKE, 7 days);
        vm.stopPrank();
    }
}