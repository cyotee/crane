// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.29;

import { IPayer } from "@crane/contracts/external/reactive-omni/interfaces/IPayer.sol";
import { IPayable } from "@crane/contracts/external/reactive-omni/interfaces/IPayable.sol";

/**
 * @title Abstract base contract for contracts needing to handle payments to the system contract or callback proxies.
 */
abstract contract AbstractPayer is IPayer {
    /// @notice Indicates that the caller is not authorized to perform the requested action.
    /// @param sender_ Caller's address.
    /// @param provider_ Authorized provider's address.
    error NotAuthorized(address sender_, address provider_);

    /// @notice Indicates that there aren't sufficient funds to pay the required amount.
    /// @param required_ Amount to pay.
    /// @param available_ Current balance.
    error InsufficientFunds(uint256 required_, uint256 available_);

    /// @notice Indicates that the payment to the service provider has failed.
    error TransferFailed();

    /// @notice Service provider contract allowed to request payments.
    IPayable public immutable _SERVICE_PROVIDER;

    /// @param serviceProvider_ Service provider contract allowed to request payments.
    constructor(IPayable serviceProvider_) {
        _SERVICE_PROVIDER = serviceProvider_;
    }

    /// @inheritdoc IPayer
    receive() virtual external payable {
    }

    /// @notice Modifier for guarding the methods that may only be called by the service provider contract.
    modifier onlyServiceProvider() {
        _onlyServiceProvider();
        _;
    }

    /// @notice The implementation of the `onlyServiceProvider` modifier.
    function _onlyServiceProvider() internal view {
        if (msg.sender != address(_SERVICE_PROVIDER)) {
            revert NotAuthorized(msg.sender, address(_SERVICE_PROVIDER));
        }
    }

    /// @inheritdoc IPayer
    function pay(uint256 amount_) external onlyServiceProvider {
        _pay(payable(msg.sender), amount_);
    }

    /// @notice Automatically cover the outstanding debt to the system contract or callback proxy, provided the contract has sufficient funds.
    function _coverDebt() internal {
        uint256 amount = _SERVICE_PROVIDER.debt(address(this));
        _pay(payable(_SERVICE_PROVIDER), amount);
    }

    /// @notice Attempts to safely transfer the specified sum to the given address.
    /// @param recipient_ Address of the transfer's recipient.
    /// @param amount_ Amount to be transferred.
    function _pay(address payable recipient_, uint256 amount_) internal {
        if (address(this).balance < amount_) {
            revert InsufficientFunds(amount_, address(this).balance);
        }

        if (amount_ > 0) {
            (bool success,) = payable(recipient_).call{ value: amount_ }(new bytes(0));

            if (!success) {
                revert TransferFailed();
            }
        }
    }
}
