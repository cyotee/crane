// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {RedstonePrimaryProdWithoutRoundsERC7412} from "../RedstoneERC7412.sol";

contract BTCFeed is RedstonePrimaryProdWithoutRoundsERC7412 {
    function getTTL() internal view virtual override returns (uint256) {
        return 3600;
    }

    function getDataFeedId() public view virtual override returns (bytes32) {
        return bytes32("BTC");
    }
}
