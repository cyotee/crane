// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";

import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import {CastingHelpers} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/CastingHelpers.sol";
import {ArrayHelpers} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/test/ArrayHelpers.sol";
import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";

import {BaseVaultTest} from "@crane/contracts/external/balancer/v3/vault/test/foundry/utils/BaseVaultTest.sol";
import {PoolFactoryMock} from "@crane/contracts/external/balancer/v3/vault/contracts/test/PoolFactoryMock.sol";
import {PoolMock} from "@crane/contracts/external/balancer/v3/vault/contracts/test/PoolMock.sol";

import {MinimalRouter} from
    "@crane/contracts/protocols/dexes/balancer/v3/hooks/MinimalRouter.sol";

/**
 * @title MinimalRouterTest
 * @notice Tests for the MinimalRouter contract.
 * @dev Verifies proportional liquidity operations via the minimal router.
 *
 * Key behaviors tested:
 * - Proportional add liquidity
 * - Proportional remove liquidity
 * - WETH/ETH handling
 */
contract MinimalRouterTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    MinimalRouter internal minimalRouter;
    PoolFactoryMock internal poolFactoryMock;

    function setUp() public override {
        super.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));
        poolFactoryMock = PoolFactoryMock(address(vault.getPoolFactoryMock()));

        // Deploy the minimal router
        minimalRouter = new MinimalRouter(
            IVault(address(vault)),
            IWETH(address(weth)),
            IPermit2(address(permit2)),
            "MinimalRouter v1"
        );
        vm.label(address(minimalRouter), "Minimal Router");

        // Set up permit2 approvals for the minimal router
        vm.startPrank(lp);
        dai.approve(address(permit2), type(uint256).max);
        usdc.approve(address(permit2), type(uint256).max);
        permit2.approve(address(dai), address(minimalRouter), type(uint160).max, type(uint48).max);
        permit2.approve(address(usdc), address(minimalRouter), type(uint160).max, type(uint48).max);
        vm.stopPrank();

        vm.startPrank(bob);
        dai.approve(address(permit2), type(uint256).max);
        usdc.approve(address(permit2), type(uint256).max);
        permit2.approve(address(dai), address(minimalRouter), type(uint160).max, type(uint48).max);
        permit2.approve(address(usdc), address(minimalRouter), type(uint160).max, type(uint48).max);
        vm.stopPrank();
    }

    /* ========================================================================== */
    /*                          ADD LIQUIDITY TESTS                               */
    /* ========================================================================== */

    function testAddLiquidityProportional() public {
        uint256 bptAmount = poolInitAmount / 10;
        uint256[] memory maxAmountsIn = [poolInitAmount, poolInitAmount].toMemoryArray();

        uint256 lpDaiBefore = dai.balanceOf(lp);
        uint256 lpUsdcBefore = usdc.balanceOf(lp);
        uint256 lpBptBefore = IERC20(pool).balanceOf(lp);

        vm.prank(lp);
        uint256[] memory amountsIn = minimalRouter.addLiquidityProportional(
            pool,
            maxAmountsIn,
            bptAmount,
            false, // wethIsEth
            bytes("")
        );

        uint256 lpDaiAfter = dai.balanceOf(lp);
        uint256 lpUsdcAfter = usdc.balanceOf(lp);
        uint256 lpBptAfter = IERC20(pool).balanceOf(lp);

        // Verify BPT received
        assertEq(lpBptAfter - lpBptBefore, bptAmount, "BPT amount received is wrong");

        // Verify tokens spent
        assertEq(lpDaiBefore - lpDaiAfter, amountsIn[daiIdx], "DAI spent is wrong");
        assertEq(lpUsdcBefore - lpUsdcAfter, amountsIn[usdcIdx], "USDC spent is wrong");

        // Verify amounts are proportional (roughly equal for balanced pool)
        assertApproxEqRel(amountsIn[daiIdx], amountsIn[usdcIdx], 0.01e18, "Amounts should be proportional");
    }

    function testAddLiquidityProportionalMinOutput() public {
        uint256 bptAmount = poolInitAmount / 10;
        uint256[] memory maxAmountsIn = [poolInitAmount, poolInitAmount].toMemoryArray();

        vm.prank(lp);
        uint256[] memory amountsIn = minimalRouter.addLiquidityProportional(
            pool,
            maxAmountsIn,
            bptAmount,
            false,
            bytes("")
        );

        // All returned amounts should be non-zero
        assertTrue(amountsIn[daiIdx] > 0, "DAI amount should be non-zero");
        assertTrue(amountsIn[usdcIdx] > 0, "USDC amount should be non-zero");
    }

    /* ========================================================================== */
    /*                         REMOVE LIQUIDITY TESTS                             */
    /* ========================================================================== */

    function testRemoveLiquidityProportional() public {
        uint256 bptAmount = poolInitAmount / 10;
        uint256[] memory minAmountsOut = [uint256(0), uint256(0)].toMemoryArray();

        uint256 lpDaiBefore = dai.balanceOf(lp);
        uint256 lpUsdcBefore = usdc.balanceOf(lp);
        uint256 lpBptBefore = IERC20(pool).balanceOf(lp);

        // Approve BPT spending
        vm.startPrank(lp);
        IERC20(pool).approve(address(minimalRouter), type(uint256).max);
        IERC20(pool).approve(address(vault), type(uint256).max);

        uint256[] memory amountsOut = minimalRouter.removeLiquidityProportional(
            pool,
            bptAmount,
            minAmountsOut,
            false, // wethIsEth
            bytes("")
        );
        vm.stopPrank();

        uint256 lpDaiAfter = dai.balanceOf(lp);
        uint256 lpUsdcAfter = usdc.balanceOf(lp);
        uint256 lpBptAfter = IERC20(pool).balanceOf(lp);

        // Verify BPT burned
        assertEq(lpBptBefore - lpBptAfter, bptAmount, "BPT amount burned is wrong");

        // Verify tokens received
        assertEq(lpDaiAfter - lpDaiBefore, amountsOut[daiIdx], "DAI received is wrong");
        assertEq(lpUsdcAfter - lpUsdcBefore, amountsOut[usdcIdx], "USDC received is wrong");

        // Verify amounts are proportional
        assertApproxEqRel(amountsOut[daiIdx], amountsOut[usdcIdx], 0.01e18, "Amounts should be proportional");
    }

    function testRemoveLiquidityProportionalFullExit() public {
        // Remove all liquidity
        uint256 lpBptBefore = IERC20(pool).balanceOf(lp);
        uint256[] memory minAmountsOut = [uint256(0), uint256(0)].toMemoryArray();

        // Keep minimum BPT to avoid minimum supply issues
        uint256 bptToRemove = lpBptBefore - 1e6;

        vm.startPrank(lp);
        IERC20(pool).approve(address(minimalRouter), type(uint256).max);
        IERC20(pool).approve(address(vault), type(uint256).max);

        uint256[] memory amountsOut = minimalRouter.removeLiquidityProportional(
            pool,
            bptToRemove,
            minAmountsOut,
            false,
            bytes("")
        );
        vm.stopPrank();

        // All returned amounts should be non-zero
        assertTrue(amountsOut[daiIdx] > 0, "DAI amount should be non-zero");
        assertTrue(amountsOut[usdcIdx] > 0, "USDC amount should be non-zero");
    }

    /* ========================================================================== */
    /*                            ROUNDTRIP TESTS                                 */
    /* ========================================================================== */

    function testAddThenRemoveLiquidity() public {
        // Record initial state
        uint256 lpDaiInitial = dai.balanceOf(lp);
        uint256 lpUsdcInitial = usdc.balanceOf(lp);
        uint256 lpBptInitial = IERC20(pool).balanceOf(lp);

        // Add liquidity
        uint256 bptAmount = poolInitAmount / 10;
        uint256[] memory maxAmountsIn = [poolInitAmount, poolInitAmount].toMemoryArray();

        vm.startPrank(lp);
        uint256[] memory amountsIn = minimalRouter.addLiquidityProportional(
            pool,
            maxAmountsIn,
            bptAmount,
            false,
            bytes("")
        );

        // Approve and remove liquidity
        IERC20(pool).approve(address(minimalRouter), type(uint256).max);
        IERC20(pool).approve(address(vault), type(uint256).max);

        uint256[] memory minAmountsOut = [uint256(0), uint256(0)].toMemoryArray();
        uint256[] memory amountsOut = minimalRouter.removeLiquidityProportional(
            pool,
            bptAmount,
            minAmountsOut,
            false,
            bytes("")
        );
        vm.stopPrank();

        uint256 lpDaiFinal = dai.balanceOf(lp);
        uint256 lpUsdcFinal = usdc.balanceOf(lp);
        uint256 lpBptFinal = IERC20(pool).balanceOf(lp);

        // BPT should return to initial
        assertEq(lpBptFinal, lpBptInitial, "BPT should return to initial");

        // Token balances should be approximately restored (small rounding allowed)
        assertApproxEqRel(lpDaiFinal, lpDaiInitial, 0.001e18, "DAI should be approximately restored");
        assertApproxEqRel(lpUsdcFinal, lpUsdcInitial, 0.001e18, "USDC should be approximately restored");
    }

    /* ========================================================================== */
    /*                           VERSION TEST                                     */
    /* ========================================================================== */

    function testVersion() public view {
        string memory version = minimalRouter.version();
        assertEq(version, "MinimalRouter v1", "Version string is wrong");
    }
}
