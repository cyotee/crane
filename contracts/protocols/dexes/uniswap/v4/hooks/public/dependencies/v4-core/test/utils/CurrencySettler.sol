// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Currency} from "@crane/contracts/protocols/dexes/uniswap/v4/types/Currency.sol";
import {IERC20Minimal} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/external/IERC20Minimal.sol";
import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";

library CurrencySettler {
    function settle(Currency currency, IPoolManager manager, address payer, uint256 amount, bool burn) internal {
        if (burn) {
            manager.burn(payer, currency.toId(), amount);
        } else if (currency.isAddressZero()) {
            manager.settle{value: amount}();
        } else {
            manager.sync(currency);
            if (payer != address(this)) {
                IERC20Minimal(Currency.unwrap(currency)).transferFrom(payer, address(manager), amount);
            } else {
                IERC20Minimal(Currency.unwrap(currency)).transfer(address(manager), amount);
            }
            manager.settle();
        }
    }

    function take(Currency currency, IPoolManager manager, address recipient, uint256 amount, bool claims) internal {
        claims ? manager.mint(recipient, currency.toId(), amount) : manager.take(currency, recipient, amount);
    }
}