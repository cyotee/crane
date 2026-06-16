// SPDX-License-Identifier: MIT

pragma solidity ^0.8.35;

interface IRETHToken {
    function getExchangeRate() external view returns (uint256);
}
