// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPPYLpOracle {
    function getLPPrice() external view returns (uint256);
}
