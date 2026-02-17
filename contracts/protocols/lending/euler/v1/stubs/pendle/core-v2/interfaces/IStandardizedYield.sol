// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStandardizedYield {
    function exchangeRate() external view returns (uint256);
    function yieldToken() external view returns (address);
}
