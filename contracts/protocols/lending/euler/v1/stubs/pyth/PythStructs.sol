// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library PythStructs {
    struct Price { int64 price; uint64 expo; }
    struct PriceFeed { bytes32 id; Price price; Price emaPrice; }
}
