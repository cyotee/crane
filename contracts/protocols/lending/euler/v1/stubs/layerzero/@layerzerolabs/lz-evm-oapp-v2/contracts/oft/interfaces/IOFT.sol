// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct SendParam {
    uint32 dstEid;
    bytes32 to;
    uint256 amountLD;
    uint256 minAmountLD;
    bytes extraOptions;
    bytes composeMsg;
    bytes oftCmd;
}

struct MessagingFee {
    uint256 nativeFee;
    uint256 lzTokenFee;
}

interface IOFT {
    function token() external view returns (address);
    function quoteSend(SendParam calldata sendParam, bool payInLzToken) external view returns (MessagingFee memory);
    function send(SendParam calldata sendParam, MessagingFee calldata fee, address refundAddress) external payable;
}
