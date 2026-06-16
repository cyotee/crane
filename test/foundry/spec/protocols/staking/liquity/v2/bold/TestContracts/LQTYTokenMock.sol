// SPDX-License-Identifier: MIT

pragma solidity ^0.8.35;

//import "@crane/contracts/protocols/cdps/liquity/v2/bold/Dependencies/IERC20.sol";
//import "@crane/contracts/protocols/cdps/liquity/v2/bold/Dependencies/IERC2612.sol";

contract LQTYTokenMock {
    /*is IERC20, IERC2612*/
    function sendToLQTYStaking(address _sender, uint256 _amount) external {}

    function getDeploymentStartTime() external view returns (uint256) {}

    function getLpRewardsEntitlement() external view returns (uint256) {}
}
