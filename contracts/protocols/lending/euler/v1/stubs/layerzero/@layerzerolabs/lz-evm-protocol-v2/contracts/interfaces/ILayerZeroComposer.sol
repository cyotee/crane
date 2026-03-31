// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILayerZeroComposer {
    function lzReceive(uint16 srcChainId, bytes calldata srcAddress, uint64 nonce, bytes calldata payload) external;
}
