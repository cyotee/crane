// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IGyro2CLPPool, Gyro2CLPPoolImmutableData, Gyro2CLPPoolDynamicData} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-gyro/IGyro2CLPPool.sol";
import {IGyroECLPPool, GyroECLPPoolImmutableData, GyroECLPPoolDynamicData} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-gyro/IGyroECLPPool.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {Rounding} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import {Gyro2CLPMath} from "@crane/contracts/external/balancer/v3/pool-gyro/contracts/lib/Gyro2CLPMath.sol";
import {GyroECLPMath} from "@crane/contracts/external/balancer/v3/pool-gyro/contracts/lib/GyroECLPMath.sol";

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ETHEREUM_MAIN} from "@crane/contracts/constants/networks/ETHEREUM_MAIN.sol";

/// @title TestBase_BalancerV3GyroFork
/// @notice Base test contract for Balancer V3 Gyro pool fork tests against Ethereum mainnet
/// @dev Provides common setup, constants, and helper functions for fork testing
///      Gyro 2-CLP and ECLP pools via parity checks between deployed pools and local math.
///
/// NOTE: The "mock" Gyro pools in network constants may be deployed but NOT initialized.
/// These tests will:
/// 1. Skip if the pool doesn't exist
/// 2. Skip if the pool is not initialized (no liquidity)
/// 3. Use immutable pool parameters to test math parity with synthetic balances
abstract contract TestBase_BalancerV3GyroFork is Test {
    /* -------------------------------------------------------------------------- */
    /*                              Fork Configuration                            */
    /* -------------------------------------------------------------------------- */

    /// @dev Block number for fork reproducibility and RPC cache reliability
    uint256 internal constant FORK_BLOCK = 21_700_000;

    /* -------------------------------------------------------------------------- */
    /*                            Mainnet Contract Refs                           */
    /* -------------------------------------------------------------------------- */

    IVault internal balancerVault;

    /* -------------------------------------------------------------------------- */
    /*                              Common Token Addresses                        */
    /* -------------------------------------------------------------------------- */

    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address internal constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    /* -------------------------------------------------------------------------- */
    /*                              Well-Known Pools                              */
    /* -------------------------------------------------------------------------- */

    // Gyro 2-CLP pool from network constants
    address internal constant GYRO_2CLP_POOL = ETHEREUM_MAIN.BALANCER_V3_MOCK_GYRO_2CLP_POOL;

    // Gyro ECLP pool from network constants
    // NOTE: typo in constant name is intentional to match ETHEREUM_MAIN
    address internal constant GYRO_ECLP_POOL = ETHEREUM_MAIN.BLANACER_V3_MOCK_GYRO_ECLP_POOL;

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

        // Create fork at pinned block for RPC cache reliability
        vm.createSelectFork("ethereum_mainnet_infura", FORK_BLOCK);

        // Set up contract references
        balancerVault = IVault(ETHEREUM_MAIN.BALANCER_V3_VAULT);

        vm.label(address(balancerVault), "BalancerV3Vault");

        // Label common tokens
        vm.label(WETH, "WETH");
        vm.label(USDC, "USDC");
        vm.label(WSTETH, "wstETH");

        // Label well-known pools
        vm.label(GYRO_2CLP_POOL, "GYRO_2CLP_POOL");
        vm.label(GYRO_ECLP_POOL, "GYRO_ECLP_POOL");
    }

    /* -------------------------------------------------------------------------- */
    /*                           2-CLP Pool Helpers                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Get 2-CLP pool at mainnet address
    function get2CLPPool(address poolAddress) internal pure returns (IGyro2CLPPool) {
        return IGyro2CLPPool(poolAddress);
    }

    /// @notice Get 2-CLP pool immutable data
    function get2CLPPoolImmutableData(IGyro2CLPPool pool)
        internal
        view
        returns (Gyro2CLPPoolImmutableData memory)
    {
        return pool.getGyro2CLPPoolImmutableData();
    }

    /// @notice Get 2-CLP pool dynamic data
    function get2CLPPoolDynamicData(IGyro2CLPPool pool)
        internal
        view
        returns (Gyro2CLPPoolDynamicData memory)
    {
        return pool.getGyro2CLPPoolDynamicData();
    }

    /// @notice Compute invariant using local 2-CLP math
    function compute2CLPInvariantLocal(
        uint256[] memory balancesLiveScaled18,
        uint256 sqrtAlpha,
        uint256 sqrtBeta,
        Rounding rounding
    ) internal pure returns (uint256) {
        return Gyro2CLPMath.calculateInvariant(balancesLiveScaled18, sqrtAlpha, sqrtBeta, rounding);
    }

    /* -------------------------------------------------------------------------- */
    /*                           ECLP Pool Helpers                                */
    /* -------------------------------------------------------------------------- */

    /// @notice Get ECLP pool at mainnet address
    function getECLPPool(address poolAddress) internal pure returns (IGyroECLPPool) {
        return IGyroECLPPool(poolAddress);
    }

    /// @notice Get ECLP pool immutable data
    function getECLPPoolImmutableData(IGyroECLPPool pool)
        internal
        view
        returns (GyroECLPPoolImmutableData memory)
    {
        return pool.getGyroECLPPoolImmutableData();
    }

    /// @notice Get ECLP pool dynamic data
    function getECLPPoolDynamicData(IGyroECLPPool pool)
        internal
        view
        returns (GyroECLPPoolDynamicData memory)
    {
        return pool.getGyroECLPPoolDynamicData();
    }

    /// @notice Get ECLP pool parameters
    function getECLPParams(IGyroECLPPool pool)
        internal
        view
        returns (IGyroECLPPool.EclpParams memory params, IGyroECLPPool.DerivedEclpParams memory derived)
    {
        return pool.getECLPParams();
    }

    /// @notice Compute invariant using local ECLP math
    function computeECLPInvariantLocal(
        uint256[] memory balancesLiveScaled18,
        IGyroECLPPool.EclpParams memory eclpParams,
        IGyroECLPPool.DerivedEclpParams memory derivedParams,
        Rounding rounding
    ) internal pure returns (uint256) {
        (int256 currentInvariant, int256 invErr) =
            GyroECLPMath.calculateInvariantWithError(balancesLiveScaled18, eclpParams, derivedParams);

        if (rounding == Rounding.ROUND_DOWN) {
            return uint256(currentInvariant - invErr);
        } else {
            return uint256(currentInvariant + invErr);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                          Pool Existence Check                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Check if a pool exists and has sufficient liquidity at the fork block
    /// @param poolAddress The address of the pool to check
    /// @return exists True if the pool exists and has non-zero balances
    function poolExistsAndHasLiquidity(address poolAddress) internal view returns (bool exists) {
        // Check if address has code
        if (poolAddress.code.length == 0) return false;

        // Try to get dynamic data from the pool (works for both 2-CLP and ECLP)
        try IGyro2CLPPool(poolAddress).getGyro2CLPPoolDynamicData() returns (Gyro2CLPPoolDynamicData memory data) {
            exists = data.balancesLiveScaled18.length >= 2
                && data.balancesLiveScaled18[0] > 0
                && data.balancesLiveScaled18[1] > 0
                && data.isPoolInitialized;
        } catch {
            // Try ECLP interface
            try IGyroECLPPool(poolAddress).getGyroECLPPoolDynamicData() returns (GyroECLPPoolDynamicData memory data) {
                exists = data.balancesLiveScaled18.length >= 2
                    && data.balancesLiveScaled18[0] > 0
                    && data.balancesLiveScaled18[1] > 0
                    && data.isPoolInitialized;
            } catch {
                exists = false;
            }
        }
    }

    /// @notice Skip the current test if the pool doesn't exist or has no liquidity
    /// @param poolAddress The address of the pool to check
    /// @param poolName Human-readable name for logging
    function skipIfPoolInvalid(address poolAddress, string memory poolName) internal {
        if (!poolExistsAndHasLiquidity(poolAddress)) {
            console.log("Skipping test - pool not available at fork block:", poolName);
            vm.skip(true);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                            Assertion Helpers                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Assert invariant matches within tolerance (basis points)
    /// @param computed The computed invariant from local math
    /// @param expected The expected invariant from mainnet pool
    /// @param toleranceBps Tolerance in basis points (10 = 0.1%)
    /// @param message Error message
    function assertInvariantParity(
        uint256 computed,
        uint256 expected,
        uint256 toleranceBps,
        string memory message
    ) internal pure {
        uint256 tolerance = (expected * toleranceBps) / 10000;
        if (tolerance == 0) tolerance = 1; // Minimum 1 wei tolerance
        assertApproxEqAbs(computed, expected, tolerance, message);
    }

    /// @notice Assert invariant matches within 0.01% tolerance (default for Gyro pools)
    function assertInvariantParity(uint256 computed, uint256 expected, string memory message) internal pure {
        assertInvariantParity(computed, expected, 1, message); // 1 bps = 0.01%
    }

    /// @notice Assert exact equality for amounts
    function assertExactMatch(uint256 expected, uint256 actual, string memory message) internal pure {
        assertEq(expected, actual, message);
    }
}
