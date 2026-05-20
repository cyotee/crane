// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Script.sol";
import "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol";
import "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/periphery/libraries/FraxswapRouterLibrary.sol";

contract CheckInitCodeHash is Script {
    function run() external pure {
        bytes32 computed = keccak256(type(FraxswapPair).creationCode);
        bytes32 constant_ = FraxswapRouterLibrary.INIT_CODE_PAIR_HASH;
        console.log("computed:");
        console.logBytes32(computed);
        console.log("constant:");
        console.logBytes32(constant_);
        require(computed == constant_, "Fraxswap INIT_CODE_HASH mismatch");
    }
}