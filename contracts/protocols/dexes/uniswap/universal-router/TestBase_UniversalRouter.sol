// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {
    UniversalRouter
} from "@crane/contracts/external/uniswap/universal-router/UniversalRouter.sol";
import {
    RouterParameters
} from "@crane/contracts/external/uniswap/universal-router/types/RouterParameters.sol";
import {
    IUniversalRouter
} from "@crane/contracts/external/uniswap/universal-router/interfaces/IUniversalRouter.sol";

/// @title TestBase_UniversalRouter
/// @notice Hermetic deploy helper for the vendored Uniswap Universal Router (pin 2.1.1).
/// @dev Use FOUNDRY_PROFILE=universal_router or another via_ir profile when compiling UR + consumers.
abstract contract TestBase_UniversalRouter is Test {
    IUniversalRouter internal universalRouter;

    /// @dev Deploy production UniversalRouter with Crane-compatible RouterParameters.
    ///      Unused venue addresses may be address(0) for V4-only hermetic smoke.
    function _deployUniversalRouter(
        address permit2,
        address weth9,
        address v4PoolManager,
        address v2Factory,
        address v3Factory,
        bytes32 pairInitCodeHash,
        bytes32 poolInitCodeHash,
        address v3NftPositionManager,
        address v4PositionManager,
        address spokePool
    ) internal returns (IUniversalRouter) {
        RouterParameters memory params = RouterParameters({
            permit2: permit2,
            weth9: weth9,
            v2Factory: v2Factory,
            v3Factory: v3Factory,
            pairInitCodeHash: pairInitCodeHash,
            poolInitCodeHash: poolInitCodeHash,
            v4PoolManager: v4PoolManager,
            v3NFTPositionManager: v3NftPositionManager,
            v4PositionManager: v4PositionManager,
            spokePool: spokePool
        });
        universalRouter = IUniversalRouter(address(new UniversalRouter(params)));
        vm.label(address(universalRouter), "UniversalRouter");
        return universalRouter;
    }

    /// @dev Minimal constructor for V4-focused tests (other venues zeroed).
    function _deployUniversalRouterV4Only(address permit2, address weth9, address v4PoolManager)
        internal
        returns (IUniversalRouter)
    {
        return _deployUniversalRouter(
            permit2,
            weth9,
            v4PoolManager,
            address(0),
            address(0),
            bytes32(0),
            bytes32(0),
            address(0),
            address(0),
            address(0)
        );
    }
}
