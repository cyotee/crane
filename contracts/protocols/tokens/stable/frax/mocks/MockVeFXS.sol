// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "@crane/contracts/protocols/tokens/stable/frax/Curve/IveFXS.sol";

/// @notice Minimal veFXS stub for veFXSYieldDistributorV4 tests
contract MockVeFXS is IveFXS {
    mapping(address => uint256) internal _balanceOf;
    mapping(address => LockedBalance) internal _locked;
    uint256 internal _totalSupply;

    function configure(address account, uint256 balance, uint256 lockEnd) external {
        uint256 oldBal = _balanceOf[account];
        _totalSupply = _totalSupply + balance - oldBal;
        _balanceOf[account] = balance;
        _locked[account] = LockedBalance(int128(int256(balance)), lockEnd);
    }

    function balanceOf(address addr) external view returns (uint256) {
        return _balanceOf[addr];
    }

    function balanceOf(address addr, uint256) external view returns (uint256) {
        return _balanceOf[addr];
    }

    function balanceOfAt(address addr, uint256) external view returns (uint256) {
        return _balanceOf[addr];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function totalSupply(uint256) external view returns (uint256) {
        return _totalSupply;
    }

    function totalSupplyAt(uint256) external view returns (uint256) {
        return _totalSupply;
    }

    function locked(address addr) external view returns (LockedBalance memory) {
        return _locked[addr];
    }

    function locked__end(address addr) external view returns (uint256) {
        return _locked[addr].end;
    }

    // --- Unused IveFXS API (stubs) ---

    function commit_transfer_ownership(address) external {}
    function apply_transfer_ownership() external {}
    function commit_smart_wallet_checker(address) external {}
    function apply_smart_wallet_checker() external {}
    function toggleEmergencyUnlock() external {}
    function recoverERC20(address, uint256) external {}

    function get_last_user_slope(address) external pure returns (int128) {
        return 0;
    }

    function user_point_history__ts(address, uint256) external pure returns (uint256) {
        return 0;
    }
    function checkpoint() external {}
    function deposit_for(address, uint256) external {}
    function create_lock(uint256, uint256) external {}
    function increase_amount(uint256) external {}
    function increase_unlock_time(uint256) external {}
    function withdraw() external {}

    function totalFXSSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function totalFXSSupplyAt(uint256) external view returns (uint256) {
        return _totalSupply;
    }
    function changeController(address) external {}

    function token() external pure returns (address) {
        return address(0);
    }

    function supply() external view returns (uint256) {
        return _totalSupply;
    }

    function epoch() external pure returns (uint256) {
        return 0;
    }

    function point_history(uint256) external pure returns (int128, int128, uint256, uint256, uint256) {
        return (0, 0, 0, 0, 0);
    }

    function user_point_history(address, uint256) external pure returns (int128, int128, uint256, uint256, uint256) {
        return (0, 0, 0, 0, 0);
    }

    function user_point_epoch(address) external pure returns (uint256) {
        return 0;
    }

    function slope_changes(uint256) external pure returns (int128) {
        return 0;
    }

    function controller() external pure returns (address) {
        return address(0);
    }

    function transfersEnabled() external pure returns (bool) {
        return true;
    }

    function emergencyUnlockActive() external pure returns (bool) {
        return false;
    }

    function name() external pure returns (string memory) {
        return "veFXS";
    }

    function symbol() external pure returns (string memory) {
        return "veFXS";
    }

    function version() external pure returns (string memory) {
        return "mock";
    }

    function decimals() external pure returns (uint256) {
        return 18;
    }

    function future_smart_wallet_checker() external pure returns (address) {
        return address(0);
    }

    function smart_wallet_checker() external pure returns (address) {
        return address(0);
    }

    function admin() external pure returns (address) {
        return address(0);
    }

    function future_admin() external pure returns (address) {
        return address(0);
    }
}
