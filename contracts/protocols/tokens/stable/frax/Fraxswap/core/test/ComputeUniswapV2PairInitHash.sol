// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.35;

import {BetterEfficientHashLib} from '@crane/contracts/utils/BetterEfficientHashLib.sol';
import '@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol';

contract ComputeUniswapV2PairInitHash{
    using BetterEfficientHashLib for bytes;

    function getInitHash() public pure returns(bytes32){
        bytes memory bytecode = type(FraxswapPair).creationCode;
        // return keccak256(abi.encodePacked(bytecode));
        return abi.encodePacked(bytecode)._hash();
    }

}