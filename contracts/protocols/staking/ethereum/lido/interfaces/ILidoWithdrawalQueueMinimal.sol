// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ILidoWithdrawalQueueMinimal
 * @notice Integration surface for request/claim (mainnet WithdrawalQueueERC721).
 */
interface ILidoWithdrawalQueueMinimal {
    function requestWithdrawalsWstETH(uint256[] calldata amounts, address owner)
        external
        returns (uint256[] memory requestIds);

    function claimWithdrawal(uint256 requestId) external;

    function isPaused() external view returns (bool);

    function getLastRequestId() external view returns (uint256);

    function getLastFinalizedRequestId() external view returns (uint256);
}
