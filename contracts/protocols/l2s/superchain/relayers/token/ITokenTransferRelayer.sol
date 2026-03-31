// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from '@crane/contracts/interfaces/IERC20.sol';

/**
 * @title ITokenTransferRelayer
 * @notice Interface for relaying atomic token transfers and messages across chains in the SuperChain protocol.
 * @notice First, bridge the token to the Token Transfer Relayer instance.
 * @notice Then send a crosschain message to the Token Transfer Relayer to have it process the token transfer and function call.
 */
interface ITokenTransferRelayer {
    event TokenRecovered(IERC20 indexed token, address indexed recipient, uint256 amount);

    /**
     * @notice Emitted when a token transfer and function call are relayed to a recipient.
     * @param sender The address of the sender on the source chain.
     * @param recipient The address of the recipient on the destination chain.
     * @param token The token being transferred.
     * @param amount The amount of tokens being transferred.
     * @param data The calldata for the function call being executed.
     */
    event TokenTransferRelayed(
        address indexed sender,
        address indexed recipient,
        IERC20 indexed token,
        uint256 amount,
        uint256 nonce,
        bytes data
    );

    /**
     * @notice Emitted when a token transfer relay fails due to insufficient balance.
     * @param actual The actual balance of the token in the relayer.
     * @param required The required balance of the token for the transfer.
     */
    error InsufficientBalance(uint256 actual, uint256 required);

    /**
     * @notice Emitted when a token transfer relay fails due to an invalid sender.
     * @param sender The address of the invalid sender.
     * @param recipient The address of the intended recipient.
     */
    error InvalidSender(address sender, address recipient);

    error InvalidSenderNonce(address sender, uint256 targetChainId, uint256 currentNonce, uint256 providedNonce);

    function nextNonce(address sender) external view returns (uint256 nonce);

    /**
     * @notice Relays a token transfer and function call to a recipient.
     * @dev The sender must have already bridged the tokens to the Token Transfer Relayer before calling this function.
     * @dev The recipient will receive the tokens and the function call will be executed atomically.
     * @dev If `pretransfer` is true, the tokens will be transferred to the recipient before the function call.
     * @dev If `pretransfer` is false and `usePermit2` is false, the tokens will be approved to the recipient and expect the recipient will pull the tokens in the function call.
     * @param recipient The address of the recipient on the destination chain.
     * @param token The token to be transferred.
     * @param amount The amount of tokens to be transferred.
     * @param pretransfer Whether to pre-transfer the token to the recipient.
     * @param permit2 Whether to use Permit2 for the transfer.
     * @param data The calldata for the function call to be executed on the destination chain.
     * @return success True if the token transfer and function call were successfully relayed, false otherwise.
     */
    function relayTokenTransfer(
        address recipient,
        IERC20 token,
        uint256 amount,
        uint256 nonce,
        bool pretransfer,
        bool permit2,
        bytes calldata data
    ) external returns (bool success);

    function recoverToken(IERC20 token, address recipient, uint256 amount) external returns (bool success);
}