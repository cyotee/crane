// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/// @dev Minimal RocketVault for domain deposit path (balanceOf + depositEther).
contract RocketVaultMock {
    mapping(string => uint256) public ethBalances;

    function balanceOf(string memory networkContractName) external view returns (uint256) {
        return ethBalances[networkContractName];
    }

    function depositEther() external payable {
        ethBalances["rocketDepositPool"] += msg.value;
    }

    function withdrawEther(uint256 amount) external {
        ethBalances["rocketDepositPool"] -= amount;
        payable(msg.sender).transfer(amount);
    }
}
