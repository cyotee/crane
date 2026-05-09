// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILayerZeroComposer {
    function lzCompose(address from, bytes32 guid, bytes calldata message, address executor, bytes calldata extraData)
        external
        payable;
}
