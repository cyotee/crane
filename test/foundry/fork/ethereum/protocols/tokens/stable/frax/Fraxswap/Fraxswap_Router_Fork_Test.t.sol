// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Fork port of `fraxswap-router-test.js` single-hop mainnet swaps.

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IWETH} from "@crane/contracts/external/uniswap/v2-periphery/contracts/interfaces/IWETH.sol";
import {FraxswapRouterMultihop} from
    "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/periphery/FraxswapRouterMultihop.sol";
import {IFraxAMOMinter} from "@crane/contracts/protocols/tokens/stable/frax/Frax/IFraxAMOMinter.sol";
import {TestBase_FraxEthereumFork, FraxEthereumAddresses} from "../TestBase_FraxEthereumFork.sol";

contract Fraxswap_Router_Fork_Test is Test, TestBase_FraxEthereumFork {
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant FRAX_V2_FXS_FRAX = 0x03B59Bd1c8B9F6C265bA0c3421923B93f15036Fa;
    address internal constant UNIV2_FRAX_USDC = 0x97C4adc5d28A86f9470C70DD91Dc6CC2f20d2d4D;
    address internal constant FRAXSWAP_V1_FPI_FRAX = 0x5A1eA0130Dc4DC38420AA77929f992f1FBd482Bb;

    struct HopConfig {
        address tokenOut;
        uint8 swapType;
        uint256 extraParam1;
        address pool;
    }

    FraxswapRouterMultihop internal router;
    IERC20 internal frax;
    address internal user;

    function setUp() public {
        _forkEthereum();
        user = makeAddr("routerForkUser");
        router = new FraxswapRouterMultihop(IWETH(WETH), FraxEthereumAddresses.FRAX);
        frax = IERC20(FraxEthereumAddresses.FRAX);
    }

    function test_swap_fraxToFxs_fraxswapV2() public {
        _runHop(HopConfig({tokenOut: FraxEthereumAddresses.FXS, swapType: 0, extraParam1: 1, pool: FRAX_V2_FXS_FRAX}));
    }

    function test_swap_fraxToUsdc_uniswapV2() public {
        _runHop(HopConfig({tokenOut: USDC, swapType: 1, extraParam1: 0, pool: UNIV2_FRAX_USDC}));
    }

    function test_swap_fraxToFpi_fraxswapV1() public {
        _runHop(HopConfig({tokenOut: FraxEthereumAddresses.FPI, swapType: 0, extraParam1: 0, pool: FRAXSWAP_V1_FPI_FRAX}));
    }

    function _runHop(HopConfig memory cfg) internal {
        uint256 amountIn = 1000e18;
        _fundFrax(user, amountIn);

        IERC20 out = IERC20(cfg.tokenOut);
        uint256 outBefore = out.balanceOf(user);
        bytes memory route = _buildRoute(cfg);

        vm.startPrank(user);
        frax.approve(address(router), amountIn);
        uint256 amountOut = router.swap(
            FraxswapRouterMultihop.FraxswapParams({
                tokenIn: FraxEthereumAddresses.FRAX,
                amountIn: amountIn,
                tokenOut: cfg.tokenOut,
                amountOutMinimum: 0,
                recipient: user,
                deadline: block.timestamp + 3600,
                approveMax: false,
                v: 0,
                r: bytes32(0),
                s: bytes32(0),
                route: route
            })
        );
        vm.stopPrank();

        assertGt(amountOut, 0);
        assertEq(out.balanceOf(user) - outBefore, amountOut);
    }

    function _buildRoute(HopConfig memory cfg) internal view returns (bytes memory route) {
        bytes memory step = router.encodeStep(cfg.swapType, 0, 0, cfg.tokenOut, cfg.pool, cfg.extraParam1, 0, 10_000);
        bytes[] memory steps = new bytes[](1);
        steps[0] = step;
        bytes memory leaf = router.encodeRoute(cfg.tokenOut, 10_000, steps, new bytes[](0));
        bytes[] memory nextHops = new bytes[](1);
        nextHops[0] = leaf;
        route = router.encodeRoute(cfg.tokenOut, 10_000, new bytes[](0), nextHops);
    }

    function _fundFrax(address to, uint256 amount) internal {
        address[3] memory whales = [
            FraxEthereumAddresses.FRAX_WHALE,
            FraxEthereumAddresses.ADDRESS_WITH_FRAX,
            FraxEthereumAddresses.ADDRESS_WITH_ETH
        ];
        for (uint256 i = 0; i < whales.length; i++) {
            uint256 bal = frax.balanceOf(whales[i]);
            if (bal >= amount) {
                vm.prank(whales[i]);
                frax.transfer(to, amount);
                return;
            }
        }

        IFraxAMOMinter minter = IFraxAMOMinter(FraxEthereumAddresses.FRAX_AMO_MINTER);
        vm.startPrank(FraxEthereumAddresses.COMPTROLLER);
        try minter.addAMO(address(this), false) {} catch {}
        minter.mintFraxForAMO(address(this), amount);
        vm.stopPrank();
        frax.transfer(to, amount);
    }
}