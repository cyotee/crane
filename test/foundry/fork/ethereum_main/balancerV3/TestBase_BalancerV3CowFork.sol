// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IHooks} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IHooks.sol";
import {ICowPool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-cow/ICowPool.sol";
import {HookFlags} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import {ETHEREUM_MAIN} from "@crane/contracts/constants/networks/ETHEREUM_MAIN.sol";

/// @title TestBase_BalancerV3CowFork
/// @notice Base test contract for Balancer V3 CoW pool fork tests against Ethereum mainnet
/// @dev Provides common setup, constants, and helper functions for fork testing CoW pools.
///
/// Fork Test Strategy:
/// Since Balancer V3 CoW pools may not yet be deployed on mainnet, this test base
/// supports two approaches:
/// 1. If a deployed CoW pool exists: compare Crane's ported implementation against it
/// 2. If no deployed pool exists: deploy the original Balancer V3 CowPool from monorepo
///    and compare math/hook behavior against our CowPoolFacet implementation
///
/// The key behaviors to verify parity:
/// - getHookFlags() - hook configuration
/// - getNormalizedWeights() - weight math
/// - computeInvariant() / computeBalance() / onSwap() - pool math
/// - Trusted router gating in onBeforeSwap()
abstract contract TestBase_BalancerV3CowFork is Test {
    /* -------------------------------------------------------------------------- */
    /*                              Fork Configuration                            */
    /* -------------------------------------------------------------------------- */

    /// @dev Block number for fork reproducibility (Jan 2025)
    /// Use a recent block with known pool states for deterministic testing
    uint256 internal constant FORK_BLOCK = 21_500_000;

    /* -------------------------------------------------------------------------- */
    /*                            Mainnet Contract Refs                           */
    /* -------------------------------------------------------------------------- */

    /// @notice Balancer V3 Vault on Ethereum mainnet
    IVault internal balancerV3Vault;

    /* -------------------------------------------------------------------------- */
    /*                              Common Token Addresses                        */
    /* -------------------------------------------------------------------------- */

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant BAL = 0xba100000625a3754423978a60c9317c58a424e3D;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual {
        // Skip fork tests when no RPC credentials are configured.
        // The `ethereum_mainnet_infura` endpoint in foundry.toml depends on ${INFURA_KEY}.
        // string memory infuraKey = vm.envOr("INFURA_KEY", string(""));
        // if (bytes(infuraKey).length == 0) {
        //     vm.skip(true);
        // }

        // Create fork at specific block for reproducibility
        // Uses the rpc_endpoints defined in foundry.toml
        vm.createSelectFork("ethereum_mainnet_infura", FORK_BLOCK);

        // Set up Balancer V3 Vault reference
        balancerV3Vault = IVault(ETHEREUM_MAIN.BALANCER_V3_VAULT);
        vm.label(address(balancerV3Vault), "BalancerV3Vault");

        // Label common tokens
        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(USDT, "USDT");
        vm.label(DAI, "DAI");
        vm.label(WBTC, "WBTC");
        vm.label(BAL, "BAL");

        // Label Balancer V3 infrastructure
        vm.label(ETHEREUM_MAIN.BALANCER_V3_ROUTER, "BalancerV3Router");
        vm.label(ETHEREUM_MAIN.BALANCER_V3_BATCH_ROUTER, "BalancerV3BatchRouter");
        vm.label(ETHEREUM_MAIN.BALANCER_V3_WEIGHTED_POOL_FACTORY, "BalancerV3WeightedPoolFactory");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Vault Helpers                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Check if a pool is registered with the Balancer V3 Vault
    /// @param pool The pool address to check
    /// @return True if the pool is registered
    function isPoolRegistered(address pool) internal view returns (bool) {
        try balancerV3Vault.isPoolRegistered(pool) returns (bool registered) {
            return registered;
        } catch {
            return false;
        }
    }

    /// @notice Get pool tokens from the vault
    /// @param pool The pool address
    /// @return tokens Array of token addresses
    function getPoolTokens(address pool) internal view returns (IERC20[] memory tokens) {
        return balancerV3Vault.getPoolTokens(pool);
    }

    /* -------------------------------------------------------------------------- */
    /*                           Hook Flag Helpers                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Compare hook flags between two pools
    /// @param pool1 First pool implementing IHooks
    /// @param pool2 Second pool implementing IHooks
    /// @return True if all hook flags match
    function hookFlagsMatch(address pool1, address pool2) internal view returns (bool) {
        HookFlags memory flags1 = IHooks(pool1).getHookFlags();
        HookFlags memory flags2 = IHooks(pool2).getHookFlags();

        return flags1.enableHookAdjustedAmounts == flags2.enableHookAdjustedAmounts
            && flags1.shouldCallBeforeInitialize == flags2.shouldCallBeforeInitialize
            && flags1.shouldCallAfterInitialize == flags2.shouldCallAfterInitialize
            && flags1.shouldCallComputeDynamicSwapFee == flags2.shouldCallComputeDynamicSwapFee
            && flags1.shouldCallBeforeSwap == flags2.shouldCallBeforeSwap
            && flags1.shouldCallAfterSwap == flags2.shouldCallAfterSwap
            && flags1.shouldCallBeforeAddLiquidity == flags2.shouldCallBeforeAddLiquidity
            && flags1.shouldCallAfterAddLiquidity == flags2.shouldCallAfterAddLiquidity
            && flags1.shouldCallBeforeRemoveLiquidity == flags2.shouldCallBeforeRemoveLiquidity
            && flags1.shouldCallAfterRemoveLiquidity == flags2.shouldCallAfterRemoveLiquidity;
    }

    /// @notice Assert that two pools have matching hook flags
    /// @param pool1 First pool implementing IHooks
    /// @param pool2 Second pool implementing IHooks
    /// @param message Error message if flags don't match
    function assertHookFlagsMatch(address pool1, address pool2, string memory message) internal view {
        HookFlags memory flags1 = IHooks(pool1).getHookFlags();
        HookFlags memory flags2 = IHooks(pool2).getHookFlags();

        assertEq(
            flags1.enableHookAdjustedAmounts,
            flags2.enableHookAdjustedAmounts,
            string.concat(message, ": enableHookAdjustedAmounts mismatch")
        );
        assertEq(
            flags1.shouldCallBeforeInitialize,
            flags2.shouldCallBeforeInitialize,
            string.concat(message, ": shouldCallBeforeInitialize mismatch")
        );
        assertEq(
            flags1.shouldCallAfterInitialize,
            flags2.shouldCallAfterInitialize,
            string.concat(message, ": shouldCallAfterInitialize mismatch")
        );
        assertEq(
            flags1.shouldCallComputeDynamicSwapFee,
            flags2.shouldCallComputeDynamicSwapFee,
            string.concat(message, ": shouldCallComputeDynamicSwapFee mismatch")
        );
        assertEq(
            flags1.shouldCallBeforeSwap,
            flags2.shouldCallBeforeSwap,
            string.concat(message, ": shouldCallBeforeSwap mismatch")
        );
        assertEq(
            flags1.shouldCallAfterSwap,
            flags2.shouldCallAfterSwap,
            string.concat(message, ": shouldCallAfterSwap mismatch")
        );
        assertEq(
            flags1.shouldCallBeforeAddLiquidity,
            flags2.shouldCallBeforeAddLiquidity,
            string.concat(message, ": shouldCallBeforeAddLiquidity mismatch")
        );
        assertEq(
            flags1.shouldCallAfterAddLiquidity,
            flags2.shouldCallAfterAddLiquidity,
            string.concat(message, ": shouldCallAfterAddLiquidity mismatch")
        );
        assertEq(
            flags1.shouldCallBeforeRemoveLiquidity,
            flags2.shouldCallBeforeRemoveLiquidity,
            string.concat(message, ": shouldCallBeforeRemoveLiquidity mismatch")
        );
        assertEq(
            flags1.shouldCallAfterRemoveLiquidity,
            flags2.shouldCallAfterRemoveLiquidity,
            string.concat(message, ": shouldCallAfterRemoveLiquidity mismatch")
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                           Weight Helpers                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Assert normalized weights match between two arrays
    /// @param weights1 First weight array
    /// @param weights2 Second weight array
    /// @param message Error message prefix
    function assertWeightsMatch(
        uint256[] memory weights1,
        uint256[] memory weights2,
        string memory message
    ) internal pure {
        assertEq(weights1.length, weights2.length, string.concat(message, ": weight array length mismatch"));

        for (uint256 i = 0; i < weights1.length; i++) {
            assertEq(
                weights1[i], weights2[i], string.concat(message, ": weight mismatch at index ", vm.toString(i))
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                              Token Helpers                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Deal tokens to an address
    /// @param token Token address
    /// @param to Recipient address
    /// @param amount Amount to deal
    function dealToken(address token, address to, uint256 amount) internal {
        deal(token, to, amount);
    }

    /// @notice Approve tokens for spending by the vault
    /// @param token Token address
    /// @param amount Amount to approve
    function approveVault(address token, uint256 amount) internal {
        IERC20(token).approve(address(balancerV3Vault), amount);
    }
}
