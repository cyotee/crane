// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {BlockNumberish} from 'contracts/protocols/launchpads/uniswap/continuous-clearing/src/libraries/BlockNumberish.sol';
import {Bid, BidStorage} from 'contracts/protocols/launchpads/uniswap/continuous-clearing/src/BidStorage.sol';

contract MockBidStorage is BidStorage, BlockNumberish {
    constructor() BlockNumberish() {}

    function createBid(uint256 amount, address owner, uint256 maxPrice, uint24 startCumulativeMps)
        external
        returns (Bid memory bid, uint256 bidId)
    {
        return super._createBid(_getBlockNumberish(), amount, owner, maxPrice, startCumulativeMps);
    }

    function getBid(uint256 bidId) external view returns (Bid memory) {
        return super._getBid(bidId);
    }
}
