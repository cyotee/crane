// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

/// @notice A simple origin contract that emits events when receiving ETH.
contract SampleOrigin {
    event Received(address indexed sender, address indexed recipient, uint256 amount);

    receive() external payable {
        emit Received(msg.sender, address(this), msg.value);
    }

    function deposit() external payable {
        emit Received(msg.sender, address(this), msg.value);
    }
}
