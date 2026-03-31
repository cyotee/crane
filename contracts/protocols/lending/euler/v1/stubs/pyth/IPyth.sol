// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPyth {
    struct Price { int64 price; uint64 expo; }
    function getPrice(bytes32 id) external view returns (Price memory);
}
