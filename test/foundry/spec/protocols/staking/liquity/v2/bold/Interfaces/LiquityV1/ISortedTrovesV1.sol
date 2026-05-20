// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

interface ISortedTrovesV1 {
    function getLast() external view returns (address);
    function getPrev(address _id) external view returns (address);
}
