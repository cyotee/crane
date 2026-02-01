// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IVaultMock} from "@balancer-labs/v3-interfaces/contracts/test/IVaultMock.sol";
import {IVaultAdmin} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
import {
    HooksConfig,
    HookFlags,
    LiquidityManagement,
    PoolRoleAccounts,
    TokenConfig,
    PoolSwapParams,
    SwapKind
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {CastingHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import {ArrayHelpers} from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import {FixedPoint} from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import {BaseVaultTest} from "@balancer-labs/v3-vault/test/foundry/utils/BaseVaultTest.sol";
import {PoolFactoryMock} from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import {PoolMock} from "@balancer-labs/v3-vault/contracts/test/PoolMock.sol";

/**
 * @title BaseHooksTestSetup
 * @notice Base test setup contract providing common utilities for hook testing.
 * @dev Extends BaseVaultTest from Balancer V3 to get pre-configured vault,
 * router, tokens, and test actors (lp, alice, bob, admin).
 *
 * Test files should inherit from this base and override:
 * - createHook(): Deploy and return the hook contract address
 * - _createPool(): Create pool with hook registration
 */
abstract contract BaseHooksTestSetup is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    /// @notice Token index tracking for sorted token arrays
    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    /// @notice Reference to the pool factory mock
    PoolFactoryMock internal poolFactoryMock;

    /// @notice Default swap fee for tests (1%)
    uint256 internal constant DEFAULT_SWAP_FEE = 1e16;

    /// @notice Default test amounts
    uint256 internal constant TEST_AMOUNT = 1000e18;
    uint256 internal constant SMALL_AMOUNT = 100e18;

    function setUp() public virtual override {
        super.setUp();

        // Get sorted token indices for consistent test assertions
        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));

        // Get reference to the pool factory mock
        poolFactoryMock = PoolFactoryMock(address(vault.getPoolFactoryMock()));
    }

    /**
     * @notice Helper to create a pool with hook registration.
     * @param tokens The tokens for the pool
     * @param hookContract The hook contract address
     * @param enableDonation Whether to enable donation
     * @param disableUnbalancedLiquidity Whether to disable unbalanced liquidity
     * @return newPool The deployed pool address
     */
    function _createPoolWithHook(
        address[] memory tokens,
        address hookContract,
        bool enableDonation,
        bool disableUnbalancedLiquidity
    ) internal returns (address newPool) {
        string memory name = "Test Pool";
        string memory symbol = "TEST";

        newPool = address(deployPoolMock(IVault(address(vault)), name, symbol));
        vm.label(newPool, "Test Pool");

        PoolRoleAccounts memory roleAccounts;
        roleAccounts.poolCreator = lp;

        LiquidityManagement memory liquidityManagement;
        liquidityManagement.enableDonation = enableDonation;
        liquidityManagement.disableUnbalancedLiquidity = disableUnbalancedLiquidity;

        PoolFactoryMock(poolFactory).registerPool(
            newPool,
            vault.buildTokenConfig(tokens.asIERC20()),
            roleAccounts,
            hookContract,
            liquidityManagement
        );

        return newPool;
    }

    /**
     * @notice Helper to fund an account with tokens.
     * @param account The account to fund
     * @param amount Amount of each token
     */
    function _fundAccount(address account, uint256 amount) internal {
        deal(address(dai), account, amount);
        deal(address(usdc), account, amount);
    }

    /**
     * @notice Helper to approve tokens for the router.
     * @param account The account giving approval
     */
    function _approveTokens(address account) internal {
        vm.startPrank(account);
        dai.approve(address(router), type(uint256).max);
        usdc.approve(address(router), type(uint256).max);
        dai.approve(address(permit2), type(uint256).max);
        usdc.approve(address(permit2), type(uint256).max);
        permit2.approve(address(dai), address(router), type(uint160).max, type(uint48).max);
        permit2.approve(address(usdc), address(router), type(uint160).max, type(uint48).max);
        vm.stopPrank();
    }

    /**
     * @notice Build PoolSwapParams for testing hook callbacks.
     * @param kind Swap kind (EXACT_IN or EXACT_OUT)
     * @param amountGiven The given amount
     * @param indexIn Index of token in
     * @param indexOut Index of token out
     * @param poolBalances Current pool balances
     */
    function _buildSwapParams(
        SwapKind kind,
        uint256 amountGiven,
        uint256 indexIn,
        uint256 indexOut,
        uint256[] memory poolBalances
    ) internal view returns (PoolSwapParams memory) {
        return PoolSwapParams({
            kind: kind,
            amountGivenScaled18: amountGiven,
            balancesScaled18: poolBalances,
            indexIn: indexIn,
            indexOut: indexOut,
            router: address(router),
            userData: bytes("")
        });
    }

    /**
     * @notice Get the default token array for tests.
     */
    function _getDefaultTokens() internal view returns (address[] memory) {
        return [address(dai), address(usdc)].toMemoryArray();
    }
}
