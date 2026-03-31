// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BetterAddress} from '@crane/contracts/utils/BetterAddress.sol';
import {SafeCast} from '@crane/contracts/utils/SafeCast.sol';
import {BetterSafeERC20} from '@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol';
import {TokenTransferRelayerRepo} from '@crane/contracts/protocols/l2s/superchain/relayers/token/TokenTransferRelayerRepo.sol';
import {SuperchainSenderNonceRepo} from '@crane/contracts/protocols/l2s/superchain/senders/SuperchainSenderNonceRepo.sol';
import {Permit2AwareRepo} from '@crane/contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol';
import {MultiStepOwnableModifiers} from '@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol';
import {IERC20} from '@crane/contracts/interfaces/IERC20.sol';
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {ITokenTransferRelayer} from '@crane/contracts/interfaces/ITokenTransferRelayer.sol';
import {ICrossDomainMessenger} from '@crane/contracts/interfaces/protocols/l2s/superchain/ICrossDomainMessenger.sol';
import {IApprovedMessageSenderRegistry} from '@crane/contracts/interfaces/IApprovedMessageSenderRegistry.sol';

contract TokenTransferRelayerTarget is ITokenTransferRelayer, MultiStepOwnableModifiers {

    using BetterAddress for address;
    using BetterSafeERC20 for IERC20;
    using SafeCast for uint256;
    
    function nextNonce(address sender) external view returns (uint256 nonce) {
        return SuperchainSenderNonceRepo._nextNonce(sender, block.chainid);
    }

    function _validateSender(address recipient, address sender) internal view {
        IApprovedMessageSenderRegistry approvedMessageSenderRegistry =
            IApprovedMessageSenderRegistry(TokenTransferRelayerRepo._approvedMessageSenderRegistry());
        if (!approvedMessageSenderRegistry.isApprovedSender(recipient, sender)) {
            revert InvalidSender(sender, recipient);
        }
    }

    function _useSenderNonce(address sender, uint256 nonce) internal {
        uint256 currentNonce = SuperchainSenderNonceRepo._nextNonce(sender, block.chainid);
        if (currentNonce != nonce) {
            revert InvalidSenderNonce(sender, block.chainid, currentNonce, nonce);
        }
        SuperchainSenderNonceRepo._useCheckedNonce(sender, block.chainid, nonce);
    }

    function _prepareTransfer(IERC20 token, address recipient, uint256 amount, bool pretransfer, bool usePermit2)
        internal
    {
        uint256 actualBalance = token.balanceOf(address(this));
        if (actualBalance < amount) {
            revert InsufficientBalance(actualBalance, amount);
        }
        if (pretransfer) {
            token.safeTransfer(recipient, amount);
            return;
        }
        if (!usePermit2) {
            token.forceApprove(address(recipient), amount);
            return;
        }

        IPermit2 permit2 = Permit2AwareRepo._permit2();
        token.forceApprove(address(permit2), amount);
        permit2.approve(address(token), recipient, amount.toUint160(), block.timestamp.toUint48());
    }

    function relayTokenTransfer(
        address recipient,
        IERC20 token,
        uint256 amount,
        uint256 nonce,
        bool pretransfer,
        bool usePermit2,
        bytes calldata data
    ) external returns (bool success) {
        address sender = ICrossDomainMessenger(msg.sender).xDomainMessageSender();
        _validateSender(recipient, sender);
        _useSenderNonce(sender, nonce);
        _prepareTransfer(token, recipient, amount, pretransfer, usePermit2);
        address(recipient).functionCall(data);
        emit TokenTransferRelayed(sender, recipient, token, amount, nonce, data);
        return true;
    }

    function recoverToken(IERC20 token, address recipient, uint256 amount) external onlyOwner returns (bool success) {
        token.safeTransfer(recipient, amount);
        emit TokenRecovered(token, recipient, amount);
        return true;
    }
}