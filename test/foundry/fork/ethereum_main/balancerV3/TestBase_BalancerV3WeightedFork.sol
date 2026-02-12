// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IRouter.sol";
import {IBasePool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBasePool.sol";
import {PoolSwapParams, Rounding, SwapKind, TokenInfo} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";
import {WeightedMath} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/WeightedMath.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ETHEREUM_MAIN} from "@crane/contracts/constants/networks/ETHEREUM_MAIN.sol";
import {IBalancerV3WeightedPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3WeightedPool.sol";
import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";

/// @title TestBase_BalancerV3WeightedFork
/// @notice Base test contract for Balancer V3 Weighted pool fork tests against Ethereum mainnet
/// @dev Provides common setup, constants, and helper functions for fork parity testing
///      of Crane's ported Balancer V3 Weighted pool implementation against deployed pools.
abstract contract TestBase_BalancerV3WeightedFork is Test {
    using FixedPoint for uint256;

    /* -------------------------------------------------------------------------- */
    /*                              Fork Configuration                            */
    /* -------------------------------------------------------------------------- */

    /// @dev Block number for fork reproducibility (Jan 2026)
    /// Use a recent block with known pool states for deterministic testing
    uint256 internal constant FORK_BLOCK = 21_700_000;

    /* -------------------------------------------------------------------------- */
    /*                            Mainnet Contract Refs                           */
    /* -------------------------------------------------------------------------- */

    IVault internal vault;
    IRouter internal router;
    address internal weightedPoolFactory;

    /* -------------------------------------------------------------------------- */
    /*                              Well-Known Pools                              */
    /* -------------------------------------------------------------------------- */

    /// @dev The mock weighted pool from ETHEREUM_MAIN constants
    /// This is a deployed 2-token weighted pool we can test against
    address internal weightedPool;

    /* -------------------------------------------------------------------------- */
    /*                              Pool State Cache                              */
    /* -------------------------------------------------------------------------- */

    /// @dev Cached pool tokens after setUp
    IERC20[] internal poolTokens;

    /// @dev Cached normalized weights
    uint256[] internal normalizedWeights;

    /// @dev Cached live balances (scaled to 18 decimals)
    uint256[] internal balancesLiveScaled18;

    /* -------------------------------------------------------------------------- */
    /*                              Test Configuration                            */
    /* -------------------------------------------------------------------------- */

    /// @dev Standard test amounts
    uint256 internal constant SMALL_AMOUNT = 1e18;
    uint256 internal constant MEDIUM_AMOUNT = 1_000e18;
    uint256 internal constant LARGE_AMOUNT = 100_000e18;

    /// @dev Tolerance for parity comparisons (0.01% = 1 bps)
    uint256 internal constant PARITY_TOLERANCE_BPS = 1;

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
        vm.createSelectFork("ethereum_mainnet_infura", FORK_BLOCK);

        // Set up contract references from network constants
        vault = IVault(ETHEREUM_MAIN.BALANCER_V3_VAULT);
        router = IRouter(ETHEREUM_MAIN.BALANCER_V3_ROUTER);
        weightedPoolFactory = ETHEREUM_MAIN.BALANCER_V3_WEIGHTED_POOL_FACTORY;
        weightedPool = ETHEREUM_MAIN.BALANCER_V3_MOCK_WEIGHTED_POOL;

        // Label contracts for readable traces
        vm.label(address(vault), "BalancerV3Vault");
        vm.label(address(router), "BalancerV3Router");
        vm.label(weightedPoolFactory, "WeightedPoolFactory");
        vm.label(weightedPool, "MockWeightedPool");

        // Cache pool state
        _cachePoolState();

        // Skip tests if pool has no liquidity (empty or not yet initialized)
        bool hasLiquidity = false;
        for (uint256 i = 0; i < balancesLiveScaled18.length; i++) {
            if (balancesLiveScaled18[i] > 0) {
                hasLiquidity = true;
                break;
            }
        }
        if (!hasLiquidity) {
            vm.skip(true);
        }
    }

    /// @notice Cache the pool's tokens, weights, and balances for test assertions
    function _cachePoolState() internal virtual {
        // If the pool address is stale for the fork block/network, skip these tests.
        if (weightedPool.code.length == 0) {
            vm.skip(true);
            return;
        }

        // Get pool tokens from vault
        try vault.getPoolTokenInfo(weightedPool) returns (
            IERC20[] memory tokens,
            TokenInfo[] memory,
            uint256[] memory,
            uint256[] memory
        ) {
            poolTokens = tokens;

            // Label pool tokens
            for (uint256 i = 0; i < tokens.length; i++) {
                vm.label(address(tokens[i]), _tokenLabel(i));
            }
        } catch {
            vm.skip(true);
            return;
        }

        // Get normalized weights from the weighted pool
        try IBalancerV3WeightedPool(weightedPool).getNormalizedWeights() returns (uint256[] memory weights) {
            normalizedWeights = weights;
        } catch {
            vm.skip(true);
            return;
        }

        // Get live balances from vault
        try vault.getPoolTokenInfo(weightedPool) returns (
            IERC20[] memory,
            TokenInfo[] memory,
            uint256[] memory balances,
            uint256[] memory
        ) {
            balancesLiveScaled18 = balances;
        } catch {
            vm.skip(true);
            return;
        }
    }

    /// @notice Generate a label for pool token at index
    function _tokenLabel(uint256 index) internal pure returns (string memory) {
        if (index == 0) return "PoolToken0";
        if (index == 1) return "PoolToken1";
        if (index == 2) return "PoolToken2";
        return "PoolTokenN";
    }

    /* -------------------------------------------------------------------------- */
    /*                              Pool State Helpers                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Get current pool balances from the vault
    /// @return balances Array of token balances in the pool
    function getPoolBalances() internal view returns (uint256[] memory balances) {
        (,, balances,) = vault.getPoolTokenInfo(weightedPool);
    }

    /// @notice Get the number of tokens in the pool
    function getPoolTokenCount() internal view returns (uint256) {
        return poolTokens.length;
    }

    /// @notice Check if the pool is a 2-token pool
    function is2TokenPool() internal view returns (bool) {
        return poolTokens.length == 2;
    }

    /* -------------------------------------------------------------------------- */
    /*                           Invariant Computation                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Compute invariant using Crane's WeightedMath library (ported from Balancer)
    /// @param balances Token balances scaled to 18 decimals
    /// @param weights Normalized weights (sum to 1e18)
    /// @param roundDown True for round down, false for round up
    /// @return invariant The computed invariant
    function computeInvariantLocal(
        uint256[] memory balances,
        uint256[] memory weights,
        bool roundDown
    ) internal pure returns (uint256 invariant) {
        if (roundDown) {
            invariant = WeightedMath.computeInvariantDown(weights, balances);
        } else {
            invariant = WeightedMath.computeInvariantUp(weights, balances);
        }
    }

    /// @notice Compute invariant by calling the deployed pool
    /// @param balances Token balances scaled to 18 decimals
    /// @param rounding Rounding direction
    /// @return invariant The computed invariant
    function computeInvariantOnChain(
        uint256[] memory balances,
        Rounding rounding
    ) internal view returns (uint256 invariant) {
        invariant = IBasePool(weightedPool).computeInvariant(balances, rounding);
    }

    /* -------------------------------------------------------------------------- */
    /*                           Balance Computation                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Compute new balance using Crane's WeightedMath library
    /// @param balances Current balances
    /// @param weights Normalized weights
    /// @param tokenIndex Index of token to compute balance for
    /// @param invariantRatio Ratio of new invariant to old
    /// @return newBalance The computed new balance
    function computeBalanceLocal(
        uint256[] memory balances,
        uint256[] memory weights,
        uint256 tokenIndex,
        uint256 invariantRatio
    ) internal pure returns (uint256 newBalance) {
        newBalance = WeightedMath.computeBalanceOutGivenInvariant(
            balances[tokenIndex],
            weights[tokenIndex],
            invariantRatio
        );
    }

    /// @notice Compute new balance by calling the deployed pool
    /// @param balances Current balances
    /// @param tokenIndex Index of token to compute balance for
    /// @param invariantRatio Ratio of new invariant to old
    /// @return newBalance The computed new balance
    function computeBalanceOnChain(
        uint256[] memory balances,
        uint256 tokenIndex,
        uint256 invariantRatio
    ) internal view returns (uint256 newBalance) {
        newBalance = IBasePool(weightedPool).computeBalance(balances, tokenIndex, invariantRatio);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Swap Computation                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Compute swap output using Crane's WeightedMath library (exact in)
    /// @param balanceIn Balance of input token
    /// @param weightIn Weight of input token
    /// @param balanceOut Balance of output token
    /// @param weightOut Weight of output token
    /// @param amountIn Amount of input token
    /// @return amountOut Computed output amount
    function computeSwapExactInLocal(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountIn
    ) internal pure returns (uint256 amountOut) {
        amountOut = WeightedMath.computeOutGivenExactIn(
            balanceIn,
            weightIn,
            balanceOut,
            weightOut,
            amountIn
        );
    }

    /// @notice Compute swap input using Crane's WeightedMath library (exact out)
    /// @param balanceIn Balance of input token
    /// @param weightIn Weight of input token
    /// @param balanceOut Balance of output token
    /// @param weightOut Weight of output token
    /// @param amountOut Desired output amount
    /// @return amountIn Computed input amount
    function computeSwapExactOutLocal(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountOut
    ) internal pure returns (uint256 amountIn) {
        amountIn = WeightedMath.computeInGivenExactOut(
            balanceIn,
            weightIn,
            balanceOut,
            weightOut,
            amountOut
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                            Assertion Helpers                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Assert two values are equal within tolerance
    /// @param a First value
    /// @param b Second value
    /// @param toleranceBps Tolerance in basis points
    /// @param message Error message
    function assertApproxEqBps(
        uint256 a,
        uint256 b,
        uint256 toleranceBps,
        string memory message
    ) internal pure {
        uint256 maxVal = a > b ? a : b;
        uint256 tolerance = (maxVal * toleranceBps) / 10000;
        if (tolerance == 0) tolerance = 1; // Minimum 1 wei tolerance

        uint256 diff = a > b ? a - b : b - a;
        if (diff > tolerance) {
            revert(string.concat(
                message,
                " - values differ by more than ",
                vm.toString(toleranceBps),
                " bps: a=",
                vm.toString(a),
                ", b=",
                vm.toString(b),
                ", diff=",
                vm.toString(diff),
                ", tolerance=",
                vm.toString(tolerance)
            ));
        }
    }

    /// @notice Assert parity between local computation and on-chain computation
    /// @param local Value from local computation
    /// @param onChain Value from on-chain call
    /// @param label Description for error messages
    function assertParity(
        uint256 local,
        uint256 onChain,
        string memory label
    ) internal pure {
        assertApproxEqBps(
            local,
            onChain,
            PARITY_TOLERANCE_BPS,
            string.concat("Parity check failed for ", label)
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                              Token Helpers                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Deal tokens to an address and approve the vault
    /// @param token Token to deal
    /// @param to Recipient address
    /// @param amount Amount to deal
    function dealAndApprove(IERC20 token, address to, uint256 amount) internal {
        deal(address(token), to, amount);
        vm.prank(to);
        token.approve(address(vault), type(uint256).max);
    }
}
