// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

import {Math} from "@crane/contracts/protocols/tokens/stable/frax/Math/Math.sol";

library RangeTestMath {
    function expectedOut(uint256 reserve0, uint256 reserve1, uint256 tradeAmount, uint256 feeBps)
        internal
        pure
        returns (uint256)
    {
        uint256 feeMult = 10_000 - feeBps;
        return (tradeAmount * feeMult * reserve1) / (reserve0 * 10_000 + tradeAmount * feeMult);
    }

    function sqrt(uint256 y) internal pure returns (uint256) {
        return Math.sqrt(y);
    }
}