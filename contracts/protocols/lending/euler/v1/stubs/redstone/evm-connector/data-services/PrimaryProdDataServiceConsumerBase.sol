// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract PrimaryProdDataServiceConsumerBase {
    function getDataFeedIds() external view virtual returns (bytes32[] memory);
    function getOracleNumericValue(bytes32 dataFeedId) external view returns (uint256);
}
