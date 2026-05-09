// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct DexKey {
    address token0;
    address token1;
    bytes32 salt;
}

struct InitializeParams {
    DexKey dexKey;
    uint256 fee;
    uint256 revenueCut;
    bool rebalancingStatus;
    uint256 centerPrice;
    uint256 centerPriceContract;
    uint256 upperPercent;
    uint256 lowerPercent;
    uint256 upperShiftThreshold;
    uint256 lowerShiftThreshold;
    uint256 shiftTime;
    uint256 minCenterPrice;
    uint256 maxCenterPrice;
    uint256 token0Amount;
    uint256 token1Amount;
}