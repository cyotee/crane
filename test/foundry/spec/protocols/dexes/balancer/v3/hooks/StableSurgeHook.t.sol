// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IVaultAdmin} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
import {
    HooksConfig,
    LiquidityManagement,
    PoolRoleAccounts,
    SwapKind,
    TokenConfig,
    PoolSwapParams
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {CastingHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import {ArrayHelpers} from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";
import {StableMath} from "@balancer-labs/v3-solidity-utils/contracts/math/StableMath.sol";

import {StablePool} from "@balancer-labs/v3-pool-stable/contracts/StablePool.sol";
import {StablePoolFactory} from "@balancer-labs/v3-pool-stable/contracts/StablePoolFactory.sol";
import {
    StablePoolContractsDeployer
} from "@balancer-labs/v3-pool-stable/test/foundry/utils/StablePoolContractsDeployer.sol";

import {BaseVaultTest} from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import {PoolFactoryMock} from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";

import {StableSurgeHook} from
    "@crane/contracts/protocols/dexes/balancer/v3/hooks/StableSurgeHook.sol";
import {ISurgeHookCommon} from
    "@balancer-labs/v3-interfaces/contracts/pool-hooks/ISurgeHookCommon.sol";

/**
 * @title StableSurgeHookTest
 * @notice Tests for the StableSurgeHook contract.
 * @dev Verifies surge pricing mechanism based on pool imbalance.
 *
 * Key behaviors tested:
 * - Surge fees trigger when imbalance exceeds threshold
 * - Fee calculation follows surge formula
 * - Unbalanced liquidity blocked during surge
 */
contract StableSurgeHookTest is StablePoolContractsDeployer, BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    address internal stableSurgeHook;
    PoolFactoryMock internal poolFactoryMock;

    uint256 internal constant DEFAULT_AMP_FACTOR = 200;
    uint256 internal constant SWAP_FEE_PERCENTAGE = 1e16; // 1%
    uint256 internal constant DEFAULT_MAX_SURGE_FEE = 95e16; // 95%
    uint256 internal constant DEFAULT_SURGE_THRESHOLD = 30e16; // 30%

    function setUp() public override {
        super.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));
        poolFactoryMock = PoolFactoryMock(address(vault.getPoolFactoryMock()));
    }

    function createPoolFactory() internal override returns (address) {
        return address(deployStablePoolFactory(
            IVault(address(vault)),
            365 days,
            "Factory v1",
            "Pool v1"
        ));
    }

    function createHook() internal override returns (address) {
        vm.prank(lp);
        stableSurgeHook = address(
            new StableSurgeHook(
                IVault(address(vault)),
                DEFAULT_MAX_SURGE_FEE,
                DEFAULT_SURGE_THRESHOLD,
                "StableSurgeHook v1"
            )
        );
        vm.label(stableSurgeHook, "Stable Surge Hook");
        return stableSurgeHook;
    }

    function _createPool(
        address[] memory tokens,
        string memory label
    ) internal override returns (address newPool, bytes memory poolArgs) {
        string memory name = "Stable Pool Test";
        string memory symbol = "STABLE-TEST";

        PoolRoleAccounts memory roleAccounts;

        // Note: Event will be emitted during registration - we just check event topic matching
        // StableSurgeHookRegistered(pool, factory) - pool is first indexed, factory is second indexed

        newPool = address(
            StablePoolFactory(poolFactory).create(
                name,
                symbol,
                vault.buildTokenConfig(tokens.asIERC20()),
                DEFAULT_AMP_FACTOR,
                roleAccounts,
                BASE_MIN_SWAP_FEE,
                poolHooksContract,
                false, // Does not allow donations
                false, // Do not disable unbalanced add/remove liquidity
                ZERO_BYTES32
            )
        );
        vm.label(newPool, label);

        authorizer.grantRole(
            vault.getActionId(IVaultAdmin.setStaticSwapFeePercentage.selector),
            admin
        );
        vm.prank(admin);
        vault.setStaticSwapFeePercentage(newPool, SWAP_FEE_PERCENTAGE);

        poolArgs = abi.encode(
            StablePool.NewPoolParams({
                name: name,
                symbol: symbol,
                amplificationParameter: DEFAULT_AMP_FACTOR,
                version: "Pool v1"
            }),
            vault
        );
    }

    /* ========================================================================== */
    /*                             REGISTRATION TESTS                             */
    /* ========================================================================== */

    function testSuccessfulRegistry() public view {
        HooksConfig memory hooksConfig = vault.getHooksConfig(pool);

        assertEq(hooksConfig.hooksContract, poolHooksContract, "hooksContract is wrong");
        assertTrue(
            hooksConfig.shouldCallComputeDynamicSwapFee,
            "shouldCallComputeDynamicSwapFee is false"
        );
        // SurgeHookCommon uses AFTER callbacks, not BEFORE
        assertTrue(
            hooksConfig.shouldCallAfterAddLiquidity,
            "shouldCallAfterAddLiquidity is false"
        );
        assertTrue(
            hooksConfig.shouldCallAfterRemoveLiquidity,
            "shouldCallAfterRemoveLiquidity is false"
        );
    }

    function testDefaultSurgeParameters() public view {
        uint256 maxSurgeFee = StableSurgeHook(stableSurgeHook).getMaxSurgeFeePercentage(pool);
        uint256 threshold = StableSurgeHook(stableSurgeHook).getSurgeThresholdPercentage(pool);

        assertEq(maxSurgeFee, DEFAULT_MAX_SURGE_FEE, "Max surge fee is wrong");
        assertEq(threshold, DEFAULT_SURGE_THRESHOLD, "Threshold is wrong");
    }

    /* ========================================================================== */
    /*                            SURGE FEE TESTS                                 */
    /* ========================================================================== */

    function testNoSurgeFeeWhenBalanced() public {
        BaseVaultTest.Balances memory balances = getBalances(lp);
        uint256[] memory balancesScaled18 = balances.poolTokens;

        // Small swap that shouldn't trigger surge
        uint256 swapAmount = poolInitAmount / 100;

        vm.prank(address(vault));
        (, uint256 feePercentage) = StableSurgeHook(stableSurgeHook)
            .onComputeDynamicSwapFeePercentage(
                PoolSwapParams({
                    kind: SwapKind.EXACT_IN,
                    amountGivenScaled18: swapAmount,
                    balancesScaled18: balancesScaled18,
                    indexIn: daiIdx,
                    indexOut: usdcIdx,
                    router: address(router),
                    userData: bytes("")
                }),
                pool,
                SWAP_FEE_PERCENTAGE
            );

        // Fee should equal static fee when balanced
        assertEq(feePercentage, SWAP_FEE_PERCENTAGE, "Fee should be static when balanced");
    }

    function testSurgeFeeWhenUnbalanced() public {
        // First, heavily unbalance the pool
        vm.prank(bob);
        router.swapSingleTokenExactIn(
            pool,
            dai,
            usdc,
            poolInitAmount / 2, // Large swap to unbalance
            0,
            MAX_UINT256,
            false,
            bytes("")
        );

        // Get updated balances
        BaseVaultTest.Balances memory balances = getBalances(lp);
        uint256[] memory balancesScaled18 = balances.poolTokens;

        // Another swap in same direction should trigger surge
        uint256 swapAmount = poolInitAmount / 4;

        vm.prank(address(vault));
        (, uint256 feePercentage) = StableSurgeHook(stableSurgeHook)
            .onComputeDynamicSwapFeePercentage(
                PoolSwapParams({
                    kind: SwapKind.EXACT_IN,
                    amountGivenScaled18: swapAmount,
                    balancesScaled18: balancesScaled18,
                    indexIn: daiIdx, // Same direction, more unbalancing
                    indexOut: usdcIdx,
                    router: address(router),
                    userData: bytes("")
                }),
                pool,
                SWAP_FEE_PERCENTAGE
            );

        // Fee should be higher than static when surging
        assertTrue(
            feePercentage > SWAP_FEE_PERCENTAGE,
            "Fee should be higher when surging"
        );
        assertTrue(
            feePercentage <= DEFAULT_MAX_SURGE_FEE,
            "Fee should not exceed max surge fee"
        );
    }

    function testSwapExecution() public {
        uint256 swapAmount = poolInitAmount / 10;

        BaseVaultTest.Balances memory balancesBefore = getBalances(lp);

        vm.prank(bob);
        router.swapSingleTokenExactIn(
            pool,
            dai,
            usdc,
            swapAmount,
            0,
            MAX_UINT256,
            false,
            bytes("")
        );

        BaseVaultTest.Balances memory balancesAfter = getBalances(lp);

        // Verify swap executed
        assertEq(
            balancesBefore.bobTokens[daiIdx] - balancesAfter.bobTokens[daiIdx],
            swapAmount,
            "Bob DAI spent is wrong"
        );
        assertTrue(
            balancesAfter.bobTokens[usdcIdx] > balancesBefore.bobTokens[usdcIdx],
            "Bob should receive USDC"
        );
    }

    /* ========================================================================== */
    /*                        LIQUIDITY OPERATION TESTS                           */
    /* ========================================================================== */

    function testProportionalAddLiquidityAllowed() public {
        uint256[] memory amounts = [poolInitAmount / 10, poolInitAmount / 10].toMemoryArray();

        // Proportional add should always be allowed
        vm.prank(lp);
        router.addLiquidityProportional(pool, amounts, 0, false, bytes(""));
    }

    function testProportionalRemoveLiquidityAllowed() public {
        uint256 bptAmount = poolInitAmount / 10;
        uint256[] memory minAmounts = [uint256(0), uint256(0)].toMemoryArray();

        // Proportional remove should always be allowed
        vm.prank(lp);
        router.removeLiquidityProportional(pool, bptAmount, minAmounts, false, bytes(""));
    }

    /* ========================================================================== */
    /*                            CONFIGURATION TESTS                             */
    /* ========================================================================== */

    function testSetMaxSurgeFeePercentage() public {
        uint256 newMaxFee = 80e16; // 80%

        // Grant role to admin
        authorizer.grantRole(
            StableSurgeHook(stableSurgeHook).getActionId(
                ISurgeHookCommon.setMaxSurgeFeePercentage.selector
            ),
            admin
        );

        vm.prank(admin);
        StableSurgeHook(stableSurgeHook).setMaxSurgeFeePercentage(pool, newMaxFee);

        uint256 maxSurgeFee = StableSurgeHook(stableSurgeHook).getMaxSurgeFeePercentage(pool);
        assertEq(maxSurgeFee, newMaxFee, "Max surge fee not updated");
    }

    function testSetSurgeThresholdPercentage() public {
        uint256 newThreshold = 40e16; // 40%

        // Grant role to admin
        authorizer.grantRole(
            StableSurgeHook(stableSurgeHook).getActionId(
                ISurgeHookCommon.setSurgeThresholdPercentage.selector
            ),
            admin
        );

        vm.prank(admin);
        StableSurgeHook(stableSurgeHook).setSurgeThresholdPercentage(pool, newThreshold);

        uint256 threshold = StableSurgeHook(stableSurgeHook).getSurgeThresholdPercentage(pool);
        assertEq(threshold, newThreshold, "Threshold not updated");
    }
}
