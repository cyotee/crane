// SPDX-License-Identifier: MIT

pragma solidity ^0.8.35;

import "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";
import "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/IERC20Permit.sol";

interface ILQTYToken is IERC20, IERC20Permit {
    function sendToLQTYStaking(address _sender, uint256 _amount) external;

    function getDeploymentStartTime() external view returns (uint256);

    function getLpRewardsEntitlement() external view returns (uint256);
}
