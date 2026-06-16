// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/old_tests/CommunalFarm-Tests.js` (local mocks)

import {Test} from "forge-std/Test.sol";
import {CommunalFarm} from "@crane/contracts/protocols/tokens/stable/frax/Staking/CommunalFarm.sol";
import {MintableERC20} from "@crane/contracts/protocols/tokens/stable/frax/mocks/MintableERC20.sol";
import {MockSaddleD4LP} from "@crane/contracts/protocols/tokens/stable/frax/mocks/MockSaddleD4LP.sol";

contract CommunalFarm_Test is Test {
    uint256 internal constant WEEK = 7 days;
    uint256 internal constant LP_STAKE = 7.5e18;

    address internal manager0;
    address internal manager1;
    address internal staker1;
    address internal staker2;

    MockSaddleD4LP internal lp;
    MintableERC20 internal reward0;
    MintableERC20 internal reward1;
    CommunalFarm internal farm;

    function setUp() public {
        manager0 = makeAddr("manager0");
        manager1 = makeAddr("manager1");
        staker1 = makeAddr("staker1");
        staker2 = makeAddr("staker2");

        lp = new MockSaddleD4LP();
        reward0 = new MintableERC20("TRIBE", "TRIBE");
        reward1 = new MintableERC20("ALCX", "ALCX");

        string[] memory symbols = new string[](2);
        symbols[0] = "TRIBE";
        symbols[1] = "ALCX";

        address[] memory tokens = new address[](2);
        tokens[0] = address(reward0);
        tokens[1] = address(reward1);

        address[] memory managers = new address[](2);
        managers[0] = manager0;
        managers[1] = manager1;

        uint256[] memory rates = new uint256[](2);
        rates[0] = 10e18 / WEEK;
        rates[1] = 5e18 / WEEK;

        farm = new CommunalFarm(address(this), address(lp), symbols, tokens, managers, rates);

        reward0.mint(address(farm), 1_000_000e18);
        reward1.mint(address(farm), 1_000_000e18);
        lp.mint(staker1, 100e18);
        lp.mint(staker2, 100e18);
    }

    function test_Deploy_initialState() public view {
        assertEq(farm.owner(), address(this));
        assertEq(farm.rewardsDuration(), WEEK);

        string[] memory symbols = farm.getRewardSymbols();
        assertEq(symbols.length, 2);
        assertEq(symbols[0], "TRIBE");

        address[] memory tokens = farm.getAllRewardTokens();
        assertEq(tokens.length, 2);
        assertEq(tokens[0], address(reward0));

        assertEq(farm.rewardManagers(address(reward0)), manager0);
        assertTrue(farm.isTokenManagerFor(manager0, address(reward0)));
        assertFalse(farm.isTokenManagerFor(staker1, address(reward0)));
    }

    function test_lockMultiplier_scalesWithDuration() public view {
        uint256 oneDay = farm.lockMultiplier(1 days);
        uint256 oneYear = farm.lockMultiplier(365 days);
        assertGt(oneYear, oneDay);
        assertLe(oneYear, farm.lock_max_multiplier());
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

    function test_getReward_accruesBothTokensOverWeek() public {
        vm.startPrank(staker1);
        lp.approve(address(farm), LP_STAKE);
        farm.stakeLocked(LP_STAKE, 7 days);
        vm.stopPrank();

        vm.warp(block.timestamp + WEEK + 1);
        farm.sync();

        uint256 bal0Before = reward0.balanceOf(staker1);
        uint256 bal1Before = reward1.balanceOf(staker1);
        vm.prank(staker1);
        uint256[] memory paid = farm.getReward();

        assertEq(paid.length, 2);
        assertGt(paid[0], 0);
        assertGt(paid[1], 0);
        assertEq(reward0.balanceOf(staker1), bal0Before + paid[0]);
        assertEq(reward1.balanceOf(staker1), bal1Before + paid[1]);
    }

    function test_greylist_blocksStake() public {
        farm.greylistAddress(staker2);

        vm.startPrank(staker2);
        lp.approve(address(farm), LP_STAKE);
        vm.expectRevert("Address has been greylisted");
        farm.stakeLocked(LP_STAKE, 7 days);
        vm.stopPrank();
    }

    function test_setRewardRate_managerOnly() public {
        uint256 newRate = 20e18 / WEEK;

        vm.prank(manager0);
        farm.setRewardRate(address(reward0), newRate, false);
        assertEq(farm.getAllRewardRates()[0], newRate);

        vm.prank(staker1);
        vm.expectRevert("Not owner or tkn mgr");
        farm.setRewardRate(address(reward0), newRate, false);
    }

    function test_recoverERC20_rewardManagerWithdrawsExcess() public {
        uint256 excess = 1000e18;
        reward0.mint(address(farm), excess);

        uint256 mgrBefore = reward0.balanceOf(manager0);
        vm.prank(manager0);
        farm.recoverERC20(address(reward0), excess);

        assertEq(reward0.balanceOf(manager0), mgrBefore + excess);
    }
}
