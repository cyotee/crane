// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/FraxGaugeFXSRewardsDistributor-Tests.js` (mock gauge controller)

import {Test} from "forge-std/Test.sol";
import {
    FraxGaugeFXSRewardsDistributor
} from "@crane/contracts/protocols/tokens/stable/frax/Curve/FraxGaugeFXSRewardsDistributor.sol";
import {MintableERC20} from "@crane/contracts/protocols/tokens/stable/frax/mocks/MintableERC20.sol";
import {MockFraxGaugeController} from "@crane/contracts/protocols/tokens/stable/frax/mocks/MockFraxGaugeController.sol";

contract FraxGaugeFXSRewardsDistributor_Test is Test {
    uint256 internal constant ONE_WEEK = 604_800;
    uint256 internal constant EMISSION_RATE = 1e12;
    uint256 internal constant GAUGE_WEIGHT = 1e18;

    address internal timelock;
    address internal curator;
    address internal gauge;

    MintableERC20 internal rewardToken;
    MockFraxGaugeController internal gaugeController;
    FraxGaugeFXSRewardsDistributor internal distributor;

    function setUp() public {
        timelock = makeAddr("timelock");
        curator = makeAddr("curator");
        gauge = makeAddr("gauge");

        rewardToken = new MintableERC20("FXS", "FXS");
        gaugeController = new MockFraxGaugeController();
        gaugeController.setEmissionRate(EMISSION_RATE);
        gaugeController.setGaugeWeight(GAUGE_WEIGHT);

        distributor = new FraxGaugeFXSRewardsDistributor(
            address(this), timelock, curator, address(rewardToken), address(gaugeController)
        );

        distributor.setGaugeState(gauge, false, true);
        rewardToken.mint(address(distributor), 1_000_000e18);
    }

    function test_Deploy_initialState() public view {
        assertEq(distributor.owner(), address(this));
        assertTrue(distributor.distributionsOn());
        assertTrue(distributor.gauge_whitelist(gauge));
    }

    function test_currentReward_matchesFormula() public view {
        uint256 expected = (EMISSION_RATE * GAUGE_WEIGHT / 1e18) * ONE_WEEK;
        assertEq(distributor.currentReward(gauge), expected);
    }

    function test_distributeReward_transfersToGauge() public {
        uint256 gaugeBalBefore = rewardToken.balanceOf(gauge);
        (uint256 weeksElapsed, uint256 rewardTally) = distributor.distributeReward(gauge);

        assertEq(weeksElapsed, 1);
        assertEq(rewardTally, distributor.currentReward(gauge));
        assertEq(rewardToken.balanceOf(gauge), gaugeBalBefore + rewardTally);
    }

    function test_distributeReward_reverts_not_whitelisted() public {
        address other = makeAddr("otherGauge");
        vm.expectRevert("Gauge not whitelisted");
        distributor.distributeReward(other);
    }

    function test_distributeReward_returns_zero_within_same_week() public {
        distributor.distributeReward(gauge);
        (uint256 weeksElapsed, uint256 rewardTally) = distributor.distributeReward(gauge);
        assertEq(weeksElapsed, 0);
        assertEq(rewardTally, 0);
    }

    function test_toggleDistributions_blocksPayout() public {
        distributor.toggleDistributions();
        vm.expectRevert("Distributions are off");
        distributor.distributeReward(gauge);
    }
}
