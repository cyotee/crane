// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "@crane/contracts/protocols/tokens/stable/frax/Curve/IFraxGaugeController.sol";

/// @notice Minimal gauge controller stub for FraxGaugeFXSRewardsDistributor tests
contract MockFraxGaugeController is IFraxGaugeController {
    uint256 public emissionRate = 1e12;
    uint256 public gaugeWeight = 1e18;

    function setEmissionRate(uint256 rate) external {
        emissionRate = rate;
    }

    function setGaugeWeight(uint256 weight) external {
        gaugeWeight = weight;
    }

    function global_emission_rate() external view returns (uint256) {
        return emissionRate;
    }

    function gauge_relative_weight(address, uint256) external view returns (uint256) {
        return gaugeWeight;
    }

    function gauge_relative_weight_write(address, uint256) external returns (uint256) {
        return gaugeWeight;
    }

    function gauge_relative_weight(address) external view returns (uint256) {
        return gaugeWeight;
    }

    function gauge_relative_weight_write(address) external returns (uint256) {
        return gaugeWeight;
    }

    // --- Unused IFraxGaugeController API (stubs) ---

    function admin() external pure returns (address) {
        return address(0);
    }
    function future_admin() external pure returns (address) {
        return address(0);
    }
    function token() external pure returns (address) {
        return address(0);
    }
    function voting_escrow() external pure returns (address) {
        return address(0);
    }
    function n_gauge_types() external pure returns (int128) {
        return 0;
    }
    function n_gauges() external pure returns (int128) {
        return 0;
    }
    function gauge_type_names(int128) external pure returns (string memory) {
        return "";
    }
    function gauges(uint256) external pure returns (address) {
        return address(0);
    }
    function vote_user_slopes(address, address) external pure returns (VotedSlope memory) {
        return VotedSlope(0, 0, 0);
    }
    function vote_user_power(address) external pure returns (uint256) {
        return 0;
    }
    function last_user_vote(address, address) external pure returns (uint256) {
        return 0;
    }
    function points_weight(address, uint256) external pure returns (Point memory) {
        return Point(0, 0);
    }
    function time_weight(address) external pure returns (uint256) {
        return 0;
    }
    function points_sum(int128, uint256) external pure returns (Point memory) {
        return Point(0, 0);
    }
    function time_sum(uint256) external pure returns (uint256) {
        return 0;
    }
    function points_total(uint256) external pure returns (uint256) {
        return 0;
    }
    function time_total() external pure returns (uint256) {
        return 0;
    }
    function points_type_weight(int128, uint256) external pure returns (uint256) {
        return 0;
    }
    function time_type_weight(uint256) external pure returns (uint256) {
        return 0;
    }
    function gauge_types(address) external pure returns (int128) {
        return 0;
    }
    function get_gauge_weight(address) external pure returns (uint256) {
        return 0;
    }
    function get_type_weight(int128) external pure returns (uint256) {
        return 0;
    }
    function get_total_weight() external pure returns (uint256) {
        return 0;
    }
    function get_weights_sum_per_type(int128) external pure returns (uint256) {
        return 0;
    }
    function commit_transfer_ownership(address) external {}
    function apply_transfer_ownership() external {}
    function add_gauge(address, int128, uint256) external {}
    function checkpoint() external {}
    function checkpoint_gauge(address) external {}
    function add_type(string memory, uint256) external {}
    function change_type_weight(int128, uint256) external {}
    function change_gauge_weight(address, uint256) external {}
    function change_global_emission_rate(uint256) external {}
    function vote_for_gauge_weights(address, uint256) external {}
}