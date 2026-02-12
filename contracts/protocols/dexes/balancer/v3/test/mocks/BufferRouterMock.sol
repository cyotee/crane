// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import { IPermit2 } from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";

import {BufferRouter} from "@crane/contracts/external/balancer/v3/vault/contracts/BufferRouter.sol";

string constant MOCK_BUFFER_ROUTER_VERSION = "Mock Router v1";

contract BufferRouterMock is BufferRouter {
    error MockErrorCode();

    constructor(IVault vault, IWETH weth, IPermit2 permit2) BufferRouter(vault, weth, permit2, MOCK_BUFFER_ROUTER_VERSION) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function manualReentrancyAddLiquidityToBufferHook() external nonReentrant {
        BufferRouter(this).addLiquidityToBufferHook(IERC4626(address(0)), 0, 0, 0, address(0));
    }

    function manualReentrancyInitializeBufferHook() external nonReentrant {
        BufferRouter(this).initializeBufferHook(IERC4626(address(0)), 0, 0, 0, address(0));
    }
}
