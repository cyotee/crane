// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {PoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/PoolManager.sol";
import {PoolSwapTest} from "../PoolSwapTest.sol";
import {PoolModifyLiquidityTest} from "../PoolModifyLiquidityTest.sol";

abstract contract Deployers is Test {
    uint160 public constant SQRT_PRICE_1_1 = 79228162514264337593543950336;

    IPoolManager public manager;
    PoolSwapTest public swapRouter;
    PoolModifyLiquidityTest public modifyLiquidityRouter;
    address public feeController;

    uint160 public hookPermissionCount = 14;
    uint160 public clearAllHookPermissionsMask = ~uint160(0) << hookPermissionCount;

    function deployFreshManagerAndRouters() internal virtual {
        manager = IPoolManager(address(new PoolManager(address(this))));
        swapRouter = new PoolSwapTest(manager);
        modifyLiquidityRouter = new PoolModifyLiquidityTest(manager);
        feeController = makeAddr("feeController");
        manager.setProtocolFeeController(feeController);
    }
}