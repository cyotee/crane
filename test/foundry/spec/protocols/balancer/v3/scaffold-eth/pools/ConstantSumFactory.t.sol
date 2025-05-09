// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import { IVaultErrors } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultErrors.sol";
import {
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import { BalancerPoolToken } from "@balancer-labs/v3-vault/contracts/BalancerPoolToken.sol";
import { BaseVaultTest } from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";

import { ConstantSumPool } from "../../../../../../../../contracts/protocols/dexes/balancer/v3/scaffold-eth/pools/const-sum/ConstantSumPool.sol";
import { ConstantSumFactory } from "../../../../../../../../contracts/protocols/dexes/balancer/v3/scaffold-eth/pools/const-sum/ConstantSumFactory.sol";

contract ConstantSumFactoryTest is BaseVaultTest {
    using CastingHelpers for address[];
    using ArrayHelpers for *;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    uint256 public constant DEFAULT_SWAP_FEE = 1e16; // 1%
    uint64 public constant MAX_SWAP_FEE_PERCENTAGE = 10e16; // 10%

    ConstantSumFactory internal constantSumFactory;

    function setUp() public override {
        super.setUp();

        constantSumFactory = new ConstantSumFactory(IVault(address(vault)), 365 days);
        vm.label(address(constantSumFactory), "constant sum factory");
    }

    function testFactoryPausedState() public view {
        uint256 pauseWindowDuration = constantSumFactory.getPauseWindowDuration();
        assertEq(pauseWindowDuration, 365 days);
    }

    function testCreatePoolWithoutDonation() public {
        address constantSumPool = _deployAndInitializeConstantSumPool(false);

        // Try to donate but fails because pool does not support donations
        vm.prank(bob);
        vm.expectRevert(IVaultErrors.DoesNotSupportDonation.selector);
        router.donate(constantSumPool, [poolInitAmount, poolInitAmount].toMemoryArray(), false, bytes(""));
    }

    function testCreatePoolWithDonation() public {
        uint256 amountToDonate = poolInitAmount;

        address constantSumPool = _deployAndInitializeConstantSumPool(true);

        HookTestLocals memory vars = _createHookTestLocals(constantSumPool);

        // Donates to pool successfully
        vm.prank(bob);
        router.donate(constantSumPool, [amountToDonate, amountToDonate].toMemoryArray(), false, bytes(""));

        _fillAfterHookTestLocals(vars, constantSumPool);

        // Bob balances
        assertEq(vars.bob.daiBefore - vars.bob.daiAfter, amountToDonate, "Bob DAI balance is wrong");
        assertEq(vars.bob.usdcBefore - vars.bob.usdcAfter, amountToDonate, "Bob USDC balance is wrong");
        assertEq(vars.bob.bptAfter, vars.bob.bptBefore, "Bob BPT balance is wrong");

        // Pool balances
        assertEq(vars.poolAfter[daiIdx] - vars.poolBefore[daiIdx], amountToDonate, "Pool DAI balance is wrong");
        assertEq(vars.poolAfter[usdcIdx] - vars.poolBefore[usdcIdx], amountToDonate, "Pool USDC balance is wrong");
        assertEq(vars.bptSupplyAfter, vars.bptSupplyBefore, "Pool BPT supply is wrong");

        // Vault Balances
        assertEq(vars.vault.daiAfter - vars.vault.daiBefore, amountToDonate, "Vault DAI balance is wrong");
        assertEq(vars.vault.usdcAfter - vars.vault.usdcBefore, amountToDonate, "Vault USDC balance is wrong");
    }

    function _deployAndInitializeConstantSumPool(bool supportsDonation) private returns (address) {
        PoolRoleAccounts memory roleAccounts;
        LiquidityManagement memory liquidityManagement;
        IERC20[] memory tokens = [address(dai), address(usdc)].toMemoryArray().asIERC20();

        if (supportsDonation) liquidityManagement.enableDonation = true;

        address constantSumPool = constantSumFactory.create(
            supportsDonation ? "Pool With Donation" : "Pool Without Donation",
            supportsDonation ? "PwD" : "PwoD",
            bytes32(0), // salt
            vault.buildTokenConfig(tokens),
            DEFAULT_SWAP_FEE, // swapFeePercentage
            false, // protocolFeeExempt
            roleAccounts,
            address(0), // poolHooksContract
            liquidityManagement
        );

        // Initialize pool.
        vm.prank(lp);
        router.initialize(
            constantSumPool,
            tokens,
            [poolInitAmount, poolInitAmount].toMemoryArray(),
            0,
            false,
            bytes("")
        );

        return constantSumPool;
    }

    struct WalletState {
        uint256 daiBefore;
        uint256 daiAfter;
        uint256 usdcBefore;
        uint256 usdcAfter;
        uint256 bptBefore;
        uint256 bptAfter;
    }

    struct HookTestLocals {
        WalletState bob;
        WalletState hook;
        WalletState vault;
        uint256[] poolBefore;
        uint256[] poolAfter;
        uint256 bptSupplyBefore;
        uint256 bptSupplyAfter;
    }

    function _createHookTestLocals(address pool) private view returns (HookTestLocals memory vars) {
        vars.bob.daiBefore = dai.balanceOf(bob);
        vars.bob.usdcBefore = usdc.balanceOf(bob);
        vars.bob.bptBefore = IERC20(pool).balanceOf(bob);
        vars.vault.daiBefore = dai.balanceOf(address(vault));
        vars.vault.usdcBefore = usdc.balanceOf(address(vault));
        vars.poolBefore = vault.getRawBalances(pool);
        vars.bptSupplyBefore = BalancerPoolToken(pool).totalSupply();
    }

    function _fillAfterHookTestLocals(HookTestLocals memory vars, address pool) private view {
        vars.bob.daiAfter = dai.balanceOf(bob);
        vars.bob.usdcAfter = usdc.balanceOf(bob);
        vars.bob.bptAfter = IERC20(pool).balanceOf(bob);
        vars.vault.daiAfter = dai.balanceOf(address(vault));
        vars.vault.usdcAfter = usdc.balanceOf(address(vault));
        vars.poolAfter = vault.getRawBalances(pool);
        vars.bptSupplyAfter = BalancerPoolToken(pool).totalSupply();
    }
}
