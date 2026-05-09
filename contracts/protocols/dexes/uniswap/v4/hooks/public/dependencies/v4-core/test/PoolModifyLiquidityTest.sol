// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {CurrencyLibrary, Currency} from "@crane/contracts/protocols/dexes/uniswap/v4/types/Currency.sol";
import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {BalanceDelta} from "@crane/contracts/protocols/dexes/uniswap/v4/types/BalanceDelta.sol";
import {PoolKey} from "@crane/contracts/protocols/dexes/uniswap/v4/types/PoolKey.sol";
import {ModifyLiquidityParams} from "@crane/contracts/protocols/dexes/uniswap/v4/types/PoolOperation.sol";
import {PoolTestBase} from "./PoolTestBase.sol";
import {CurrencySettler} from "./utils/CurrencySettler.sol";
import {StateLibrary} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/StateLibrary.sol";

contract PoolModifyLiquidityTest is PoolTestBase {
    using CurrencySettler for Currency;
    using StateLibrary for IPoolManager;

    constructor(IPoolManager _manager) PoolTestBase(_manager) {}

    struct CallbackData {
        address sender;
        PoolKey key;
        ModifyLiquidityParams params;
        bytes hookData;
        bool settleUsingBurn;
        bool takeClaims;
    }

    function modifyLiquidity(PoolKey memory key, ModifyLiquidityParams memory params, bytes memory hookData)
        external
        payable
        returns (BalanceDelta delta)
    {
        delta = modifyLiquidity(key, params, hookData, false, false);
    }

    function modifyLiquidity(
        PoolKey memory key,
        ModifyLiquidityParams memory params,
        bytes memory hookData,
        bool settleUsingBurn,
        bool takeClaims
    ) public payable returns (BalanceDelta delta) {
        delta = abi.decode(
            manager.unlock(abi.encode(CallbackData(msg.sender, key, params, hookData, settleUsingBurn, takeClaims))),
            (BalanceDelta)
        );

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            CurrencyLibrary.ADDRESS_ZERO.transfer(msg.sender, ethBalance);
        }
    }

    function unlockCallback(bytes calldata rawData) external returns (bytes memory) {
        require(msg.sender == address(manager));

        CallbackData memory data = abi.decode(rawData, (CallbackData));

        (uint128 liquidityBefore,,) = manager.getPositionInfo(
            data.key.toId(), address(this), data.params.tickLower, data.params.tickUpper, data.params.salt
        );

        (BalanceDelta delta,) = manager.modifyLiquidity(data.key, data.params, data.hookData);

        (uint128 liquidityAfter,,) = manager.getPositionInfo(
            data.key.toId(), address(this), data.params.tickLower, data.params.tickUpper, data.params.salt
        );

        (,, int256 delta0) = _fetchBalances(data.key.currency0, data.sender, address(this));
        (,, int256 delta1) = _fetchBalances(data.key.currency1, data.sender, address(this));

        require(
            int128(liquidityBefore) + data.params.liquidityDelta == int128(liquidityAfter),
            "liquidity change incorrect"
        );

        if (data.params.liquidityDelta < 0) {
            assert(delta0 > 0 || delta1 > 0);
            assert(!(delta0 < 0 || delta1 < 0));
        } else if (data.params.liquidityDelta > 0) {
            assert(delta0 < 0 || delta1 < 0);
            assert(!(delta0 > 0 || delta1 > 0));
        }

        if (delta0 < 0) data.key.currency0.settle(manager, data.sender, uint256(-delta0), data.settleUsingBurn);
        if (delta1 < 0) data.key.currency1.settle(manager, data.sender, uint256(-delta1), data.settleUsingBurn);
        if (delta0 > 0) data.key.currency0.take(manager, data.sender, uint256(delta0), data.takeClaims);
        if (delta1 > 0) data.key.currency1.take(manager, data.sender, uint256(delta1), data.takeClaims);

        return abi.encode(delta);
    }
}