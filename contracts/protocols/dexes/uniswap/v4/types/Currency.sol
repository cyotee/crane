// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Currency
/// @notice A Currency is a representation of a token address (or native ETH as address(0))
/// @dev Ported from Uniswap V4 for compatibility with Solidity 0.8.30
type Currency is address;

using CurrencyLibrary for Currency global;

/// @notice Library for working with Currency types
library CurrencyLibrary {
    /// @notice Represents the native currency (ETH on mainnet)
    Currency public constant ADDRESS_ZERO = Currency.wrap(address(0));

    /// @notice Returns whether the currency is native (address(0))
    function isAddressZero(Currency currency) internal pure returns (bool) {
        return Currency.unwrap(currency) == address(0);
    }

    /// @notice Returns the address of the currency
    function toAddress(Currency currency) internal pure returns (address) {
        return Currency.unwrap(currency);
    }

    /// @notice Compares two currencies for sorting
    function lessThan(Currency currency, Currency other) internal pure returns (bool) {
        return Currency.unwrap(currency) < Currency.unwrap(other);
    }
}
