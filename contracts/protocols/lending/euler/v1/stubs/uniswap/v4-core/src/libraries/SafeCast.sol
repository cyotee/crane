// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeCast {
    function toInt256(uint256) external pure returns (int256);
    function toUint256(int256) external pure returns (uint256);
}
