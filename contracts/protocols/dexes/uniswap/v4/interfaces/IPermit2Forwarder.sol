// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IAllowanceTransfer } from "@crane/contracts/interfaces/protocols/utils/permit2/IAllowanceTransfer.sol";

/// @title IPermit2Forwarder
/// @notice Interface for the Permit2Forwarder contract
/// @dev Ported from Uniswap V4 for compatibility with Solidity 0.8.30
interface IPermit2Forwarder {
    /// @notice allows forwarding a single permit to permit2
    /// @dev this function is payable to allow multicall with NATIVE based actions
    /// @param owner the owner of the tokens
    /// @param permitSingle the permit data
    /// @param signature the signature of the permit; abi.encodePacked(r, s, v)
    /// @return err the error returned by a reverting permit call, empty if successful
    function permit(address owner, IAllowanceTransfer.PermitSingle calldata permitSingle, bytes calldata signature)
        external
        payable
        returns (bytes memory err);

    /// @notice allows forwarding batch permits to permit2
    /// @dev this function is payable to allow multicall with NATIVE based actions
    /// @param owner the owner of the tokens
    /// @param _permitBatch a batch of approvals
    /// @param signature the signature of the permit; abi.encodePacked(r, s, v)
    /// @return err the error returned by a reverting permit call, empty if successful
    function permitBatch(address owner, IAllowanceTransfer.PermitBatch calldata _permitBatch, bytes calldata signature)
        external
        payable
        returns (bytes memory err);
}
