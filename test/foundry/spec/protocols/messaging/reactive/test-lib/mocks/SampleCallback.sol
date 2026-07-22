// SPDX-License-Identifier: MIT
pragma solidity >=0.8.20;

/// @notice Minimal callback contract for testing.
contract SampleCallback {
    address public authorizedSender;
    address public rvmId;

    uint256 public lastAmount;
    address public lastRvmId;
    uint256 public callbackCount;

    constructor(address _callbackSender) {
        authorizedSender = _callbackSender;
        rvmId = msg.sender;
    }

    function onCallback(address _rvmId, uint256 amount) external {
        lastRvmId = _rvmId;
        lastAmount = amount;
        callbackCount++;
    }

    function onCronCallback(address _rvmId, uint256 blockNumber) external {
        lastRvmId = _rvmId;
        lastAmount = blockNumber;
        callbackCount++;
    }
}
