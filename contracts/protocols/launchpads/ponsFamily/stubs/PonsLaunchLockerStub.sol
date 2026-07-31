// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {
    IERC721ReceiverLike,
    IPonsLaunchLocker
} from "@crane/contracts/protocols/launchpads/ponsFamily/pons/interfaces/ILaunchpad.sol";

/// @title PonsLaunchLockerStub
/// @notice Minimal hermetic locker for ponsFamily tests — not a factory mock.
/// @dev Matches factory order: `safeTransferFrom` of the position NFT to this contract,
///      then `lockPosition(token)`. Implements ERC-721 receiver so the transfer succeeds.
contract PonsLaunchLockerStub is IPonsLaunchLocker, IERC721ReceiverLike {
    address public immutable override protocolFeeRecipient;

    mapping(address token => bool locked) public isLocked;
    mapping(address token => address feeWallet) public feeRedirect;
    address[] public lockedTokens;

    error ZeroAddress();
    error AlreadyLocked(address token);

    constructor(address protocolFeeRecipient_) {
        if (protocolFeeRecipient_ == address(0)) revert ZeroAddress();
        protocolFeeRecipient = protocolFeeRecipient_;
    }

    /// @inheritdoc IPonsLaunchLocker
    function lockPosition(address token) external override {
        if (token == address(0)) revert ZeroAddress();
        if (isLocked[token]) revert AlreadyLocked(token);
        isLocked[token] = true;
        lockedTokens.push(token);
    }

    /// @inheritdoc IPonsLaunchLocker
    function setFeeRedirect(address token, address newFeeWallet) external override {
        if (token == address(0)) revert ZeroAddress();
        feeRedirect[token] = newFeeWallet;
    }

    /// @inheritdoc IERC721ReceiverLike
    function onERC721Received(address, address, uint256, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        return IERC721ReceiverLike.onERC721Received.selector;
    }

    function lockedTokenCount() external view returns (uint256) {
        return lockedTokens.length;
    }
}
