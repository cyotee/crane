// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                            Gyro Pool Components                            */
/* -------------------------------------------------------------------------- */

import {BalancerV3GyroECLPPoolFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/eclp/BalancerV3GyroECLPPoolFacet.sol";
import {
    IBalancerV3GyroECLPPoolDFPkg,
    BalancerV3GyroECLPPoolDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/eclp/BalancerV3GyroECLPPoolDFPkg.sol";
import {BalancerV3Gyro2CLPPoolFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/2clp/BalancerV3Gyro2CLPPoolFacet.sol";
import {
    IBalancerV3Gyro2CLPPoolDFPkg,
    BalancerV3Gyro2CLPPoolDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/2clp/BalancerV3Gyro2CLPPoolDFPkg.sol";

/**
 * @title GyroPoolFactoryService
 * @notice Library for deterministic deployment of Gyro pool facets and DFPkgs.
 * @dev Provides helper functions to deploy ECLP and 2-CLP pool components
 * using CREATE3 for deterministic addresses. These are used in test setups
 * and production deployments to ensure consistent addresses.
 *
 * Usage:
 * ```solidity
 * IBalancerV3GyroECLPPoolDFPkg eclpDFPkg = GyroPoolFactoryService.initGyroECLPPoolDFPkg(
 *     create3Factory,
 *     sharedFacets,
 *     balancerV3Vault,
 *     poolFeeManager
 * );
 * ```
 */
library GyroPoolFactoryService {
    using BetterEfficientHashLib for bytes;

    /**
     * @notice Shared facet references needed by all Gyro pool DFPkgs.
     * @dev These facets are shared across all Balancer V3 pool types.
     */
    struct SharedFacets {
        IFacet balancerV3VaultAwareFacet;
        IFacet betterBalancerV3PoolTokenFacet;
        IFacet defaultPoolInfoFacet;
        IFacet balancerV3AuthenticationFacet;
    }

    /* ---------------------------------------------------------------------- */
    /*                           ECLP Pool Deployment                         */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Deploy the Gyro ECLP pool facet.
     * @param create3Factory The CREATE3 factory for deterministic deployment.
     * @return gyroECLPPoolFacet The deployed ECLP pool facet.
     */
    function deployGyroECLPPoolFacet(
        ICreate3Factory create3Factory
    ) internal returns (IFacet gyroECLPPoolFacet) {
        gyroECLPPoolFacet = create3Factory.deployFacet(
            type(BalancerV3GyroECLPPoolFacet).creationCode,
            abi.encode(type(BalancerV3GyroECLPPoolFacet).name)._hash()
        );
    }

    /**
     * @notice Deploy the complete Gyro ECLP pool DFPkg.
     * @param create3Factory The CREATE3 factory for deterministic deployment.
     * @param sharedFacets The shared facets required by all pool types.
     * @param balancerV3Vault The Balancer V3 vault address.
     * @param poolFeeManager The address that manages pool fees.
     * @return eclpDFPkg The deployed ECLP pool DFPkg.
     */
    function initGyroECLPPoolDFPkg(
        ICreate3Factory create3Factory,
        SharedFacets memory sharedFacets,
        IVault balancerV3Vault,
        address poolFeeManager
    ) internal returns (IBalancerV3GyroECLPPoolDFPkg eclpDFPkg) {
        // Deploy ECLP-specific facet
        IFacet gyroECLPPoolFacet = deployGyroECLPPoolFacet(create3Factory);

        // Deploy the DFPkg
        eclpDFPkg = IBalancerV3GyroECLPPoolDFPkg(
            address(
                create3Factory.deployPackageWithArgs(
                    type(BalancerV3GyroECLPPoolDFPkg).creationCode,
                    abi.encode(
                        IBalancerV3GyroECLPPoolDFPkg.PkgInit({
                            balancerV3VaultAwareFacet: sharedFacets.balancerV3VaultAwareFacet,
                            betterBalancerV3PoolTokenFacet: sharedFacets.betterBalancerV3PoolTokenFacet,
                            defaultPoolInfoFacet: sharedFacets.defaultPoolInfoFacet,
                            balancerV3AuthenticationFacet: sharedFacets.balancerV3AuthenticationFacet,
                            balancerV3GyroECLPPoolFacet: gyroECLPPoolFacet,
                            balancerV3Vault: balancerV3Vault,
                            diamondFactory: create3Factory.diamondPackageFactory(),
                            poolFeeManager: poolFeeManager
                        })
                    ),
                    abi.encode(type(BalancerV3GyroECLPPoolDFPkg).name)._hash()
                )
            )
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                           2-CLP Pool Deployment                        */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Deploy the Gyro 2-CLP pool facet.
     * @param create3Factory The CREATE3 factory for deterministic deployment.
     * @return gyro2CLPPoolFacet The deployed 2-CLP pool facet.
     */
    function deployGyro2CLPPoolFacet(
        ICreate3Factory create3Factory
    ) internal returns (IFacet gyro2CLPPoolFacet) {
        gyro2CLPPoolFacet = create3Factory.deployFacet(
            type(BalancerV3Gyro2CLPPoolFacet).creationCode,
            abi.encode(type(BalancerV3Gyro2CLPPoolFacet).name)._hash()
        );
    }

    /**
     * @notice Deploy the complete Gyro 2-CLP pool DFPkg.
     * @param create3Factory The CREATE3 factory for deterministic deployment.
     * @param sharedFacets The shared facets required by all pool types.
     * @param balancerV3Vault The Balancer V3 vault address.
     * @param poolFeeManager The address that manages pool fees.
     * @return twoCLPDFPkg The deployed 2-CLP pool DFPkg.
     */
    function initGyro2CLPPoolDFPkg(
        ICreate3Factory create3Factory,
        SharedFacets memory sharedFacets,
        IVault balancerV3Vault,
        address poolFeeManager
    ) internal returns (IBalancerV3Gyro2CLPPoolDFPkg twoCLPDFPkg) {
        // Deploy 2-CLP-specific facet
        IFacet gyro2CLPPoolFacet = deployGyro2CLPPoolFacet(create3Factory);

        // Deploy the DFPkg
        twoCLPDFPkg = IBalancerV3Gyro2CLPPoolDFPkg(
            address(
                create3Factory.deployPackageWithArgs(
                    type(BalancerV3Gyro2CLPPoolDFPkg).creationCode,
                    abi.encode(
                        IBalancerV3Gyro2CLPPoolDFPkg.PkgInit({
                            balancerV3VaultAwareFacet: sharedFacets.balancerV3VaultAwareFacet,
                            betterBalancerV3PoolTokenFacet: sharedFacets.betterBalancerV3PoolTokenFacet,
                            defaultPoolInfoFacet: sharedFacets.defaultPoolInfoFacet,
                            balancerV3AuthenticationFacet: sharedFacets.balancerV3AuthenticationFacet,
                            balancerV3Gyro2CLPPoolFacet: gyro2CLPPoolFacet,
                            balancerV3Vault: balancerV3Vault,
                            diamondFactory: create3Factory.diamondPackageFactory(),
                            poolFeeManager: poolFeeManager
                        })
                    ),
                    abi.encode(type(BalancerV3Gyro2CLPPoolDFPkg).name)._hash()
                )
            )
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                         Combined Deployment                            */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Deploy both Gyro pool DFPkgs at once.
     * @dev Convenience function for deploying complete Gyro pool infrastructure.
     * @param create3Factory The CREATE3 factory for deterministic deployment.
     * @param sharedFacets The shared facets required by all pool types.
     * @param balancerV3Vault The Balancer V3 vault address.
     * @param poolFeeManager The address that manages pool fees.
     * @return eclpDFPkg The deployed ECLP pool DFPkg.
     * @return twoCLPDFPkg The deployed 2-CLP pool DFPkg.
     */
    function initAllGyroPools(
        ICreate3Factory create3Factory,
        SharedFacets memory sharedFacets,
        IVault balancerV3Vault,
        address poolFeeManager
    )
        internal
        returns (
            IBalancerV3GyroECLPPoolDFPkg eclpDFPkg,
            IBalancerV3Gyro2CLPPoolDFPkg twoCLPDFPkg
        )
    {
        eclpDFPkg = initGyroECLPPoolDFPkg(
            create3Factory,
            sharedFacets,
            balancerV3Vault,
            poolFeeManager
        );
        twoCLPDFPkg = initGyro2CLPPoolDFPkg(
            create3Factory,
            sharedFacets,
            balancerV3Vault,
            poolFeeManager
        );
    }
}
