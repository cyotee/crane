// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.35;

import "./interface/IStateRootOracle.sol";

contract DummyStateRootOracle is IStateRootOracle {
    mapping(uint256 => BlockInfo) public blocks;

    function getBlockInfo(uint256 blockNumber) external view returns (BlockInfo memory) {
        return blocks[blockNumber];
    }

    function setStateRoot(uint256 blockNumber, bytes32 stateRoot, uint32 timestamp) external {
        blocks[blockNumber] = BlockInfo(stateRoot, timestamp);
    }
}
