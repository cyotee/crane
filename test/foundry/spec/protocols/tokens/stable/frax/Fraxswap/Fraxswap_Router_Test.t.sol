// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Local port of encode/deadline behavior from `fraxswap-router-test.js`.

import {Test} from "forge-std/Test.sol";
import {
    FraxswapRouterMultihop
} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/periphery/FraxswapRouterMultihop.sol";
import {IWETH} from "@crane/contracts/external/uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import {DummyToken} from "@crane/contracts/protocols/tokens/stable/frax/Fraxferry/DummyToken.sol";

contract Fraxswap_Router_Test is Test {
    address internal constant WETH_MAINNET = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    FraxswapRouterMultihop internal router;
    DummyToken internal frax;
    DummyToken internal fxs;

    address internal user;

    function setUp() public {
        user = makeAddr("routerUser");
        frax = new DummyToken();
        fxs = new DummyToken();
        router = new FraxswapRouterMultihop(IWETH(WETH_MAINNET), address(frax));
    }

    function test_setupContracts() public {
        assertTrue(address(router) != address(0));
        assertTrue(address(frax) != address(0));
    }

    function test_encodeStep_roundTrip() public view {
        bytes memory step = router.encodeStep(0, 1, 0, address(fxs), address(0xBEEF), 1, 2, 10_000);
        FraxswapRouterMultihop.FraxswapStepData memory decoded =
            abi.decode(step, (FraxswapRouterMultihop.FraxswapStepData));
        assertEq(decoded.swapType, 0);
        assertEq(decoded.directFundNextPool, 1);
        assertEq(decoded.directFundThisPool, 0);
        assertEq(decoded.tokenOut, address(fxs));
        assertEq(decoded.pool, address(0xBEEF));
        assertEq(decoded.extraParam1, 1);
        assertEq(decoded.extraParam2, 2);
        assertEq(decoded.percentOfHop, 10_000);
    }

    function test_encodeRoute_roundTrip() public {
        bytes memory step = router.encodeStep(1, 0, 0, address(fxs), address(0xCAFE), 0, 0, 5000);
        bytes[] memory steps = new bytes[](1);
        steps[0] = step;

        bytes memory leaf = router.encodeRoute(address(fxs), 10_000, steps, new bytes[](0));
        bytes[] memory nextHops = new bytes[](1);
        nextHops[0] = leaf;
        bytes memory top = router.encodeRoute(address(fxs), 10_000, new bytes[](0), nextHops);

        FraxswapRouterMultihop.FraxswapRoute memory topRoute = abi.decode(top, (FraxswapRouterMultihop.FraxswapRoute));
        assertEq(topRoute.percentOfHop, 10_000);
        assertEq(topRoute.nextHops.length, 1);

        FraxswapRouterMultihop.FraxswapRoute memory leafRoute =
            abi.decode(topRoute.nextHops[0], (FraxswapRouterMultihop.FraxswapRoute));
        assertEq(leafRoute.tokenOut, address(fxs));
        assertEq(leafRoute.steps.length, 1);
    }

    function test_encodeRoute_nestedNextHops() public view {
        bytes memory stepA = router.encodeStep(0, 0, 0, address(fxs), address(0xA1), 1, 0, 5000);
        bytes memory stepB = router.encodeStep(1, 0, 0, address(frax), address(0xB1), 0, 0, 5000);
        bytes[] memory steps = new bytes[](2);
        steps[0] = stepA;
        steps[1] = stepB;

        bytes memory leaf = router.encodeRoute(address(fxs), 10_000, steps, new bytes[](0));
        bytes memory wethStep = router.encodeStep(10, 0, 0, WETH_MAINNET, address(0), 0, 0, 10_000);
        bytes[] memory wethSteps = new bytes[](1);
        wethSteps[0] = wethStep;
        bytes memory mid = router.encodeRoute(WETH_MAINNET, 10_000, wethSteps, new bytes[](0));

        bytes[] memory nextHops = new bytes[](2);
        nextHops[0] = leaf;
        nextHops[1] = mid;
        bytes memory top = router.encodeRoute(address(0), 10_000, new bytes[](0), nextHops);

        FraxswapRouterMultihop.FraxswapRoute memory topRoute = abi.decode(top, (FraxswapRouterMultihop.FraxswapRoute));
        assertEq(topRoute.nextHops.length, 2);

        FraxswapRouterMultihop.FraxswapRoute memory leafRoute =
            abi.decode(topRoute.nextHops[0], (FraxswapRouterMultihop.FraxswapRoute));
        assertEq(leafRoute.steps.length, 2);

        FraxswapRouterMultihop.FraxswapStepData memory decodedA =
            abi.decode(leafRoute.steps[0], (FraxswapRouterMultihop.FraxswapStepData));
        assertEq(decodedA.swapType, 0);
        assertEq(decodedA.extraParam1, 1);
    }

    function test_swap_revertsWhenDeadlinePassed() public {
        frax.mint(user, 100e18);

        bytes memory route = router.encodeRoute(address(fxs), 10_000, new bytes[](0), new bytes[](0));

        FraxswapRouterMultihop.FraxswapParams memory params = FraxswapRouterMultihop.FraxswapParams({
            tokenIn: address(frax),
            amountIn: 1e18,
            tokenOut: address(fxs),
            amountOutMinimum: 0,
            recipient: user,
            deadline: block.timestamp,
            approveMax: false,
            v: 0,
            r: bytes32(0),
            s: bytes32(0),
            route: route
        });

        vm.warp(block.timestamp + 1);
        vm.startPrank(user);
        frax.approve(address(router), params.amountIn);
        vm.expectRevert("Transaction too old");
        router.swap(params);
        vm.stopPrank();
    }
}
