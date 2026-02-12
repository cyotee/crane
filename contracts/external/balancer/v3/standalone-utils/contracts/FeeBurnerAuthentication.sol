// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import { IVault } from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {Ownable} from "@crane/contracts/access/Ownable.sol";
import {Ownable2Step} from "@crane/contracts/access/Ownable2Step.sol";
import { IProtocolFeeSweeper } from "@crane/contracts/external/balancer/v3/interfaces/contracts/standalone-utils/IProtocolFeeSweeper.sol";

contract FeeBurnerAuthentication is Ownable2Step {
    IProtocolFeeSweeper public immutable protocolFeeSweeper;

    /// @notice The fee protocol is invalid.
    error InvalidProtocolFeeSweeper();

    /// @notice The sender does not have permission to call a function.
    error SenderNotAllowed();

    modifier onlyProtocolFeeSweeper() {
        if (msg.sender != address(protocolFeeSweeper)) {
            revert SenderNotAllowed();
        }
        _;
    }

    modifier onlyFeeRecipientOrOwner() {
        if (msg.sender != protocolFeeSweeper.getFeeRecipient() && msg.sender != owner()) {
            revert SenderNotAllowed();
        }
        _;
    }

    constructor(IProtocolFeeSweeper _protocolFeeSweeper, address initialOwner) Ownable(initialOwner) {
        if (address(_protocolFeeSweeper) == address(0)) {
            revert InvalidProtocolFeeSweeper();
        }

        protocolFeeSweeper = _protocolFeeSweeper;
    }
}
