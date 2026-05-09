// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {IV4Quoter} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IV4Quoter.sol";
import {V4Quoter} from "@crane/contracts/protocols/dexes/uniswap/v4/lens/V4Quoter.sol";

library Deploy {
    function v4Quoter(address poolManager, bytes memory) internal returns (IV4Quoter quoter) {
        quoter = new V4Quoter(IPoolManager(poolManager));
    }
}