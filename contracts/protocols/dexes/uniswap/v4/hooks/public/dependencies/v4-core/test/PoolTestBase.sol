// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Currency} from "@crane/contracts/protocols/dexes/uniswap/v4/types/Currency.sol";
import {IUnlockCallback} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/callback/IUnlockCallback.sol";
import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {StateLibrary} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/StateLibrary.sol";
import {TransientStateLibrary} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/TransientStateLibrary.sol";

abstract contract PoolTestBase is IUnlockCallback {
    using StateLibrary for IPoolManager;
    using TransientStateLibrary for IPoolManager;

    IPoolManager public immutable manager;

    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    function _fetchBalances(Currency currency, address user, address deltaHolder)
        internal
        view
        returns (uint256 userBalance, uint256 poolBalance, int256 delta)
    {
        userBalance = currency.balanceOf(user);
        poolBalance = currency.balanceOf(address(manager));
        delta = manager.currencyDelta(deltaHolder, currency);
    }
}