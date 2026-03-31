// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Currency {
    address internal constant NATIVE = address(0);
    function isNative() external pure returns (bool);
    function equals(Currency) external pure returns (bool);
}
