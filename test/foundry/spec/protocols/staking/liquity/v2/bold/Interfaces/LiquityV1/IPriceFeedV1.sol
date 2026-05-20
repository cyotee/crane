// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

interface IPriceFeedV1 {
    function fetchPrice() external returns (uint256);
}
