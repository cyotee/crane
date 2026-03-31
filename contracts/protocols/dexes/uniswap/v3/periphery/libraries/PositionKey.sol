// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

library PositionKey {
    using BetterEfficientHashLib for bytes;

    /// @dev Returns the key of the position in the core library
    function compute(address owner, int24 tickLower, int24 tickUpper) internal pure returns (bytes32) {
        // return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
        return abi.encodePacked(owner, tickLower, tickUpper)._hash();
    }
}
