// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {
    HooksConfig,
    LiquidityManagement,
    PoolConfig,
    PoolRoleAccounts,
    TokenConfig
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import {CastingHelpers} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/CastingHelpers.sol";
import {ArrayHelpers} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/test/ArrayHelpers.sol";
import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";

import {BaseVaultTest} from "@crane/contracts/external/balancer/v3/vault/test/foundry/utils/BaseVaultTest.sol";
import {PoolFactoryMock} from "@crane/contracts/external/balancer/v3/vault/contracts/test/PoolFactoryMock.sol";
import {PoolMock} from "@crane/contracts/external/balancer/v3/vault/contracts/test/PoolMock.sol";

import {ExitFeeHookExample} from
    "@crane/contracts/protocols/dexes/balancer/v3/hooks/ExitFeeHookExample.sol";

/**
 * @title ExitFeeHookExampleTest
 * @notice Tests for the ExitFeeHookExample contract.
 * @dev Verifies exit fee mechanics, donation pattern, and owner controls.
 */
contract ExitFeeHookExampleTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    PoolFactoryMock poolFactoryMock;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    /// @notice 10% exit fee for testing
    uint64 internal constant EXIT_FEE_PERCENTAGE = 10e16;

    function setUp() public override {
        super.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));
        poolFactoryMock = PoolFactoryMock(address(vault.getPoolFactoryMock()));
    }

    function createHook() internal override returns (address) {
        // lp will be the owner of the hook
        vm.prank(lp);
        address exitFeeHook = address(new ExitFeeHookExample(IVault(address(vault))));
        vm.label(exitFeeHook, "Exit Fee Hook");
        return exitFeeHook;
    }

    function _createPool(
        address[] memory tokens,
        string memory label
    ) internal virtual override returns (address newPool, bytes memory poolArgs) {
        string memory name = "ERC20 Pool";
        string memory symbol = "ERC20POOL";

        newPool = address(deployPoolMock(IVault(address(vault)), name, symbol));
        vm.label(newPool, label);

        PoolRoleAccounts memory roleAccounts;
        roleAccounts.poolCreator = lp;

        LiquidityManagement memory liquidityManagement;
        liquidityManagement.disableUnbalancedLiquidity = true;
        liquidityManagement.enableDonation = true;

        vm.expectEmit();
        emit ExitFeeHookExample.ExitFeeHookExampleRegistered(poolHooksContract, newPool);

        PoolFactoryMock(poolFactory).registerPool(
            newPool,
            vault.buildTokenConfig(tokens.asIERC20()),
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );

        poolArgs = abi.encode(vault, name, symbol);
    }

    /* ========================================================================== */
    /*                             REGISTRATION TESTS                             */
    /* ========================================================================== */

    function testRegistryWithWrongDonationFlag() public {
        address exitFeePool = _createPoolToRegister();
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );
        vm.expectRevert(ExitFeeHookExample.PoolDoesNotSupportDonation.selector);
        _registerPoolWithHook(exitFeePool, tokenConfig, false);
    }

    function testSuccessfulRegistry() public {
        address exitFeePool = _createPoolToRegister();
        TokenConfig[] memory tokenConfig = vault.buildTokenConfig(
            [address(dai), address(usdc)].toMemoryArray().asIERC20()
        );

        _registerPoolWithHook(exitFeePool, tokenConfig, true);

        PoolConfig memory poolConfig = vault.getPoolConfig(exitFeePool);
        HooksConfig memory hooksConfig = vault.getHooksConfig(exitFeePool);

        assertTrue(poolConfig.liquidityManagement.enableDonation, "enableDonation is false");
        assertTrue(
            poolConfig.liquidityManagement.disableUnbalancedLiquidity,
            "disableUnbalancedLiquidity is false"
        );
        assertTrue(hooksConfig.enableHookAdjustedAmounts, "enableHookAdjustedAmounts is false");
        assertEq(hooksConfig.hooksContract, poolHooksContract, "hooksContract is wrong");
    }

    /* ========================================================================== */
    /*                               EXIT FEE TESTS                               */
    /* ========================================================================== */

    function testExitFeeReturnToLPs() public virtual {
        vm.expectEmit();
        emit ExitFeeHookExample.ExitFeePercentageChanged(poolHooksContract, EXIT_FEE_PERCENTAGE);

        vm.prank(lp);
        ExitFeeHookExample(poolHooksContract).setExitFeePercentage(EXIT_FEE_PERCENTAGE);

        uint256 amountOut = poolInitAmount / 2;
        uint256 hookFee = amountOut.mulDown(EXIT_FEE_PERCENTAGE);
        uint256[] memory minAmountsOut = [amountOut - hookFee, amountOut - hookFee].toMemoryArray();

        BaseVaultTest.Balances memory balancesBefore = getBalances(lp);

        vm.expectEmit();
        emit ExitFeeHookExample.ExitFeeCharged(pool, IERC20(dai), hookFee);

        vm.expectEmit();
        emit ExitFeeHookExample.ExitFeeCharged(pool, IERC20(usdc), hookFee);

        vm.prank(lp);
        router.removeLiquidityProportional(pool, 2 * amountOut, minAmountsOut, false, bytes(""));

        BaseVaultTest.Balances memory balancesAfter = getBalances(lp);

        // LP gets original liquidity minus hook fee
        assertEq(
            balancesAfter.lpTokens[daiIdx] - balancesBefore.lpTokens[daiIdx],
            amountOut - hookFee,
            "LP's DAI amount is wrong"
        );
        assertEq(
            balancesAfter.lpTokens[usdcIdx] - balancesBefore.lpTokens[usdcIdx],
            amountOut - hookFee,
            "LP's USDC amount is wrong"
        );
        assertEq(balancesBefore.lpBpt - balancesAfter.lpBpt, 2 * amountOut, "LP's BPT amount is wrong");

        // Pool balances decrease by amountOut, and receive hook fee back (donated)
        assertEq(
            balancesBefore.poolTokens[daiIdx] - balancesAfter.poolTokens[daiIdx],
            amountOut - hookFee,
            "Pool's DAI amount is wrong"
        );
        assertEq(
            balancesBefore.poolTokens[usdcIdx] - balancesAfter.poolTokens[usdcIdx],
            amountOut - hookFee,
            "Pool's USDC amount is wrong"
        );
    }

    function testZeroExitFee() public {
        // Default fee is 0, so no fee should be charged
        uint256 amountOut = poolInitAmount / 2;
        uint256[] memory minAmountsOut = [amountOut, amountOut].toMemoryArray();

        BaseVaultTest.Balances memory balancesBefore = getBalances(lp);

        vm.prank(lp);
        router.removeLiquidityProportional(pool, 2 * amountOut, minAmountsOut, false, bytes(""));

        BaseVaultTest.Balances memory balancesAfter = getBalances(lp);

        // LP gets full amount with zero fee
        assertEq(
            balancesAfter.lpTokens[daiIdx] - balancesBefore.lpTokens[daiIdx],
            amountOut,
            "LP's DAI amount should be full"
        );
        assertEq(
            balancesAfter.lpTokens[usdcIdx] - balancesBefore.lpTokens[usdcIdx],
            amountOut,
            "LP's USDC amount should be full"
        );
    }

    /* ========================================================================== */
    /*                              PERMISSION TESTS                              */
    /* ========================================================================== */

    function testPercentageTooHigh() public {
        uint64 highFee = uint64(FixedPoint.ONE);

        vm.expectRevert(
            abi.encodeWithSelector(
                ExitFeeHookExample.ExitFeeAboveLimit.selector,
                highFee,
                EXIT_FEE_PERCENTAGE
            )
        );
        vm.prank(lp);
        ExitFeeHookExample(poolHooksContract).setExitFeePercentage(highFee);
    }

    function testOnlyOwnerCanSetFee() public {
        vm.expectRevert();
        vm.prank(bob);
        ExitFeeHookExample(poolHooksContract).setExitFeePercentage(EXIT_FEE_PERCENTAGE);
    }

    /* ========================================================================== */
    /*                              HELPER FUNCTIONS                              */
    /* ========================================================================== */

    function _createPoolToRegister() private returns (address newPool) {
        newPool = address(deployPoolMock(IVault(address(vault)), "ERC20 Pool", "ERC20POOL"));
        vm.label(newPool, "Exit Fee Pool");
    }

    function _registerPoolWithHook(
        address exitFeePool,
        TokenConfig[] memory tokenConfig,
        bool enableDonation
    ) private {
        PoolRoleAccounts memory roleAccounts;

        LiquidityManagement memory liquidityManagement;
        liquidityManagement.disableUnbalancedLiquidity = true;
        liquidityManagement.enableDonation = enableDonation;

        poolFactoryMock.registerPool(
            exitFeePool,
            tokenConfig,
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );
    }
}
