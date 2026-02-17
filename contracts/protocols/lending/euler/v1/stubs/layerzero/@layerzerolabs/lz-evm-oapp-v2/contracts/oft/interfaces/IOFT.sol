// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOFT {
    struct SendParam { address to; uint256 amount; uint256 minAmount; uint256 dstGasLimit; bytes payload; bytes extraOptions; address refundAddress; }
    struct MessagingFee { uint256 gasLimit; uint256 gasPrice; uint256 lzTokenFee; }
    function send(SendParam calldata, bytes calldata) external payable returns (MessagingFee memory, bytes memory);
}
