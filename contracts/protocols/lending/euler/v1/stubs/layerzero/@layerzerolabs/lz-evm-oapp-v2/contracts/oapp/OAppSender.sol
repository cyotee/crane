// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct MessagingFee { uint256 gasLimit; uint256 gasPrice; uint256 lzTokenFee; }

abstract contract OAppSender {
    function _send(MessagingFee memory, bytes calldata) internal virtual returns (MessagingFee memory, bytes memory);
}
