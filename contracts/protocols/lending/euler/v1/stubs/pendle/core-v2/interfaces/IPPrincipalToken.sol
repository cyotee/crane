// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPPrincipalToken {
    function underlyingAsset() external view returns (address);
    function yieldToken() external view returns (address);
}
